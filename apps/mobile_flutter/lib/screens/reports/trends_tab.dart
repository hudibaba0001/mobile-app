import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../calendar/sweden_holidays.dart';
import '../../design/app_theme.dart';
import '../../models/absence.dart';
import '../../providers/absence_provider.dart';
import '../../providers/contract_provider.dart';
import '../../reporting/accounted_time_calculator.dart';
import '../../reporting/leave_minutes.dart';
import '../../reporting/time_format.dart';
import '../../reporting/time_range.dart';
import '../../utils/target_hours_calculator.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';
import '../../l10n/generated/app_localizations.dart';

class TrendsTab extends StatefulWidget {
  final TimeRange range;

  const TrendsTab({
    super.key,
    required this.range,
  });

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  bool _absencesLoading = false;
  final SwedenHolidayCalendar _holidays = SwedenHolidayCalendar();

  String _formatTrackedMinutes(
    BuildContext context,
    int minutes, {
    bool signed = false,
    bool showPlusForZero = false,
  }) {
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return formatMinutes(
      minutes,
      localeCode: localeCode,
      signed: signed,
      showPlusForZero: showPlusForZero,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRangeToViewModel();
      _loadAbsencesForRange();
    });
  }

  @override
  void didUpdateWidget(covariant TrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rangeChanged =
        oldWidget.range.startInclusive != widget.range.startInclusive ||
            oldWidget.range.endExclusive != widget.range.endExclusive;
    if (rangeChanged) {
      _syncRangeToViewModel();
      _loadAbsencesForRange();
    }
  }

  void _syncRangeToViewModel() {
    final endInclusive =
        widget.range.endExclusive.subtract(const Duration(days: 1));
    context
        .read<CustomerAnalyticsViewModel>()
        .setDateRange(widget.range.startInclusive, endInclusive);
  }

  Set<int> _rangeYears() {
    final startYear = widget.range.startInclusive.year;
    final endInclusive =
        widget.range.endExclusive.subtract(const Duration(days: 1));
    final endYear = endInclusive.year;
    return {for (int year = startYear; year <= endYear; year++) year};
  }

  Future<void> _loadAbsencesForRange() async {
    if (_absencesLoading) return;
    setState(() => _absencesLoading = true);
    try {
      final absenceProvider = context.read<AbsenceProvider>();
      for (final year in _rangeYears()) {
        await absenceProvider.loadAbsences(year: year);
      }
    } finally {
      if (mounted) {
        setState(() => _absencesLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final viewModel = context.watch<CustomerAnalyticsViewModel>();
    final absenceProvider = context.watch<AbsenceProvider>();
    final contractProvider = context.watch<ContractProvider>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context).overview_errorLoadingData,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              viewModel.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    try {
      final trendsData = viewModel.trendsData;
      final monthlyBreakdown = viewModel.monthlyBreakdown;
      final leaveSummaries =
          _buildMonthlyLeaveSummaries(monthlyBreakdown, absenceProvider);
      final visibleMonths = monthlyBreakdown;

      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Monthly Comparison
          _buildSectionHeader(
            theme,
            t.trends_monthlyComparison,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_absencesLoading || absenceProvider.isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          if (visibleMonths.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  t.overview_noDataAvailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: visibleMonths.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final month = mapEntry.value;
                  final leaves = leaveSummaries[_monthKey(month.month)] ??
                      _MonthlyLeaveSummary.empty;
                  final isLast = index == visibleMonths.length - 1;
                  return Column(
                    children: [
                      _buildMonthlyBreakdownCard(
                        context,
                        theme,
                        month,
                        leaves,
                        contractProvider,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Weekly Hours Chart
          _buildSectionHeader(
            theme,
            AppLocalizations.of(context).trends_weeklyHours,
          ),
          const SizedBox(height: AppSpacing.md),
          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: _buildWeeklyHoursChart(
                  theme,
                  trendsData['weeklyMinutes'] as List<int>? ??
                      List.filled(7, 0)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Daily Trends
          _buildSectionHeader(
            theme,
            AppLocalizations.of(context).trends_dailyTrends,
          ),
          const SizedBox(height: AppSpacing.md),
          ...(trendsData['dailyTrends'] as List<Map<String, dynamic>?>? ?? [])
              .map(
            (dayData) => _buildDailyTrendCard(context, theme, dayData),
          ),
        ],
      );
    } catch (e) {
      final t = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.trends_errorLoadingData,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.trends_tryRefreshingPage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Map<String, _MonthlyLeaveSummary> _buildMonthlyLeaveSummaries(
    List<MonthlyBreakdown> months,
    AbsenceProvider absenceProvider,
  ) {
    final summaries = <String, _MonthlyLeaveSummary>{};
    final years = months.map((m) => m.month.year).toSet();
    final absencesByYear = <int, List<AbsenceEntry>>{
      for (final year in years) year: absenceProvider.absencesForYear(year)
    };

    for (final month in months) {
      final absences = absencesByYear[month.month.year] ?? [];
      var paidVacationCount = 0;
      var paidVacationMinutes = 0;
      var sickLeaveCount = 0;
      var sickLeaveMinutes = 0;
      var vabCount = 0;
      var vabMinutes = 0;
      var unpaidCount = 0;
      var unpaidMinutes = 0;

      for (final absence in absences) {
        if (absence.date.month != month.month.month) continue;
        final minutes = normalizedLeaveMinutes(absence);
        switch (absence.type) {
          case AbsenceType.vacationPaid:
            paidVacationCount += 1;
            paidVacationMinutes += minutes;
            break;
          case AbsenceType.sickPaid:
            sickLeaveCount += 1;
            sickLeaveMinutes += minutes;
            break;
          case AbsenceType.vabPaid:
            vabCount += 1;
            vabMinutes += minutes;
            break;
          case AbsenceType.unpaid:
            unpaidCount += 1;
            unpaidMinutes += minutes;
            break;
          case AbsenceType.unknown:
            // Skip or log unknown types for trends
            break;
        }
      }

      summaries[_monthKey(month.month)] = _MonthlyLeaveSummary(
        paidVacationCount: paidVacationCount,
        paidVacationMinutes: paidVacationMinutes,
        sickLeaveCount: sickLeaveCount,
        sickLeaveMinutes: sickLeaveMinutes,
        vabCount: vabCount,
        vabMinutes: vabMinutes,
        unpaidCount: unpaidCount,
        unpaidMinutes: unpaidMinutes,
      );
    }

    return summaries;
  }

  Widget _buildMonthlyBreakdownCard(
    BuildContext context,
    ThemeData theme,
    MonthlyBreakdown month,
    _MonthlyLeaveSummary leaves,
    ContractProvider contractProvider,
  ) {
    final t = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final monthLabel = DateFormat('MMM').format(month.month);
    final monthlyTargetMinutes = TargetHoursCalculator.monthlyScheduledMinutes(
      year: month.month.year,
      month: month.month.month,
      weeklyTargetMinutes: contractProvider.weeklyTargetMinutes,
      holidays: _holidays,
    );
    final accounted = AccountedTimeCalculator.compute(
      trackedMinutes: month.totalMinutes,
      leaveMinutes: leaves.creditedMinutes,
      targetMinutes: monthlyTargetMinutes,
    );
    final isAhead = accounted.deltaMinutes >= 0;
    final statusColor =
        isAhead ? FlexsaldoColors.positive : FlexsaldoColors.negative;
    final deltaValue = _formatTrackedMinutes(
      context,
      accounted.deltaMinutes,
      signed: true,
      showPlusForZero: true,
    );
    final workMinutes = month.workMinutes;
    final travelMinutes = month.travelMinutes;
    final leaveMinutes = accounted.leaveMinutes;
    final compositionTotal = workMinutes + travelMinutes + leaveMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthLabel.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      monthLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.overview_differenceVsPlan,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        deltaValue,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildMonthlyStatTile(
                      theme,
                      label: t.overview_accountedTime,
                      value: _formatTrackedMinutes(
                        context,
                        accounted.accountedMinutes,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildMonthlyStatTile(
                      theme,
                      label: t.overview_plannedTime,
                      value: _formatTrackedMinutes(
                        context,
                        accounted.targetMinutes,
                      ),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      if (workMinutes > 0)
                        Expanded(
                          flex: workMinutes,
                          child: ColoredBox(
                            color: colorScheme.primary,
                          ),
                        ),
                      if (travelMinutes > 0)
                        Expanded(
                          flex: travelMinutes,
                          child: ColoredBox(
                            color: colorScheme.tertiary,
                          ),
                        ),
                      if (leaveMinutes > 0)
                        Expanded(
                          flex: leaveMinutes,
                          child: ColoredBox(
                            color: colorScheme.secondary,
                          ),
                        ),
                      if (compositionTotal == 0)
                        Expanded(
                          child: ColoredBox(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildMonthlyLegendItem(
                      theme,
                      dotColor: colorScheme.primary,
                      label: t.trends_work,
                      value: _formatTrackedMinutes(context, workMinutes),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMonthlyLegendItem(
                      theme,
                      dotColor: colorScheme.tertiary,
                      label: t.trends_travel,
                      value: _formatTrackedMinutes(context, travelMinutes),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildMonthlyLegendItem(
                      theme,
                      dotColor: colorScheme.secondary,
                      label: t.reportsMetric_leave,
                      value: _formatTrackedMinutes(context, leaveMinutes),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (leaves.hasAny) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leaves.paidVacationCount > 0)
                        _buildLeaveLine(
                          theme,
                          label: t.leave_paidVacation,
                          value: _formatTrackedMinutes(
                            context,
                            leaves.paidVacationMinutes,
                          ),
                        ),
                      if (leaves.sickLeaveCount > 0)
                        _buildLeaveLine(
                          theme,
                          label: t.leave_sickLeave,
                          value: _formatTrackedMinutes(
                            context,
                            leaves.sickLeaveMinutes,
                          ),
                        ),
                      if (leaves.vabCount > 0)
                        _buildLeaveLine(
                          theme,
                          label: t.leave_vab,
                          value: _formatTrackedMinutes(
                            context,
                            leaves.vabMinutes,
                          ),
                        ),
                      if (leaves.unpaidCount > 0)
                        _buildLeaveLine(
                          theme,
                          label: t.leave_unpaid,
                          value: _formatTrackedMinutes(
                            context,
                            leaves.unpaidMinutes,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyStatTile(
    ThemeData theme, {
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLegendItem(
    ThemeData theme, {
    required Color dotColor,
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildLeaveLine(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  Widget _buildWeeklyHoursChart(ThemeData theme, List<int> weeklyMinutes) {
    final t = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final colorScheme = theme.colorScheme;
    final weeklyHours =
        weeklyMinutes.map((minutes) => minutes / 60.0).toList(growable: false);

    if (weeklyHours.isEmpty) {
      return Center(
        child: Text(
          t.trends_noHoursDataAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final maxHours = weeklyHours.reduce((a, b) => a > b ? a : b);

    if (maxHours == 0) {
      return Center(
        child: Text(
          t.trends_noHoursDataAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxHours * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < 7) {
                  final weekdayDate =
                      DateTime(2024, 1, 1).add(Duration(days: value.toInt()));
                  final dayLabel = DateFormat.E(localeTag).format(weekdayDate);
                  return Text(
                    dayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 68,
              getTitlesWidget: (value, meta) {
                return Text(
                  formatMinutes(
                    (value * 60).round(),
                    localeCode: localeTag,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: weeklyHours.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: colorScheme.secondary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.xs)),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxHours / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  Widget _buildDailyTrendCard(
      BuildContext context, ThemeData theme, Map<String, dynamic>? dayData) {
    final colorScheme = theme.colorScheme;

    // Handle null dayData
    if (dayData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).overview_noDataAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final date = dayData['date'] as DateTime? ?? DateTime.now();
    final workMinutes = (dayData['workMinutes'] as int?) ?? 0;
    final travelMinutes = (dayData['travelMinutes'] as int?) ?? 0;
    final totalMinutes = (dayData['totalMinutes'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _getDayAbbreviation(context, date.weekday),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.month}/${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_formatTrackedMinutes(context, totalMinutes)} ${AppLocalizations.of(context).trends_total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatTrackedMinutes(context, workMinutes)} ${AppLocalizations.of(context).trends_work}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_formatTrackedMinutes(context, travelMinutes)} ${AppLocalizations.of(context).trends_travel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDayAbbreviation(BuildContext context, int weekday) {
    if (weekday < 1 || weekday > 7) return '?';
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime(2024, 1, weekday);
    final shortName = DateFormat.E(localeTag).format(date);
    return shortName.isNotEmpty ? shortName[0].toUpperCase() : '?';
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MonthlyLeaveSummary {
  final int paidVacationCount;
  final int paidVacationMinutes;
  final int sickLeaveCount;
  final int sickLeaveMinutes;
  final int vabCount;
  final int vabMinutes;
  final int unpaidCount;
  final int unpaidMinutes;

  const _MonthlyLeaveSummary({
    required this.paidVacationCount,
    required this.paidVacationMinutes,
    required this.sickLeaveCount,
    required this.sickLeaveMinutes,
    required this.vabCount,
    required this.vabMinutes,
    required this.unpaidCount,
    required this.unpaidMinutes,
  });

  static const empty = _MonthlyLeaveSummary(
    paidVacationCount: 0,
    paidVacationMinutes: 0,
    sickLeaveCount: 0,
    sickLeaveMinutes: 0,
    vabCount: 0,
    vabMinutes: 0,
    unpaidCount: 0,
    unpaidMinutes: 0,
  );

  int get creditedMinutes =>
      paidVacationMinutes + sickLeaveMinutes + vabMinutes;

  bool get hasAny =>
      paidVacationCount > 0 ||
      sickLeaveCount > 0 ||
      vabCount > 0 ||
      unpaidCount > 0;
}
