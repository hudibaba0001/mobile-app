import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../utils/constants.dart';

class FilterChips extends StatelessWidget {
  final Function()? onFiltersChanged;
  
  const FilterChips({
    super.key,
    this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filterProvider.hasActiveFilters) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Filters',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      filterProvider.clearAllFilters();
                      if (onFiltersChanged != null) {
                        onFiltersChanged!();
                      }
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
            ],
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: [
                // Date range filter chip
                if (filterProvider.hasDateRange)
                  FilterChip(
                    label: Text(
                      'Date: ${filterProvider.getDateRangeText()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        filterProvider.clearDateRange();
                        if (onFiltersChanged != null) {
                          onFiltersChanged!();
                        }
                      }
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      filterProvider.clearDateRange();
                      if (onFiltersChanged != null) {
                        onFiltersChanged!();
                      }
                    },
                  ),
                
                // Location filter chips
                ...filterProvider.selectedLocations.map((location) => 
                  FilterChip(
                    label: Text(
                      location.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        filterProvider.removeLocationFilter(location.id);
                        if (onFiltersChanged != null) {
                          onFiltersChanged!();
                        }
                      }
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      filterProvider.removeLocationFilter(location.id);
                      if (onFiltersChanged != null) {
                        onFiltersChanged!();
                      }
                    },
                  ),
                ),
                
                // Duration range filter chip
                if (filterProvider.hasDurationRange)
                  FilterChip(
                    label: Text(
                      'Duration: ${filterProvider.getDurationRangeText()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        filterProvider.clearDurationRange();
                        if (onFiltersChanged != null) {
                          onFiltersChanged!();
                        }
                      }
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      filterProvider.clearDurationRange();
                      if (onFiltersChanged != null) {
                        onFiltersChanged!();
                      }
                    },
                  ),
                
                // Quick filter chips for common scenarios
                if (!filterProvider.hasActiveFilters) ...[
                  _buildQuickFilterChip(
                    context,
                    'Today',
                    Icons.today,
                    () => _applyQuickDateFilter(context, QuickDateFilter.today),
                  ),
                  _buildQuickFilterChip(
                    context,
                    'This Week',
                    Icons.date_range,
                    () => _applyQuickDateFilter(context, QuickDateFilter.thisWeek),
                  ),
                  _buildQuickFilterChip(
                    context,
                    'This Month',
                    Icons.calendar_month,
                    () => _applyQuickDateFilter(context, QuickDateFilter.thisMonth),
                  ),
                  _buildQuickFilterChip(
                    context,
                    'Short Trips',
                    Icons.timer,
                    () => _applyQuickDurationFilter(context, QuickDurationFilter.short),
                  ),
                  _buildQuickFilterChip(
                    context,
                    'Long Trips',
                    Icons.schedule,
                    () => _applyQuickDurationFilter(context, QuickDurationFilter.long),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  void _applyQuickDateFilter(BuildContext context, QuickDateFilter filter) {
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filter) {
      case QuickDateFilter.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case QuickDateFilter.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case QuickDateFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    filterProvider.setDateRange(start, end);
    if (onFiltersChanged != null) {
      onFiltersChanged!();
    }
  }

  void _applyQuickDurationFilter(BuildContext context, QuickDurationFilter filter) {
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    
    switch (filter) {
      case QuickDurationFilter.short:
        filterProvider.setDurationRange(0, 30); // 0-30 minutes
        break;
      case QuickDurationFilter.long:
        filterProvider.setDurationRange(60, null); // 60+ minutes
        break;
    }

    if (onFiltersChanged != null) {
      onFiltersChanged!();
    }
  }
}

enum QuickDateFilter {
  today,
  thisWeek,
  thisMonth,
}

enum QuickDurationFilter {
  short,
  long,
}