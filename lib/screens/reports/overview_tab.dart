import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_analytics_viewmodel.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<CustomerAnalyticsViewModel>();

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
                title: 'Total Time',
                value: _formatMinutes(
                    viewModel.totalTravelMinutes + viewModel.totalWorkMinutes),
                subtitle: 'All activities',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme,
                icon: Icons.assignment_turned_in_rounded,
                iconColor: colorScheme.secondary,
                iconBgColor: colorScheme.secondary.withOpacity(0.1),
                title: 'Contract',
                value:
                    '${(viewModel.contractCompletion * 100).toStringAsFixed(1)}%',
                subtitle: 'Completion',
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
                value: _formatMinutes(viewModel.totalTravelMinutes),
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
                value: _formatMinutes(viewModel.totalWorkMinutes),
                subtitle: 'Total work',
              ),
            ),
          ],
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
                  child: _buildDistributionChart(theme, viewModel),
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
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
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

  Widget _buildDistributionChart(
      ThemeData theme, CustomerAnalyticsViewModel viewModel) {
    final total = viewModel.totalTravelMinutes + viewModel.totalWorkMinutes;
    if (total == 0) {
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
      painter: _DistributionPainter(
        travelRatio: viewModel.totalTravelMinutes / total,
        workRatio: viewModel.totalWorkMinutes / total,
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

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')}';
  }
}

class _DistributionPainter extends CustomPainter {
  final double travelRatio;
  final double workRatio;
  final Color travelColor;
  final Color workColor;

  _DistributionPainter({
    required this.travelRatio,
    required this.workRatio,
    required this.travelColor,
    required this.workColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 3 : size.height / 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw travel arc
    final travelPaint = Paint()
      ..color = travelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -1.5708, // Start at top (-90 degrees)
      2 * 3.14159 * travelRatio, // Travel portion
      false,
      travelPaint,
    );

    // Draw work arc
    final workPaint = Paint()
      ..color = workColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -1.5708 + (2 * 3.14159 * travelRatio), // Start after travel
      2 * 3.14159 * workRatio, // Work portion
      false,
      workPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DistributionPainter oldDelegate) {
    return travelRatio != oldDelegate.travelRatio ||
        workRatio != oldDelegate.workRatio ||
        travelColor != oldDelegate.travelColor ||
        workColor != oldDelegate.workColor;
  }
}
