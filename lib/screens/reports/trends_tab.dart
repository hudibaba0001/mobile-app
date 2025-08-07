import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';

class TrendsTab extends StatelessWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<CustomerAnalyticsViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Activity Chart
        Text(
          'Daily Activity',
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
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _buildDailyActivityChart(theme, viewModel),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      theme,
                      color: colorScheme.tertiary,
                      label: 'Travel',
                    ),
                    const SizedBox(width: 24),
                    _buildLegendItem(
                      theme,
                      color: colorScheme.error,
                      label: 'Work',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Weekly Summary
        Text(
          'Weekly Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildWeeklySummaryRow(
                theme,
                label: 'Average Daily Travel',
                value: '1:45',
                trend: 0.12,
              ),
              const Divider(height: 32),
              _buildWeeklySummaryRow(
                theme,
                label: 'Average Daily Work',
                value: '6:30',
                trend: -0.05,
              ),
              const Divider(height: 32),
              _buildWeeklySummaryRow(
                theme,
                label: 'Most Active Day',
                value: 'Wednesday',
                showTrend: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Monthly Comparison
        Text(
          'Monthly Comparison',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildMonthlyComparisonRow(
                theme,
                label: 'Total Hours',
                currentValue: '165:30',
                previousValue: '158:45',
              ),
              const Divider(height: 32),
              _buildMonthlyComparisonRow(
                theme,
                label: 'Travel Time',
                currentValue: '35:15',
                previousValue: '32:30',
              ),
              const Divider(height: 32),
              _buildMonthlyComparisonRow(
                theme,
                label: 'Work Time',
                currentValue: '130:15',
                previousValue: '126:15',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyActivityChart(
      ThemeData theme, CustomerAnalyticsViewModel viewModel) {
    if (viewModel.dailyTrends.isEmpty) {
      return Center(
        child: Text(
          'No data for selected period',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: viewModel.dailyTrends.fold<double>(
          0,
          (max, trend) => trend.totalMinutes > max ? trend.totalMinutes.toDouble() : max,
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: theme.colorScheme.surface,
            tooltipRoundedRadius: 8,
            tooltipBorder: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final trend = viewModel.dailyTrends[groupIndex];
              final minutes = rodIndex == 0 ? trend.travelMinutes : trend.workMinutes;
              final hours = minutes ~/ 60;
              final remainingMinutes = minutes % 60;
              return BarTooltipItem(
                '${hours}h ${remainingMinutes}m',
                theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= viewModel.dailyTrends.length) {
                  return const SizedBox();
                }
                final date = viewModel.dailyTrends[value.toInt()].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final hours = value ~/ 60;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${hours}h',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 120, // 2-hour intervals
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: viewModel.dailyTrends.asMap().entries.map((entry) {
          final index = entry.key;
          final trend = entry.value;
          return BarChartGroupData(
            x: index,
            groupVertically: true,
            barRods: [
              BarChartRodData(
                toY: trend.travelMinutes.toDouble(),
                color: theme.colorScheme.tertiary,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: trend.workMinutes.toDouble(),
                color: theme.colorScheme.error,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryRow(
    ThemeData theme, {
    required String label,
    required String value,
    double? trend,
    bool showTrend = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (showTrend && trend != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (trend >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trend >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: trend >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(trend.abs() * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: trend >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlyComparisonRow(
    ThemeData theme, {
    required String label,
    required String currentValue,
    required String previousValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    currentValue,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'vs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    previousValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}


