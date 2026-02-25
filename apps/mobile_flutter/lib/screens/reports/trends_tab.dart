import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../calendar/sweden_holidays.dart';
import '../../design/app_theme.dart';
import '../../design/components/components.dart';
import '../../models/absence.dart';
import '../../providers/absence_provider.dart';
import '../../providers/contract_provider.dart';
import '../../reporting/accounted_time_calculator.dart';
import '../../reporting/time_format.dart';
import '../../reporting/time_range.dart';
import '../../services/holiday_service.dart';
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
    final holidayService = context.watch<HolidayService?>();

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
      final leaveSummaries = _buildMonthlyLeaveSummaries(
        monthlyBreakdown,
        absenceProvider,
        weeklyTargetMinutes: contractProvider.weeklyTargetMinutes,
        holidayService: holidayService,
      );
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
            Column(
              children: visibleMonths.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final month = mapEntry.value;
                final leaves = leaveSummaries[_monthKey(month.month)] ??
                    _MonthlyLeaveSummary.empty;
                final isLast = index == visibleMonths.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                  child: _buildMonthlyBreakdownCard(
                    context,
                    theme,
                    month,
                    leaves,
                    contractProvider,
                  ),
                );
              }).toList(),
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
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              borderRadius: BorderRadius.circular(AppRadius.md),
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
    AbsenceProvider absenceProvider, {
    required int weeklyTargetMinutes,
    HolidayService? holidayService,
  }) {
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
      final byDate = <DateTime, List<AbsenceEntry>>{};

      for (final absence in absences) {
        if (absence.date.month != month.month.month) continue;
        final date =
            DateTime(absence.date.year, absence.date.month, absence.date.day);
        byDate.putIfAbsent(date, () => <AbsenceEntry>[]).add(absence);
        switch (absence.type) {
          case AbsenceType.vacationPaid:
            paidVacationCount += 1;
            break;
          case AbsenceType.sickPaid:
            sickLeaveCount += 1;
            break;
          case AbsenceType.vabPaid:
            vabCount += 1;
            break;
          case AbsenceType.unpaid:
            unpaidCount += 1;
            break;
          case AbsenceType.unknown:
            // Skip or log unknown types for trends
            break;
        }
      }

      final orderedDates = byDate.keys.toList()..sort();
      for (final date in orderedDates) {
        final dayAbsences = byDate[date]!;
        final scheduled = _scheduledMinutesForDate(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          holidayService: holidayService,
        );

        final credited =
            absenceProvider.paidAbsenceMinutesForDate(date, scheduled);
        final paidAllocations =
            _allocatePaidCreditedMinutesByType(dayAbsences, credited);
        paidVacationMinutes += paidAllocations[AbsenceType.vacationPaid] ?? 0;
        sickLeaveMinutes += paidAllocations[AbsenceType.sickPaid] ?? 0;
        vabMinutes += paidAllocations[AbsenceType.vabPaid] ?? 0;

        unpaidMinutes += _unpaidMinutesForDate(dayAbsences, scheduled);
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

  int _scheduledMinutesForDate({
    required DateTime date,
    required int weeklyTargetMinutes,
    HolidayService? holidayService,
  }) {
    if (holidayService != null) {
      final redDayInfo = holidayService.getRedDayInfo(date);
      if (redDayInfo.isRedDay) {
        return TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          isFullRedDay: redDayInfo.isFullDay,
          isHalfRedDay: redDayInfo.halfDay != null,
        );
      }
    }

    return TargetHoursCalculator.scheduledMinutesForDate(
      date: date,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
  }

  Map<AbsenceType, int> _allocatePaidCreditedMinutesByType(
    List<AbsenceEntry> dayAbsences,
    int creditedMinutes,
  ) {
    final allocations = <AbsenceType, int>{
      AbsenceType.vacationPaid: 0,
      AbsenceType.sickPaid: 0,
      AbsenceType.vabPaid: 0,
    };
    if (creditedMinutes <= 0) {
      return allocations;
    }

    final paidAbsences =
        dayAbsences.where((absence) => absence.isPaid).toList();
    if (paidAbsences.isEmpty) {
      return allocations;
    }

    final hasFullDay = paidAbsences.any((absence) => absence.minutes == 0);
    if (hasFullDay) {
      final fullDay = paidAbsences.firstWhere(
        (absence) => absence.minutes == 0,
        orElse: () => paidAbsences.first,
      );
      final type = fullDay.type;
      allocations[type] = (allocations[type] ?? 0) + creditedMinutes;
      return allocations;
    }

    final totalRawPaidMinutes = paidAbsences.fold<int>(
      0,
      (sum, absence) => sum + absence.minutes,
    );
    if (totalRawPaidMinutes <= 0) {
      final firstType = paidAbsences.first.type;
      allocations[firstType] = (allocations[firstType] ?? 0) + creditedMinutes;
      return allocations;
    }

    var remaining = creditedMinutes;
    for (var i = 0; i < paidAbsences.length; i++) {
      final absence = paidAbsences[i];
      final isLast = i == paidAbsences.length - 1;
      var allocated = isLast
          ? remaining
          : ((creditedMinutes * absence.minutes) / totalRawPaidMinutes).round();
      if (allocated < 0) allocated = 0;
      if (allocated > remaining) allocated = remaining;

      allocations[absence.type] = (allocations[absence.type] ?? 0) + allocated;
      remaining -= allocated;
      if (remaining <= 0) break;
    }

    return allocations;
  }

  int _unpaidMinutesForDate(
      List<AbsenceEntry> dayAbsences, int scheduledMinutes) {
    final unpaidAbsences = dayAbsences
        .where((absence) => absence.type == AbsenceType.unpaid)
        .toList();
    if (unpaidAbsences.isEmpty) {
      return 0;
    }

    final hasFullDay = unpaidAbsences.any((absence) => absence.minutes == 0);
    if (hasFullDay) {
      return scheduledMinutes;
    }

    final totalUnpaidMinutes = unpaidAbsences.fold<int>(
      0,
      (sum, absence) => sum + absence.minutes,
    );
    return totalUnpaidMinutes < scheduledMinutes
        ? totalUnpaidMinutes
        : scheduledMinutes;
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

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTrackedMinutes(
                      context,
                      accounted.deltaMinutes,
                      signed: true,
                      showPlusForZero: true,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.reportsMetric_delta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: _buildMonthlyMetric(
                  theme,
                  value: _formatTrackedMinutes(
                      context, accounted.accountedMinutes),
                  label: t.reportsMetric_accounted,
                ),
              ),
              SizedBox(
                width: 120,
                child: _buildMonthlyMetric(
                  theme,
                  value:
                      _formatTrackedMinutes(context, accounted.targetMinutes),
                  label: t.trends_target,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: _buildMonthlyMetric(
                  theme,
                  value: _formatTrackedMinutes(context, month.workMinutes),
                  label: t.trends_work,
                ),
              ),
              SizedBox(
                width: 120,
                child: _buildMonthlyMetric(
                  theme,
                  value: _formatTrackedMinutes(context, month.travelMinutes),
                  label: t.trends_travel,
                ),
              ),
              SizedBox(
                width: 120,
                child: _buildMonthlyMetric(
                  theme,
                  value: _formatTrackedMinutes(context, accounted.leaveMinutes),
                  label: t.reportsMetric_leave,
                ),
              ),
            ],
          ),
          if (leaves.hasAny) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (leaves.paidVacationCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.paidVacationMinutes)} ${t.leave_paidVacation}',
                  ),
                if (leaves.sickLeaveCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.sickLeaveMinutes)} ${t.leave_sickLeave}',
                  ),
                if (leaves.vabCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.vabMinutes)} ${t.leave_vab}',
                  ),
                if (leaves.unpaidCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.unpaidMinutes)} ${t.leave_unpaid}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyMetric(
    ThemeData theme, {
    required String value,
    required String label,
  }) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
                width: 24,
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
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Text(
            AppLocalizations.of(context).overview_noDataAvailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final date = dayData['date'] as DateTime? ?? DateTime.now();
    final workMinutes = (dayData['workMinutes'] as int?) ?? 0;
    final travelMinutes = (dayData['travelMinutes'] as int?) ?? 0;
    final totalMinutes = (dayData['totalMinutes'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayAbbreviation(context, date.weekday),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTrackedMinutes(context, totalMinutes),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).trends_total,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_rounded,
                        size: AppIconSize.xs,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatTrackedMinutes(context, workMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: AppIconSize.xs,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatTrackedMinutes(context, travelMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
