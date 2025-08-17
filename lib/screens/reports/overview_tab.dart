import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<CustomerAnalyticsViewModel>();

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
              'Error loading data',
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

    final overviewData = viewModel.overviewData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.timer_rounded,
                iconColor: colorScheme.primary,
                iconBgColor: colorScheme.primary.withOpacity(0.1),
                title: 'Total Hours',
                value: '${overviewData['totalHours'].toStringAsFixed(1)}h',
                subtitle: 'All activities',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.assignment_rounded,
                iconColor: colorScheme.secondary,
                iconBgColor: colorScheme.secondary.withOpacity(0.1),
                title: 'Total Entries',
                value: '${overviewData['totalEntries']}',
                subtitle: 'This period',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.directions_car_rounded,
                iconColor: colorScheme.tertiary,
                iconBgColor: colorScheme.tertiary.withOpacity(0.1),
                title: 'Travel Time',
                value: _formatMinutes(overviewData['totalTravelMinutes']),
                subtitle: 'Total commute',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.work_rounded,
                iconColor: colorScheme.error,
                iconBgColor: colorScheme.error.withOpacity(0.1),
                title: 'Work Time',
                value: _formatMinutes(overviewData['totalWorkMinutes']),
                subtitle: 'Total work',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Insights
        Text(
          'Quick Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...(overviewData['quickInsights'] as List<Map<String, dynamic>>).map(
          (insight) => _buildInsightCard(theme, insight),
        ),
        const SizedBox(height: 24),

        // Activity Distribution
        Text(
          'Activity Distribution',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.5,
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
                  child: _buildDistributionChart(theme, overviewData),
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

        // Recent Activity
        Row(
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to history screen
              },
              child: Text(
                'View All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // TODO: Add recent activity list
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme, Map<String, dynamic> insight) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              insight['icon'] as String,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            insight['trend'] == 'positive'
                ? Icons.trending_up
                : insight['trend'] == 'negative'
                    ? Icons.trending_down
                    : Icons.trending_flat,
            color: insight['trend'] == 'positive'
                ? Colors.green
                : insight['trend'] == 'negative'
                    ? Colors.red
                    : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(
      ThemeData theme, Map<String, dynamic> overviewData) {
    final colorScheme = theme.colorScheme;
    final workMinutes = overviewData['totalWorkMinutes'] as int;
    final travelMinutes = overviewData['totalTravelMinutes'] as int;
    final totalMinutes = workMinutes + travelMinutes;

    if (totalMinutes == 0) {
      return Center(
        child: Text(
          'No data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: workMinutes.toDouble(),
            title:
                '${((workMinutes / totalMinutes) * 100).toStringAsFixed(1)}%',
            color: colorScheme.error,
            radius: 60,
            titleStyle: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: travelMinutes.toDouble(),
            title:
                '${((travelMinutes / totalMinutes) * 100).toStringAsFixed(1)}%',
            color: colorScheme.tertiary,
            radius: 60,
            titleStyle: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
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

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return remainingMinutes > 0
          ? '${hours}h ${remainingMinutes}m'
          : '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }
}
