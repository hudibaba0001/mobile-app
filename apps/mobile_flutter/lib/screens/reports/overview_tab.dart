import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../design/app_theme.dart';
import '../../models/absence.dart';
import '../../models/entry.dart';
import '../../repositories/balance_adjustment_repository.dart';
import '../../reports/report_aggregator.dart';
import '../../reports/report_query_service.dart';
import '../../services/export_service.dart';
import '../../services/supabase_auth_service.dart';
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
    final queryService = ReportQueryService(
      authService: context.read<SupabaseAuthService>(),
      adjustmentRepository: BalanceAdjustmentRepository(SupabaseConfig.client),
    );

    final aggregator = ReportAggregator(queryService: queryService);

    final summary = await aggregator.buildSummary(
      start: widget.range.start,
      end: widget.range.end,
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

    Widget buildChip(ReportSegment segment, String label, IconData icon) {
      final selected = widget.segment == segment;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? colorScheme.onPrimary : null),
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
                ..._buildSegmentCards(context, summary),
                const SizedBox(height: AppSpacing.lg),
                _buildBalanceAdjustmentsSection(context, summary),
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

  List<Widget> _buildSegmentCards(BuildContext context, ReportSummary summary) {
    switch (widget.segment) {
      case ReportSegment.all:
        return _buildAllCards(context, summary);
      case ReportSegment.work:
        return _buildWorkCards(context, summary);
      case ReportSegment.travel:
        return _buildTravelCards(context, summary);
      case ReportSegment.leave:
        return _buildLeaveCards(context, summary);
    }
  }

  List<Widget> _buildAllCards(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.timer_rounded,
              title: t.overview_totalHours,
              value: _formatMinutes(summary.totalTrackedMinutes),
              subtitle: t.overview_allActivities,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.assignment_rounded,
              title: t.overview_totalEntries,
              value: '${summary.filteredEntries.length}',
              subtitle: t.overview_thisPeriod,
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
              icon: Icons.work_rounded,
              title: t.overview_workTime,
              value: _formatMinutes(summary.workMinutes),
              subtitle: t.overview_totalWork,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.directions_car_rounded,
              title: t.overview_travelTime,
              value: _formatMinutes(summary.travelMinutes),
              subtitle: t.overview_totalCommute,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildWorkCards(BuildContext context, ReportSummary summary) {
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
              value: _formatMinutes(summary.workMinutes),
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

  List<Widget> _buildTravelCards(BuildContext context, ReportSummary summary) {
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
              value: _formatMinutes(summary.travelMinutes),
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
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
        ),
      ],
    ];
  }

  List<Widget> _buildLeaveCards(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    final leaves = summary.leavesSummary;
    final unpaid = leaves.byType[AbsenceType.unpaid]?.totalMinutes ?? 0;
    final paid = leaves.totalMinutes - unpaid;

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
      BuildContext context, ReportSummary summary) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final opening = summary.balanceOffsets.openingEvent;
    final adjustments = summary.balanceOffsets.adjustmentsInRange;
    final totalAdjustments = summary.balanceAdjustmentMinutesInRange;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                  summary.startingBalanceMinutes,
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
                  summary.closingBalanceMinutes,
                  signed: true,
                ),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntrySlivers(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);
    final entries = summary.filteredEntries;

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: _buildListSectionHeader(
            context,
            '${t.reportsCustom_entriesInPeriod} (${entries.length})',
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
      if (entries.isEmpty)
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
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildListRowCard(
                    context,
                    child: _buildEntryRow(context, entry),
                  ),
                );
              },
              childCount: entries.length,
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  Widget _buildListRowCard(
    BuildContext context, {
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: child,
      ),
    );
  }

  Widget _buildEmptySectionCard(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildEmptyState(context),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context, ReportSummary summary) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
      ),
    );
  }

  ReportExportLabels _reportExportLabels(AppLocalizations t) {
    return ReportExportLabels(
      entriesSheetName: t.reportsExport_entriesSheetName,
      adjustmentsSheetName: t.reportsExport_adjustmentsSheetName,
      openingBalanceRow: t.reportsExport_openingBalanceRow,
      timeAdjustmentRow: t.reportsExport_timeAdjustmentRow,
      timeAdjustmentsTotalRow: t.reportsExport_timeAdjustmentsTotalRow,
      periodStartBalanceRow: t.reportsExport_periodStartBalanceRow,
      periodEndBalanceRow: t.reportsExport_periodEndBalanceRow,
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
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffold = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final start = DateTime(
      widget.range.start.year,
      widget.range.start.month,
      widget.range.start.day,
    );
    final end = DateTime(
      widget.range.end.year,
      widget.range.end.month,
      widget.range.end.day,
    );

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
          rangeStart: start,
          rangeEnd: end,
          labels: labels,
          fileName: t.reportsExport_fileName,
        );
      } else {
        filePath = await ExportService.exportReportSummaryToExcel(
          summary: summary,
          rangeStart: start,
          rangeEnd: end,
          labels: labels,
          fileName: t.reportsExport_fileName,
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

      scaffold.showSnackBar(
        SnackBar(
          content: Text(t.reportsCustom_exportFailed(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    }
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
            size: 40,
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
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
    final absMinutes = minutes.abs();
    final h = absMinutes ~/ 60;
    final m = absMinutes % 60;
    final base = m == 0 ? '${h}h' : '${h}h ${m}m';

    if (!signed) return base;
    final sign = minutes < 0 ? '-' : '+';
    return '$sign$base';
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

enum _ExportFormat {
  csv,
  excel,
}
