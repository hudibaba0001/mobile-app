import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';
import '../../l10n/generated/app_localizations.dart';

class LocationsTab extends StatelessWidget {
  const LocationsTab({super.key});

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
              AppLocalizations.of(context)!.locations_errorLoading,
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

    final locationsData = viewModel.locationsData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Location Distribution Chart
        Text(
          AppLocalizations.of(context)!.locations_distribution,
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
            child: _buildLocationDistributionChart(context, theme, locationsData),
          ),
        ),
        const SizedBox(height: 24),

        // Location List
        Text(
          AppLocalizations.of(context)!.locations_details,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (locationsData.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.locations_noData,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.locations_noDataDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...locationsData
              .map((location) => _buildLocationCard(context, theme, location)),
      ],
    );
  }

  Widget _buildLocationDistributionChart(
    BuildContext context,
    ThemeData theme,
    List<Map<String, dynamic>> locations,
  ) {
    if (locations.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.locations_noDataAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: locations.map((location) {
          return PieChartSectionData(
            value: location['totalHours'] as double,
            title: '${location['percentage'].toStringAsFixed(1)}%',
            color: Color(location['color'] as int),
            radius: 60,
            titleStyle: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, ThemeData theme, Map<String, dynamic> location) {
    final colorScheme = theme.colorScheme;
    final name = location['name'] as String;
    final totalHours = location['totalHours'] as double;
    final percentage = location['percentage'] as double;
    final workMinutes = location['workMinutes'] as int;
    final travelMinutes = location['travelMinutes'] as int;
    final color = Color(location['color'] as int);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLocationStat(
                  context,
                  theme,
                  icon: Icons.timer_rounded,
                  label: AppLocalizations.of(context)!.locations_totalHours,
                  value: '${totalHours.toStringAsFixed(1)}h',
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildLocationStat(
                  context,
                  theme,
                  icon: Icons.assignment_rounded,
                  label: AppLocalizations.of(context)!.locations_entries,
                  value: '${workMinutes + travelMinutes}',
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLocationStat(
                  context,
                  theme,
                  icon: Icons.work_rounded,
                  label: AppLocalizations.of(context)!.locations_workTime,
                  value: _formatMinutes(workMinutes),
                  color: colorScheme.error,
                ),
              ),
              Expanded(
                child: _buildLocationStat(
                  context,
                  theme,
                  icon: Icons.directions_car_rounded,
                  label: AppLocalizations.of(context)!.locations_travelTime,
                  value: _formatMinutes(travelMinutes),
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStat(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
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
