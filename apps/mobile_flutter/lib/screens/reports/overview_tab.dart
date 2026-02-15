import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../design/app_theme.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';
import '../../l10n/generated/app_localizations.dart';

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

    final overviewData = viewModel.overviewData;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.timer_rounded,
                iconColor: colorScheme.primary,
                iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
                title: AppLocalizations.of(context).overview_totalHours,
                value: '${overviewData['totalHours'].toStringAsFixed(1)}h',
                subtitle: AppLocalizations.of(context).overview_allActivities,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.assignment_rounded,
                iconColor: colorScheme.secondary,
                iconBgColor: colorScheme.secondary.withValues(alpha: 0.1),
                title: AppLocalizations.of(context).overview_totalEntries,
                value: '${overviewData['totalEntries']}',
                subtitle: AppLocalizations.of(context).overview_thisPeriod,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.directions_car_rounded,
                iconColor: colorScheme.tertiary,
                iconBgColor: colorScheme.tertiary.withValues(alpha: 0.1),
                title: AppLocalizations.of(context).overview_travelTime,
                value: _formatMinutes(overviewData['totalTravelMinutes']),
                subtitle: AppLocalizations.of(context).overview_totalCommute,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.work_rounded,
                iconColor: colorScheme.error,
                iconBgColor: colorScheme.error.withValues(alpha: 0.1),
                title: AppLocalizations.of(context).overview_workTime,
                value: _formatMinutes(overviewData['totalWorkMinutes']),
                subtitle: AppLocalizations.of(context).overview_totalWork,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Activity Distribution
        Text(
          AppLocalizations.of(context).overview_activityDistribution,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl - AppSpacing.xs),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _buildDistributionChart(context, theme, overviewData),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  children: [
                    _buildLegendItem(
                      theme,
                      color: colorScheme.tertiary,
                      label: AppLocalizations.of(context).overview_travel,
                    ),
                    _buildLegendItem(
                      theme,
                      color: colorScheme.error,
                      label: AppLocalizations.of(context).overview_work,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl - AppSpacing.xs),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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

  Widget _buildDistributionChart(BuildContext context, ThemeData theme,
      Map<String, dynamic> overviewData) {
    final colorScheme = theme.colorScheme;
    final workMinutes = overviewData['totalWorkMinutes'] as int;
    final travelMinutes = overviewData['totalTravelMinutes'] as int;
    final totalMinutes = workMinutes + travelMinutes;

    if (totalMinutes == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context).overview_noDataAvailable,
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
                  color: AppColors.neutral50,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                  color: AppColors.neutral50,
                  fontWeight: FontWeight.bold,
                ),
          ),
          PieChartSectionData(
            value: travelMinutes.toDouble(),
            title:
                '${((travelMinutes / totalMinutes) * 100).toStringAsFixed(1)}%',
            color: colorScheme.tertiary,
            radius: 60,
            titleStyle: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.neutral50,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                  color: AppColors.neutral50,
                  fontWeight: FontWeight.bold,
                ),
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
        const SizedBox(width: AppSpacing.sm),
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
