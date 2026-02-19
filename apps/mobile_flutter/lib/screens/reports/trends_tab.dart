import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../design/app_theme.dart';
import '../../models/absence.dart';
import '../../providers/absence_provider.dart';
import '../../providers/time_provider.dart';
import '../../providers/contract_provider.dart';
import '../../reporting/time_format.dart';
import '../../reporting/time_range.dart';
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
      _loadAbsences();
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
    }
  }

  void _syncRangeToViewModel() {
    final endInclusive =
        widget.range.endExclusive.subtract(const Duration(days: 1));
    context
        .read<CustomerAnalyticsViewModel>()
        .setDateRange(widget.range.startInclusive, endInclusive);
  }

  Future<void> _loadAbsences() async {
    if (_absencesLoading) return;
    setState(() => _absencesLoading = true);
    final now = DateTime.now();
    try {
      final absenceProvider = context.read<AbsenceProvider>();
      await absenceProvider.loadAbsences(year: now.year);
      await absenceProvider.loadAbsences(year: now.year - 1);
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
    final timeProvider = context.watch<TimeProvider>();
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
      final visibleMonths = monthlyBreakdown.where((month) {
        final leaves = leaveSummaries[_monthKey(month.month)];
        return month.totalMinutes > 0 || (leaves?.hasAny ?? false);
      }).toList(growable: false);

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
                        timeProvider,
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
      var paidVacation = 0;
      var sickLeave = 0;
      var vab = 0;
      var unpaid = 0;

      for (final absence in absences) {
        if (absence.date.month != month.month.month) continue;
        switch (absence.type) {
          case AbsenceType.vacationPaid:
            paidVacation += 1;
            break;
          case AbsenceType.sickPaid:
            sickLeave += 1;
            break;
          case AbsenceType.vabPaid:
            vab += 1;
            break;
          case AbsenceType.unpaid:
            unpaid += 1;
            break;
        }
      }

      summaries[_monthKey(month.month)] = _MonthlyLeaveSummary(
        paidVacation: paidVacation,
        sickLeave: sickLeave,
        vab: vab,
        unpaid: unpaid,
      );
    }

    return summaries;
  }

  Widget _buildMonthlyBreakdownCard(
    BuildContext context,
    ThemeData theme,
    MonthlyBreakdown month,
    _MonthlyLeaveSummary leaves,
    TimeProvider timeProvider,
    ContractProvider contractProvider,
  ) {
    final t = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final monthLabel = DateFormat('MMM').format(month.month);

    // Calculate monthly target hours
    final monthlyTargetHours = timeProvider.monthlyTargetHours(
      year: month.month.year,
      month: month.month.month,
    );
    final monthlyTargetMinutes = (monthlyTargetHours * 60).round();

    // Calculate variance (actual - target)
    final varianceMinutes = month.totalMinutes - monthlyTargetMinutes;
    final isAhead = varianceMinutes >= 0;
    final statusColor =
        isAhead ? FlexsaldoColors.positive : FlexsaldoColors.negative;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row: Month | Work | Travel | Total | vs Target | Diff
          Row(
            children: [
              // Month label
              SizedBox(
                width: 36,
                child: Text(
                  monthLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              // Work
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatTrackedMinutes(context, month.workMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      t.trends_work,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Travel
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatTrackedMinutes(context, month.travelMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      t.trends_travel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Total
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatTrackedMinutes(context, month.totalMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      t.trends_total,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Target
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatTrackedMinutes(context, monthlyTargetMinutes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      t.trends_target,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Difference
              SizedBox(
                width: 90,
                child: Text(
                  _formatTrackedMinutes(
                    context,
                    varianceMinutes,
                    signed: true,
                    showPlusForZero: true,
                  ),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (leaves.hasAny) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl + AppSpacing.md,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (leaves.paidVacation > 0)
                    _buildLeaveLabel(theme,
                        '${leaves.paidVacation} ${t.leave_paidVacation}'),
                  if (leaves.sickLeave > 0)
                    _buildLeaveLabel(
                        theme, '${leaves.sickLeave} ${t.leave_sickLeave}'),
                  if (leaves.vab > 0)
                    _buildLeaveLabel(theme, '${leaves.vab} ${t.leave_vab}'),
                  if (leaves.unpaid > 0)
                    _buildLeaveLabel(
                        theme, '${leaves.unpaid} ${t.leave_unpaid}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
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
  final int paidVacation;
  final int sickLeave;
  final int vab;
  final int unpaid;

  const _MonthlyLeaveSummary({
    required this.paidVacation,
    required this.sickLeave,
    required this.vab,
    required this.unpaid,
  });

  static const empty = _MonthlyLeaveSummary(
    paidVacation: 0,
    sickLeave: 0,
    vab: 0,
    unpaid: 0,
  );

  bool get hasAny => paidVacation > 0 || sickLeave > 0 || vab > 0 || unpaid > 0;
}
