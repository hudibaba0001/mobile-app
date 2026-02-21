import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../calendar/sweden_holidays.dart';
import '../../design/app_theme.dart';
import '../../design/components/components.dart';
import '../../models/absence.dart';
import '../../models/entry.dart';
import '../../providers/contract_provider.dart';
import '../../repositories/balance_adjustment_repository.dart';
import '../../reports/report_aggregator.dart';
import '../../reports/report_query_service.dart';
import '../../reporting/period_summary.dart';
import '../../reporting/period_summary_calculator.dart';
import '../../reporting/time_format.dart';
import '../../reporting/time_range.dart';
import '../../services/export_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/export_share_dialog.dart';
import '../../l10n/generated/app_localizations.dart';

enum ReportSegment { all, work, travel, leave }

class OverviewTab extends StatefulWidget {
  final DateTimeRange range;
  final ReportSegment segment;
  final ValueChanged<ReportSegment> onSegmentChanged;

  const OverviewTab({
    super.key,
    required this.range,
    required this.segment,
    required this.onSegmentChanged,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late Future<ReportSummary> _summaryFuture;
  final ScrollController _scrollController = ScrollController();
  final SwedenHolidayCalendar _holidays = SwedenHolidayCalendar();

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  @override
  void didUpdateWidget(covariant OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rangeChanged = oldWidget.range.start != widget.range.start ||
        oldWidget.range.end != widget.range.end;
    final segmentChanged = oldWidget.segment != widget.segment;

    if (rangeChanged || segmentChanged) {
      _summaryFuture = _loadSummary();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  EntryType? _entryTypeForSegment(ReportSegment segment) {
    switch (segment) {
      case ReportSegment.all:
      case ReportSegment.leave:
        return null;
      case ReportSegment.work:
        return EntryType.work;
      case ReportSegment.travel:
        return EntryType.travel;
    }
  }

  Future<ReportSummary> _loadSummary() async {
    final selectedRange =
        TimeRange.custom(widget.range.start, widget.range.end);
    final endInclusive =
        selectedRange.endExclusive.subtract(const Duration(days: 1));
    final queryService = ReportQueryService(
      authService: context.read<SupabaseAuthService>(),
      adjustmentRepository: BalanceAdjustmentRepository(SupabaseConfig.client),
    );

    final aggregator = ReportAggregator(queryService: queryService);

    final summary = await aggregator.buildSummary(
      start: selectedRange.startInclusive,
      end: endInclusive,
      selectedType: _entryTypeForSegment(widget.segment),
    );

    if (widget.segment != ReportSegment.leave) {
      return summary;
    }

    // Leave segment should not export/show work/travel entry totals.
    return ReportSummary(
      filteredEntries: const [],
      workMinutes: 0,
      travelMinutes: 0,
      totalTrackedMinutes: 0,
      workInsights: summary.workInsights,
      travelInsights: summary.travelInsights,
      leavesSummary: summary.leavesSummary,
      balanceOffsets: summary.balanceOffsets,
    );
  }

  PeriodSummary _buildPeriodSummary(ReportSummary summary) {
    final contractProvider = context.read<ContractProvider>();
    final travelEnabled =
        context.read<SettingsProvider>().isTravelLoggingEnabled;
    final selectedRange =
        TimeRange.custom(widget.range.start, widget.range.end);

    return PeriodSummaryCalculator.compute(
      entries: summary.filteredEntries,
      absences: summary.leavesSummary.absences,
      range: selectedRange,
      travelEnabled: travelEnabled,
      weeklyTargetMinutes: contractProvider.weeklyTargetMinutes,
      holidays: _holidays,
      trackingStartDate: contractProvider.trackingStartDate,
      startBalanceMinutes: summary.startingBalanceMinutes,
      manualAdjustmentMinutes: summary.balanceAdjustmentMinutesInRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSegmentControl(context),
        Expanded(
          child: FutureBuilder<ReportSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final summary = snapshot.data;
              if (summary == null) {
                return const SizedBox.shrink();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _summaryFuture = _loadSummary();
                  });
                  await _summaryFuture;
                },
                child: _buildSummaryContent(context, summary),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentControl(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final unselectedChipColor = colorScheme.surfaceContainerHighest
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.42 : 0.72);
    final selectedChipColor = colorScheme.primary;
    final segmentChipTextStyle = theme.textTheme.labelMedium?.copyWith(
      // Keep chip labels on the app's configured font family.
      fontFamily: theme.textTheme.titleMedium?.fontFamily,
      fontWeight: FontWeight.w600,
    );

    Widget buildChip(ReportSegment segment, String label, IconData icon) {
      final selected = widget.segment == segment;
      return ChoiceChip(
        showCheckmark: false,
        backgroundColor: unselectedChipColor,
        selectedColor: selectedChipColor,
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.35),
        ),
        labelStyle: segmentChipTextStyle?.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.xs,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => widget.onSegmentChanged(segment),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildChip(
              ReportSegment.all,
              t.reportsCustom_filterAll,
              Icons.grid_view_rounded,
            ),
            const SizedBox(width: AppSpacing.sm),
            buildChip(
              ReportSegment.work,
              t.reportsCustom_filterWork,
              Icons.work_rounded,
            ),
            const SizedBox(width: AppSpacing.sm),
            buildChip(
              ReportSegment.travel,
              t.reportsCustom_filterTravel,
              Icons.directions_car_rounded,
            ),
            const SizedBox(width: AppSpacing.sm),
            buildChip(
              ReportSegment.leave,
              t.reportsCustom_filterLeave,
              Icons.event_note_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context, ReportSummary summary) {
    final mediaQuery = MediaQuery.of(context);
    final periodSummary = _buildPeriodSummary(summary);
    final showBalanceDetails =
        context.watch<SettingsProvider>().isTimeBalanceEnabled;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                ..._buildSegmentCards(context, summary, periodSummary),
                if (showBalanceDetails) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildBalanceAdjustmentsSection(
                    context,
                    summary,
                    periodSummary,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        if (widget.segment == ReportSegment.leave)
          ..._buildLeaveSlivers(context, summary)
        else
          ..._buildEntrySlivers(context, summary),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _buildExportSection(context, summary),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: mediaQuery.padding.bottom + AppSpacing.xxxl,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSegmentCards(
    BuildContext context,
    ReportSummary summary,
    PeriodSummary periodSummary,
  ) {
    switch (widget.segment) {
      case ReportSegment.all:
        return _buildAllCards(context, periodSummary);
      case ReportSegment.work:
        return _buildWorkCards(context, summary, periodSummary);
      case ReportSegment.travel:
        return _buildTravelCards(context, summary, periodSummary);
      case ReportSegment.leave:
        return _buildLeaveCards(context, summary);
    }
  }

  List<Widget> _buildAllCards(
      BuildContext context, PeriodSummary periodSummary) {
    final t = AppLocalizations.of(context);
    final showBalanceDetails =
        context.watch<SettingsProvider>().isTimeBalanceEnabled;

    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.work_rounded,
              title: t.overview_workTime,
              value: _formatMinutes(periodSummary.workMinutes),
              subtitle: t.overview_trackedWork,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.directions_car_rounded,
              title: t.overview_travelTime,
              value: _formatMinutes(periodSummary.travelMinutes),
              subtitle: t.overview_trackedTravel,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.timer_rounded,
              title: t.overview_totalLoggedTime,
              value: _formatMinutes(periodSummary.trackedTotalMinutes),
              subtitle: t.overview_workPlusTravel,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.event_note_rounded,
              title: t.overview_creditedLeave,
              value: _formatMinutes(periodSummary.paidLeaveMinutes),
              subtitle: t.reportsCustom_paidLeaveTypes,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      if (showBalanceDetails) ...[
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.account_balance_wallet_rounded,
                title: t.overview_accountedTime,
                value: _formatMinutes(periodSummary.accountedMinutes),
                subtitle: t.overview_loggedPlusCreditedLeave,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.flag_rounded,
                title: t.overview_plannedTime,
                value: _formatMinutes(periodSummary.targetMinutes),
                subtitle: t.overview_scheduledTarget,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.show_chart_rounded,
                title: t.overview_differenceVsPlan,
                value: _formatMinutes(
                  periodSummary.differenceMinutes,
                  signed: true,
                ),
                subtitle: t.overview_accountedMinusPlanned,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.balance_rounded,
                title: t.overview_balanceAfterPeriod,
                value: _formatMinutes(
                  periodSummary.endBalanceMinutes,
                  signed: true,
                ),
                subtitle: t.overview_startPlusAdjPlusDiff,
              ),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildWorkCards(
    BuildContext context,
    ReportSummary summary,
    PeriodSummary periodSummary,
  ) {
    final t = AppLocalizations.of(context);
    final longest = summary.workInsights.longestShift;

    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.work_rounded,
              title: t.overview_workTime,
              value: _formatMinutes(periodSummary.workMinutes),
              subtitle: t.overview_totalWork,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.calendar_today_rounded,
              title: t.reportsCustom_workDays,
              value: '${summary.workInsights.activeWorkDays}',
              subtitle: t.reportsCustom_daysWithWork,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.av_timer_rounded,
              title: t.reportsCustom_averagePerDay,
              value: _formatMinutes(
                summary.workInsights.averageWorkedMinutesPerDay.round(),
              ),
              subtitle: t.reportsCustom_workedTime,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.free_breakfast_rounded,
              title: t.reportsCustom_breaks,
              value: _formatMinutes(summary.workInsights.totalBreakMinutes),
              subtitle: t.reportsCustom_breakAveragePerShift(
                '${summary.workInsights.averageBreakMinutesPerShift.toStringAsFixed(1)}m',
              ),
            ),
          ),
        ],
      ),
      if (longest != null) ...[
        const SizedBox(height: AppSpacing.md),
        _buildInfoCard(
          context,
          title: t.reportsCustom_longestShift,
          value:
              '${DateFormat('yyyy-MM-dd').format(longest.date)} - ${_formatMinutes(longest.workedMinutes)}',
          subtitle: longest.location?.isNotEmpty == true
              ? longest.location!
              : t.reportsCustom_noLocationProvided,
        ),
      ],
    ];
  }

  List<Widget> _buildTravelCards(
    BuildContext context,
    ReportSummary summary,
    PeriodSummary periodSummary,
  ) {
    final t = AppLocalizations.of(context);
    final topRoutes = summary.travelInsights.topRoutes.take(3).toList();
    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.directions_car_rounded,
              title: t.reportsCustom_travelTime,
              value: _formatMinutes(periodSummary.travelMinutes),
              subtitle: t.reportsCustom_totalTravelTime,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.route_rounded,
              title: t.reportsCustom_trips,
              value: '${summary.travelInsights.tripCount}',
              subtitle: t.reportsCustom_tripCount,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _buildInfoCard(
        context,
        title: t.reportsCustom_averagePerTrip,
        value: _formatMinutes(
            summary.travelInsights.averageMinutesPerTrip.round()),
        subtitle: t.reportsCustom_averageTravelTime,
      ),
      if (topRoutes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.reportsCustom_topRoutes,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...topRoutes.map(
                (route) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    t.reportsCustom_topRouteLine(
                      route.routeKey,
                      route.tripCount,
                      _formatMinutes(route.totalMinutes),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildLeaveCards(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    final leaves = summary.leavesSummary;
    final unpaid = leaves.unpaidMinutes;
    final paid = leaves.creditedMinutes;

    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.event_note_rounded,
              title: t.reportsCustom_leaveDays,
              value: leaves.totalDays.toStringAsFixed(1),
              subtitle: t.reportsCustom_totalInPeriod,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.assignment_rounded,
              title: t.reportsCustom_leaveEntries,
              value: '${leaves.totalEntries}',
              subtitle: t.reportsCustom_registeredEntries,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.check_circle_outline_rounded,
              title: t.reportsCustom_paidLeave,
              value: _formatMinutes(paid),
              subtitle: t.reportsCustom_paidLeaveTypes,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.remove_circle_outline_rounded,
              title: t.reportsCustom_unpaidLeave,
              value: _formatMinutes(unpaid),
              subtitle: t.reportsCustom_unpaidLeaveType,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildBalanceAdjustmentsSection(
    BuildContext context,
    ReportSummary summary,
    PeriodSummary periodSummary,
  ) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final opening = summary.balanceOffsets.openingEvent;
    final adjustments = summary.balanceOffsets.adjustmentsInRange;
    final totalAdjustments = periodSummary.manualAdjustmentMinutes;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.reportsCustom_balanceAdjustments,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (opening != null) ...[
            Text(
              t.reportsCustom_openingBalanceEffectiveFrom(
                _formatMinutes(opening.minutes, signed: true),
                dateFormat.format(opening.effectiveDate),
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            t.reportsCustom_timeAdjustmentsTotal(
              _formatMinutes(totalAdjustments, signed: true),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (adjustments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(t.reportsCustom_timeAdjustmentsInPeriod),
              children: adjustments.map((adj) {
                final note = (adj.note ?? '').trim();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    note.isEmpty ? t.reportsCustom_noNote : note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(dateFormat.format(adj.effectiveDate)),
                  trailing: Text(
                    _formatMinutes(adj.minutes, signed: true),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.reportsCustom_balanceAtPeriodStart(
              _formatMinutes(
                periodSummary.startBalanceMinutes,
                signed: true,
              ),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.reportsCustom_periodStartIncludesStartDateAdjustmentsHint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.reportsCustom_balanceAtPeriodEnd(
              _formatMinutes(
                periodSummary.endBalanceMinutes,
                signed: true,
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEntrySlivers(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    final includeLeaves = widget.segment == ReportSegment.all;
    final items = _buildCombinedPeriodItems(
      entries: summary.filteredEntries,
      absences: includeLeaves ? summary.leavesSummary.absences : const [],
    );

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: _buildListSectionHeader(
            context,
            '${t.reportsCustom_entriesInPeriod} (${items.length})',
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
      if (items.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _buildEmptySectionCard(context),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildListRowCard(
                    context,
                    child: item.when(
                      entry: (entry) => _buildEntryRow(context, entry),
                      absence: (absence) => _buildAbsenceRow(context, absence),
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildLeaveSlivers(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    final leaves = summary.leavesSummary.absences;
    final leavesCount = leaves.length;

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: _buildListSectionHeader(
            context,
            '${t.reportsCustom_entriesInPeriod} ($leavesCount)',
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
      if (leavesCount == 0)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _buildEmptySectionCard(context),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final absence = leaves[leavesCount - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildListRowCard(
                    context,
                    child: _buildAbsenceRow(context, absence),
                  ),
                );
              },
              childCount: leavesCount,
            ),
          ),
        ),
    ];
  }

  Widget _buildListSectionHeader(BuildContext context, String title) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildListRowCard(
    BuildContext context, {
    required Widget child,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: child,
    );
  }

  Widget _buildEmptySectionCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: _buildEmptyState(context),
    );
  }

  Widget _buildExportSection(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () =>
                _exportSummary(context, summary, _ExportFormat.csv),
            icon: const Icon(Icons.table_view_rounded),
            label: Text(t.reportsCustom_exportCsv),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () =>
                _exportSummary(context, summary, _ExportFormat.excel),
            icon: const Icon(Icons.grid_on_rounded),
            label: Text(t.reportsCustom_exportExcel),
          ),
        ],
      ),
    );
  }

  ReportExportLabels _reportExportLabels(AppLocalizations t) {
    final isSwedish = Localizations.localeOf(context).languageCode == 'sv';
    final summarySheetName =
        isSwedish ? 'Sammanfattning (enkel)' : 'Summary (Easy)';
    final balanceEventsSheetName =
        isSwedish ? 'Saldohändelser' : 'Balance Events';

    return ReportExportLabels(
      entriesSheetName: t.reportsExport_entriesSheetName,
      summarySheetName: summarySheetName,
      balanceEventsSheetName: balanceEventsSheetName,
      openingBalanceRow: t.reportsExport_openingBalanceRow,
      timeAdjustmentRow: t.reportsExport_timeAdjustmentRow,
      timeAdjustmentsTotalRow: t.reportsExport_timeAdjustmentsTotalRow,
      periodStartBalanceRow: t.reportsExport_periodStartBalanceRow,
      periodEndBalanceRow: t.reportsExport_periodEndBalanceRow,
      metricHeader: isSwedish ? 'Mått' : 'Metric',
      minutesHeader: isSwedish ? 'Minuter' : 'Minutes',
      hoursHeader: isSwedish ? 'Timmar' : 'Hours',
      periodRow: isSwedish ? 'Period' : 'Period',
      quickReadRow: isSwedish ? 'Snabböversikt' : 'Quick read',
      totalLoggedTimeRow: isSwedish ? 'Totalt loggad tid' : 'Total logged time',
      paidLeaveRow: isSwedish ? 'Ersatt frånvaro' : 'Credited leave',
      accountedTimeRow: isSwedish ? 'Räknad tid' : 'Accounted time',
      plannedTimeRow: isSwedish ? 'Planerad tid' : 'Planned time',
      differenceVsPlanRow:
          isSwedish ? 'Skillnad mot plan' : 'Difference vs plan',
      balanceAfterPeriodRow: isSwedish
          ? 'Din saldo efter perioden'
          : 'Your balance after this period',
      trackedTotalsNote: isSwedish
          ? 'TOTAL (tracked only) exkluderar frånvaro och saldohändelser. Se $summarySheetName.'
          : 'TOTAL (tracked only) excludes Leave and Balance events. See $summarySheetName.',
      colType: t.reportsExport_colType,
      colDate: t.reportsExport_colDate,
      colMinutes: t.reportsExport_colMinutes,
      colHours: t.reportsExport_colHours,
      colNote: t.reportsExport_colNote,
    );
  }

  Future<void> _exportSummary(
    BuildContext context,
    ReportSummary summary,
    _ExportFormat format,
  ) async {
    if (!context.mounted) return;

    final t = AppLocalizations.of(context);
    final labels = _reportExportLabels(t);
    final periodSummary = _buildPeriodSummary(summary);
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffold = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final selectedRange =
        TimeRange.custom(widget.range.start, widget.range.end);
    final start = selectedRange.startInclusive;
    final end = selectedRange.endExclusive.subtract(const Duration(days: 1));
    final contractProvider = context.read<ContractProvider>();
    final trackingStartDate = DateTime(
      contractProvider.trackingStartDate.year,
      contractProvider.trackingStartDate.month,
      contractProvider.trackingStartDate.day,
    );
    final effectiveStart =
        start.isBefore(trackingStartDate) ? trackingStartDate : start;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      late final String filePath;
      final formatValue = format == _ExportFormat.csv ? 'csv' : 'excel';

      if (format == _ExportFormat.csv) {
        filePath = await ExportService.exportReportSummaryToCSV(
          summary: summary,
          periodSummary: periodSummary,
          rangeStart: start,
          rangeEnd: end,
          labels: labels,
          fileName: t.reportsExport_fileName,
          trackingStartDate: trackingStartDate,
          effectiveRangeStart: effectiveStart,
          contractPercent: contractProvider.contractPercent,
          fullTimeHours: contractProvider.fullTimeHours,
        );
      } else {
        filePath = await ExportService.exportReportSummaryToExcel(
          summary: summary,
          periodSummary: periodSummary,
          rangeStart: start,
          rangeEnd: end,
          labels: labels,
          fileName: t.reportsExport_fileName,
          trackingStartDate: trackingStartDate,
          effectiveRangeStart: effectiveStart,
          contractPercent: contractProvider.contractPercent,
          fullTimeHours: contractProvider.fullTimeHours,
        );
      }

      if (navigator.canPop()) {
        navigator.pop();
      }

      if (!kIsWeb && filePath.isNotEmpty && context.mounted) {
        await showExportShareDialog(
          context,
          filePath: filePath,
          fileName: t.reportsExport_fileName,
          format: formatValue,
        );
      } else if (context.mounted) {
        scaffold.showSnackBar(
          SnackBar(
            content:
                Text(t.export_downloadedSuccess(formatValue.toUpperCase())),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (!context.mounted) return;

      scaffold.showSnackBar(
        SnackBar(
          content: Text(t.reportsCustom_exportFailed(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  List<_OverviewPeriodItem> _buildCombinedPeriodItems({
    required List<Entry> entries,
    required List<AbsenceEntry> absences,
  }) {
    final items = <_OverviewPeriodItem>[
      ...entries.map(_OverviewPeriodItem.entry),
      ...absences.map(_OverviewPeriodItem.absence),
    ];

    items.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) {
        return byDate;
      }

      if (a.entry != null && b.entry != null) {
        final aTime = a.entry!.updatedAt ?? a.entry!.createdAt;
        final bTime = b.entry!.updatedAt ?? b.entry!.createdAt;
        return bTime.compareTo(aTime);
      }

      // Keep tracked entries first when date ties, then absences.
      if (a.entry != null && b.absence != null) return -1;
      if (a.absence != null && b.entry != null) return 1;
      return 0;
    });

    return items;
  }

  Widget _buildAbsenceRow(BuildContext context, AbsenceEntry absence) {
    final typeLabel = _absenceTypeLabel(context, absence.type);
    final date = DateFormat('yyyy-MM-dd').format(absence.date);
    final minutesLabel = absence.minutes == 0
        ? AppLocalizations.of(context).leave_fullDay
        : _formatMinutes(absence.minutes);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_note_outlined),
      title: Text(typeLabel),
      subtitle: Text(date),
      trailing: Text(
        minutesLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _absenceTypeLabel(BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return t.leave_paidVacation;
      case AbsenceType.sickPaid:
        return t.leave_sickLeave;
      case AbsenceType.vabPaid:
        return t.leave_vab;
      case AbsenceType.unpaid:
      return t.leave_unpaid;
    case AbsenceType.unknown:
      return t.leave_unknownType;
    }
  }

  Widget _buildEntryRow(BuildContext context, Entry entry) {
    final date = DateFormat('yyyy-MM-dd').format(entry.date);
    final duration = _formatMinutes(entry.totalDuration.inMinutes);
    final travelRoute = _travelRouteText(entry);
    final subtitle =
        entry.type == EntryType.travel ? (travelRoute ?? date) : date;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.type == EntryType.work
            ? Icons.work_outline_rounded
            : Icons.directions_car_outlined,
      ),
      title: Text(
        entry.type == EntryType.work
            ? AppLocalizations.of(context).history_work
            : AppLocalizations.of(context).history_travel,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        duration,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: AppIconSize.xl,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.reportsCustom_emptyTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.reportsCustom_emptySubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.sm, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes, {bool signed = false}) {
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return formatMinutes(
      minutes,
      localeCode: localeCode,
      signed: signed,
      showPlusForZero: signed,
    );
  }

  String? _travelRouteText(Entry entry) {
    if (entry.type != EntryType.travel) return null;
    if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
      final first = entry.travelLegs!.first;
      final last = entry.travelLegs!.last;
      return '${first.fromText} \u2192 ${last.toText}';
    }
    if (entry.from != null && entry.to != null) {
      return '${entry.from} \u2192 ${entry.to}';
    }
    return null;
  }
}

class _OverviewPeriodItem {
  final Entry? entry;
  final AbsenceEntry? absence;
  final DateTime date;

  const _OverviewPeriodItem._({
    required this.entry,
    required this.absence,
    required this.date,
  });

  factory _OverviewPeriodItem.entry(Entry entry) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    return _OverviewPeriodItem._(
      entry: entry,
      absence: null,
      date: date,
    );
  }

  factory _OverviewPeriodItem.absence(AbsenceEntry absence) {
    final date = DateTime(
      absence.date.year,
      absence.date.month,
      absence.date.day,
    );
    return _OverviewPeriodItem._(
      entry: null,
      absence: absence,
      date: date,
    );
  }

  T when<T>({
    required T Function(Entry entry) entry,
    required T Function(AbsenceEntry absence) absence,
  }) {
    final currentEntry = this.entry;
    if (currentEntry != null) {
      return entry(currentEntry);
    }
    return absence(this.absence!);
  }
}

enum _ExportFormat {
  csv,
  excel,
}
