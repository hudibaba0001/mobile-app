import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';

class LocationsTab extends StatelessWidget {
  const LocationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<CustomerAnalyticsViewModel>();

    final locations = viewModel.locationAnalytics.entries.toList()
      ..sort((a, b) => b.value.totalMinutes.compareTo(a.value.totalMinutes));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Location Distribution Chart
        Text(
          'Location Distribution',
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
            child: _buildLocationDistributionChart(theme, locations),
          ),
        ),
        const SizedBox(height: 24),

        // Location List
        Text(
          'Location Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        if (locations.isEmpty)
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
                  'No location data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No travel entries found for the selected period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...locations.map((entry) => _buildLocationCard(
                theme,
                name: entry.key,
                analytics: entry.value,
                totalTime: locations.fold<int>(
                  0,
                  (sum, e) => sum + e.value.totalMinutes,
                ),
              )),
      ],
    );
  }

  Widget _buildLocationDistributionChart(
    ThemeData theme,
    List<MapEntry<String, LocationAnalytics>> locations,
  ) {
    if (locations.isEmpty) {
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
      painter: _LocationDistributionPainter(
        locations: locations,
        baseColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildLocationCard(
    ThemeData theme, {
    required String name,
    required LocationAnalytics analytics,
    required int totalTime,
  }) {
    final colorScheme = theme.colorScheme;
    final percentage = totalTime > 0
        ? (analytics.totalMinutes / totalTime * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${analytics.totalVisits} visits',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalTime > 0 ? analytics.totalMinutes / totalTime : 0,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  color: colorScheme.primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatMinutes(analytics.totalMinutes),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')}';
  }
}

class _LocationDistributionPainter extends CustomPainter {
  final List<MapEntry<String, LocationAnalytics>> locations;
  final Color baseColor;

  _LocationDistributionPainter({
    required this.locations,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.isEmpty) return;

    final totalMinutes = locations.fold<int>(
      0,
      (sum, entry) => sum + entry.value.totalMinutes,
    );
    if (totalMinutes == 0) return;

    var startAngle = -1.5708; // Start at top (-90 degrees)
    final radius = size.width < size.height ? size.width / 3 : size.height / 3;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < locations.length; i++) {
      final entry = locations[i];
      final sweepAngle =
          2 * 3.14159 * (entry.value.totalMinutes / totalMinutes);

      final paint = Paint()
        ..color = baseColor.withOpacity(1 - (i * 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _LocationDistributionPainter oldDelegate) {
    return locations != oldDelegate.locations ||
        baseColor != oldDelegate.baseColor;
  }
}
