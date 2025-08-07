import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    // TODO: Replace with proper chart widget
    return CustomPaint(
      painter: _DailyActivityPainter(
        trends: viewModel.dailyTrends,
        travelColor: theme.colorScheme.tertiary,
        workColor: theme.colorScheme.error,
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

class _DailyActivityPainter extends CustomPainter {
  final List<DailyTrend> trends;
  final Color travelColor;
  final Color workColor;

  _DailyActivityPainter({
    required this.trends,
    required this.travelColor,
    required this.workColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final maxMinutes = trends.fold<int>(
      0,
      (max, trend) => trend.totalMinutes > max ? trend.totalMinutes : max,
    );
    if (maxMinutes == 0) return;

    final barWidth = size.width / (trends.length * 2);
    final spacing = barWidth;
    final maxHeight = size.height - 20;

    for (var i = 0; i < trends.length; i++) {
      final trend = trends[i];
      final x = i * (barWidth + spacing);

      // Travel bar
      if (trend.travelMinutes > 0) {
        final travelHeight = (trend.travelMinutes / maxMinutes) * maxHeight;
        final travelRect = Rect.fromLTWH(
          x,
          size.height - travelHeight,
          barWidth,
          travelHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(travelRect, const Radius.circular(4)),
          Paint()..color = travelColor,
        );
      }

      // Work bar
      if (trend.workMinutes > 0) {
        final workHeight = (trend.workMinutes / maxMinutes) * maxHeight;
        final workRect = Rect.fromLTWH(
          x + barWidth + (spacing / 2),
          size.height - workHeight,
          barWidth,
          workHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(workRect, const Radius.circular(4)),
          Paint()..color = workColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailyActivityPainter oldDelegate) {
    return trends != oldDelegate.trends ||
        travelColor != oldDelegate.travelColor ||
        workColor != oldDelegate.workColor;
  }
}
