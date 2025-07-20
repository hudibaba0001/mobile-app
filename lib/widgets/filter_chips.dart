import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../utils/constants.dart';

class FilterChips extends StatelessWidget {
  final Function(Map<String, dynamic> filters)? onFiltersChanged;
  
  const FilterChips({
    Key? key,
    this.onFiltersChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time period filters
            _buildFilterSection(
              context,
              'Time Period',
              _buildTimePeriodChips(context, filterProvider),
            ),
            
            // Duration filters
            _buildFilterSection(
              context,
              'Travel Duration',
              _buildDurationChips(context, filterProvider),
            ),
            
            // Location filters
            if (filterProvider.availableLocations.isNotEmpty)
              _buildFilterSection(
                context,
                'Locations',
                _buildLocationChips(context, filterProvider),
              ),
            
            // Active filters summary
            if (filterProvider.hasActiveFilters) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildActiveFiltersSection(context, filterProvider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content,
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }

  Widget _buildTimePeriodChips(BuildContext context, FilterProvider filterProvider) {
    final timePeriods = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'yesterday', 'label': 'Yesterday'},
      {'key': 'thisWeek', 'label': 'This Week'},
      {'key': 'lastWeek', 'label': 'Last Week'},
      {'key': 'thisMonth', 'label': 'This Month'},
      {'key': 'lastMonth', 'label': 'Last Month'},
      {'key': 'last30Days', 'label': 'Last 30 Days'},
      {'key': 'last90Days', 'label': 'Last 90 Days'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: timePeriods.map((period) {
          final isSelected = filterProvider.selectedTimePeriod == period['key'];
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.smallPadding),
            child: FilterChip(
              label: Text(period['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  filterProvider.setTimePeriod(period['key']!);
                } else {
                  filterProvider.clearTimePeriod();
                }
                _notifyFiltersChanged(filterProvider);
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationChips(BuildContext context, FilterProvider filterProvider) {
    final durations = [
      {'key': 'short', 'label': '< 30 min', 'min': 0, 'max': 30},
      {'key': 'medium', 'label': '30-60 min', 'min': 30, 'max': 60},
      {'key': 'long', 'label': '1-2 hours', 'min': 60, 'max': 120},
      {'key': 'veryLong', 'label': '> 2 hours', 'min': 120, 'max': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: durations.map((duration) {
          final isSelected = filterProvider.selectedDurationRanges.contains(duration['key']);
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.smallPadding),
            child: FilterChip(
              label: Text(duration['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  filterProvider.addDurationRange(
                    duration['key']! as String,
                    duration['min']! as int,
                    duration['max'] as int?,
                  );
                } else {
                  filterProvider.removeDurationRange(duration['key']! as String);
                }
                _notifyFiltersChanged(filterProvider);
              },
              selectedColor: Theme.of(context).colorScheme.secondaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationChips(BuildContext context, FilterProvider filterProvider) {
    final locations = filterProvider.availableLocations.take(10).toList(); // Limit to prevent overflow
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          ...locations.map((location) {
            final isSelected = filterProvider.selectedLocations.contains(location.id);
            return Padding(
              padding: const EdgeInsets.only(right: AppConstants.smallPadding),
              child: FilterChip(
                label: Text(
                  location.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    filterProvider.addLocation(location.id);
                  } else {
                    filterProvider.removeLocation(location.id);
                  }
                  _notifyFiltersChanged(filterProvider);
                },
                selectedColor: Theme.of(context).colorScheme.tertiaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            );
          }).toList(),
          if (locations.length >= 10)
            ActionChip(
              label: const Text('More...'),
              onPressed: () => _showLocationSelectionDialog(context, filterProvider),
              avatar: const Icon(Icons.add, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersSection(BuildContext context, FilterProvider filterProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  filterProvider.clearAllFilters();
                  _notifyFiltersChanged(filterProvider);
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
          Wrap(
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: [
              if (filterProvider.selectedTimePeriod != null)
                _buildActiveFilterChip(
                  context,
                  'Time: ${_getTimePeriodLabel(filterProvider.selectedTimePeriod!)}',
                  () {
                    filterProvider.clearTimePeriod();
                    _notifyFiltersChanged(filterProvider);
                  },
                ),
              ...filterProvider.selectedDurationRanges.map((range) =>
                _buildActiveFilterChip(
                  context,
                  'Duration: ${_getDurationLabel(range)}',
                  () {
                    filterProvider.removeDurationRange(range);
                    _notifyFiltersChanged(filterProvider);
                  },
                ),
              ),
              ...filterProvider.selectedLocations.map((locationId) {
                final location = filterProvider.availableLocations
                    .firstWhere((loc) => loc.id == locationId, orElse: () => null);
                return _buildActiveFilterChip(
                  context,
                  'Location: ${location?.name ?? 'Unknown'}',
                  () {
                    filterProvider.removeLocation(locationId);
                    _notifyFiltersChanged(filterProvider);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(BuildContext context, String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      deleteIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  String _getTimePeriodLabel(String key) {
    final labels = {
      'today': 'Today',
      'yesterday': 'Yesterday',
      'thisWeek': 'This Week',
      'lastWeek': 'Last Week',
      'thisMonth': 'This Month',
      'lastMonth': 'Last Month',
      'last30Days': 'Last 30 Days',
      'last90Days': 'Last 90 Days',
    };
    return labels[key] ?? key;
  }

  String _getDurationLabel(String key) {
    final labels = {
      'short': '< 30 min',
      'medium': '30-60 min',
      'long': '1-2 hours',
      'veryLong': '> 2 hours',
    };
    return labels[key] ?? key;
  }

  void _showLocationSelectionDialog(BuildContext context, FilterProvider filterProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Locations'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: filterProvider.availableLocations.length,
            itemBuilder: (context, index) {
              final location = filterProvider.availableLocations[index];
              final isSelected = filterProvider.selectedLocations.contains(location.id);
              
              return CheckboxListTile(
                title: Text(location.name),
                subtitle: Text(location.address),
                value: isSelected,
                onChanged: (selected) {
                  if (selected == true) {
                    filterProvider.addLocation(location.id);
                  } else {
                    filterProvider.removeLocation(location.id);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notifyFiltersChanged(filterProvider);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _notifyFiltersChanged(FilterProvider filterProvider) {
    if (onFiltersChanged != null) {
      onFiltersChanged!(filterProvider.activeFilters);
    }
  }
}