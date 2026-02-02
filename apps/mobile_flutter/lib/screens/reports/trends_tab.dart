import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../design/app_theme.dart';
import '../../models/absence.dart';
import '../../providers/absence_provider.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';
import '../../l10n/generated/app_localizations.dart';

class TrendsTab extends StatefulWidget {
  const TrendsTab({super.key});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  bool _absencesLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsences();
    });
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
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).overview_errorLoadingData,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
        return month.totalHours > 0 || (leaves?.hasAny ?? false);
      }).toList(growable: false);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Monthly Comparison
          Text(
            t.trends_monthlyComparison,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (_absencesLoading || absenceProvider.isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: colorScheme.primary,
                backgroundColor:
                    colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          if (visibleMonths.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                t.overview_noDataAvailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...visibleMonths.map((month) {
              final leaves =
                  leaveSummaries[_monthKey(month.month)] ??
                      _MonthlyLeaveSummary.empty;
              return _buildMonthlyBreakdownCard(
                context,
                theme,
                month,
                leaves,
              );
            }),
          const SizedBox(height: 24),

          // Weekly Hours Chart
          Text(
            AppLocalizations.of(context).trends_weeklyHours,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: _buildWeeklyHoursChart(
                  theme,
                  trendsData['weeklyHours'] as List<double>? ??
                      List.filled(7, 0.0)),
            ),
          ),
          const SizedBox(height: 24),

          // Daily Trends
          Text(
            AppLocalizations.of(context).trends_dailyTrends,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...(trendsData['dailyTrends'] as List<Map<String, dynamic>?>? ?? [])
              .map(
            (dayData) => _buildDailyTrendCard(context, theme, dayData),
          ),
        ],
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading trends data',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try refreshing the page',
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
  ) {
    final t = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final monthLabel = DateFormat('MMM yyyy').format(month.month);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthlyMetric(
                  theme,
                  label: t.trends_work,
                  value: month.workHours,
                  valueColor: colorScheme.error,
                ),
              ),
              Expanded(
                child: _buildMonthlyMetric(
                  theme,
                  label: t.trends_travel,
                  value: month.travelHours,
                  valueColor: colorScheme.tertiary,
                ),
              ),
              Expanded(
                child: _buildMonthlyMetric(
                  theme,
                  label: t.trends_total,
                  value: month.totalHours,
                  valueColor: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (leaves.hasAny) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (leaves.paidVacation > 0)
                  _buildLeaveChip(
                    theme,
                    label: t.leave_paidVacation,
                    count: leaves.paidVacation,
                    color: AbsenceColors.paidVacation,
                  ),
                if (leaves.sickLeave > 0)
                  _buildLeaveChip(
                    theme,
                    label: t.leave_sickLeave,
                    count: leaves.sickLeave,
                    color: AbsenceColors.sickLeave,
                  ),
                if (leaves.vab > 0)
                  _buildLeaveChip(
                    theme,
                    label: t.leave_vab,
                    count: leaves.vab,
                    color: AbsenceColors.vab,
                  ),
                if (leaves.unpaid > 0)
                  _buildLeaveChip(
                    theme,
                    label: t.leave_unpaid,
                    count: leaves.unpaid,
                    color: AbsenceColors.unpaid,
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
    required String label,
    required double value,
    required Color valueColor,
  }) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${value.toStringAsFixed(1)}h',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveChip(
    ThemeData theme, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  Widget _buildWeeklyHoursChart(ThemeData theme, List<double> weeklyHours) {
    final colorScheme = theme.colorScheme;

    if (weeklyHours.isEmpty) {
      return Center(
        child: Text(
          'No hours data available',
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
          'No hours data available',
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
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value >= 0 && value < days.length) {
                  return Text(
                    days[value.toInt()],
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
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
    final workHours = (dayData['workHours'] as double?) ?? 0.0;
    final travelHours = (dayData['travelHours'] as double?) ?? 0.0;
    final totalHours = (dayData['totalHours'] as double?) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getDayAbbreviation(date.weekday),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  '${totalHours.toStringAsFixed(1)}h ${AppLocalizations.of(context).trends_total}',
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
                '${workHours.toStringAsFixed(1)}h ${AppLocalizations.of(context).trends_work}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${travelHours.toStringAsFixed(1)}h ${AppLocalizations.of(context).trends_travel}',
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

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '?';
    }
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

  bool get hasAny =>
      paidVacation > 0 || sickLeave > 0 || vab > 0 || unpaid > 0;
}
