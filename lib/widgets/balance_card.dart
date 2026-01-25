import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import '../l10n/generated/app_localizations.dart';

/// A Material 3 styled card widget that displays work/travel time balance
/// with visual indicators and interactive elements
class BalanceCard extends StatefulWidget {
  final DateTime? selectedDate;
  final VoidCallback? onTap;
  final bool showDetails;
  
  const BalanceCard({
    super.key,
    this.selectedDate,
    this.onTap,
    this.showDetails = true,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        final selectedDate = widget.selectedDate ?? DateTime.now();
        final dayStats = _calculateDayStats(travelProvider, selectedDate);
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: 2,
                shadowColor: colorScheme.shadow.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.primaryContainer.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme, dayStats),
                        const SizedBox(height: 16),
                        _buildProgressBar(theme, dayStats),
                        if (widget.showDetails) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(theme, dayStats),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, DayStats stats) {
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.balance,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).balance_todaysBalance,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(stats.totalMinutes),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildBalanceIndicator(theme, stats),
      ],
    );
  }

  Widget _buildBalanceIndicator(ThemeData theme, DayStats stats) {
    final colorScheme = theme.colorScheme;
    final isBalanced = (stats.workMinutes - stats.travelMinutes).abs() <= 30;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBalanced 
            ? colorScheme.tertiary.withOpacity(0.1)
            : colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isBalanced ? colorScheme.tertiary : colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            isBalanced 
              ? AppLocalizations.of(context).balance_balanced
              : AppLocalizations.of(context).balance_unbalanced,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isBalanced ? colorScheme.tertiary : colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, DayStats stats) {
    final colorScheme = theme.colorScheme;
    final totalMinutes = stats.totalMinutes;
    final workRatio = totalMinutes > 0 ? stats.workMinutes / totalMinutes : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).balance_workVsTravel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
            Text(
              '${(workRatio * 100).toInt()}% / ${((1 - workRatio) * 100).toInt()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.outline.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: (workRatio * _progressAnimation.value * 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - workRatio) * _progressAnimation.value * 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (_progressAnimation.value < 1.0)
                    Expanded(
                      flex: ((1 - _progressAnimation.value) * 100).toInt(),
                      child: Container(),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, DayStats stats) {
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.work_outline,
            label: AppLocalizations.of(context).balance_work,
            value: _formatDuration(stats.workMinutes),
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.directions_car,
            label: AppLocalizations.of(context).balance_travel,
            value: _formatDuration(stats.travelMinutes),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            theme,
            icon: Icons.timeline,
            label: AppLocalizations.of(context).balance_entries,
            value: '${stats.entryCount}',
            color: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  DayStats _calculateDayStats(TravelProvider provider, DateTime date) {
    // In a real implementation, this would fetch data from the provider
    // For now, we'll return mock data
    return DayStats(
      workMinutes: 480, // 8 hours
      travelMinutes: 60, // 1 hour
      entryCount: 4,
    );
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

/// Data class to hold daily statistics
class DayStats {
  final int workMinutes;
  final int travelMinutes;
  final int entryCount;

  DayStats({
    required this.workMinutes,
    required this.travelMinutes,
    required this.entryCount,
  });

  int get totalMinutes => workMinutes + travelMinutes;
}
