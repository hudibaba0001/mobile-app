import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../l10n/generated/app_localizations.dart';

/// A Material 3 styled pie chart widget for displaying work/travel statistics
/// with interactive legend and smooth animations
class PieChartStats extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showLegend;
  final bool showPercentages;
  final double? height;
  
  const PieChartStats({
    super.key,
    this.startDate,
    this.endDate,
    this.showLegend = true,
    this.showPercentages = true,
    this.height,
  });

  @override
  State<PieChartStats> createState() => _PieChartStatsState();
}

class _PieChartStatsState extends State<PieChartStats>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController;
  late Animation<double> _animation;
  late Animation<double> _hoverAnimation;
  
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        final stats = _calculateStats(travelProvider);
        
        return Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 20),
                SizedBox(
                  height: widget.height ?? 200,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return _buildPieChart(theme, stats);
                    },
                  ),
                ),
                if (widget.showLegend) ...[
                  const SizedBox(height: 20),
                  _buildLegend(theme, stats),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.pie_chart,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).chart_timeDistribution,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getDateRangeText(context),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(ThemeData theme, ChartStats stats) {
    final colorScheme = theme.colorScheme;
    
    if (stats.totalMinutes == 0) {
      return _buildEmptyState(theme);
    }
    
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                _hoverController.reverse();
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              _hoverController.forward();
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: _buildPieSections(colorScheme, stats),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    ColorScheme colorScheme,
    ChartStats stats,
  ) {
    final workPercentage = stats.totalMinutes > 0 
        ? (stats.workMinutes / stats.totalMinutes * 100)
        : 0.0;
    final travelPercentage = stats.totalMinutes > 0 
        ? (stats.travelMinutes / stats.totalMinutes * 100)
        : 0.0;
    
    return [
      // Work section
      PieChartSectionData(
        color: colorScheme.secondary,
        value: stats.workMinutes.toDouble() * _animation.value,
        title: widget.showPercentages ? '${workPercentage.toInt()}%' : '',
        radius: touchedIndex == 0 ? 80 * _hoverAnimation.value : 70,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 0 ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSecondary,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
      // Travel section
      PieChartSectionData(
        color: colorScheme.primary,
        value: stats.travelMinutes.toDouble() * _animation.value,
        title: widget.showPercentages ? '${travelPercentage.toInt()}%' : '',
        radius: touchedIndex == 1 ? 80 * _hoverAnimation.value : 70,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 1 ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),
        titlePositionPercentageOffset: 0.6,
      ),
    ];
  }

  Widget _buildLegend(ThemeData theme, ChartStats stats) {
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        _buildLegendItem(
          theme,
          color: colorScheme.secondary,
          label: AppLocalizations.of(context).chart_workTime,
          value: _formatDuration(stats.workMinutes),
          percentage: stats.totalMinutes > 0 
              ? (stats.workMinutes / stats.totalMinutes * 100).toInt()
              : 0,
          isSelected: touchedIndex == 0,
        ),
        const SizedBox(height: 12),
        _buildLegendItem(
          theme,
          color: colorScheme.primary,
          label: AppLocalizations.of(context).chart_travelTime,
          value: _formatDuration(stats.travelMinutes),
          percentage: stats.totalMinutes > 0 
              ? (stats.travelMinutes / stats.totalMinutes * 100).toInt()
              : 0,
          isSelected: touchedIndex == 1,
        ),
        const SizedBox(height: 16),
        Divider(color: colorScheme.outline.withOpacity(0.2)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).chart_totalTime,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDuration(stats.totalMinutes),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
    required String value,
    required int percentage,
    required bool isSelected,
  }) {
    final colorScheme = theme.colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected 
            ? color.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
            ? Border.all(color: color.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (widget.showPercentages)
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).chart_noDataAvailable,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).chart_startTracking,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ChartStats _calculateStats(TravelProvider provider) {
    // In a real implementation, this would fetch data from the provider
    // based on the date range
    return ChartStats(
      workMinutes: 480, // 8 hours
      travelMinutes: 120, // 2 hours
    );
  }

  String _getDateRangeText(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (widget.startDate == null && widget.endDate == null) {
      return t.chart_allTime;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = widget.startDate ?? today;
    final endDate = widget.endDate ?? today;
    
    if (startDate == endDate && startDate == today) {
      return t.chart_today;
    } else if (startDate == endDate) {
      return _formatDate(startDate);
    } else {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}

/// Data class to hold chart statistics
class ChartStats {
  final int workMinutes;
  final int travelMinutes;

  ChartStats({
    required this.workMinutes,
    required this.travelMinutes,
  });

  int get totalMinutes => workMinutes + travelMinutes;
}
