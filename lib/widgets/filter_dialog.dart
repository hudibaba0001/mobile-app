import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../utils/constants.dart';
import 'date_range_picker_widget.dart';

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic> filters)? onFiltersApplied;

  const FilterDialog({
    Key? key,
    this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late FilterProvider _tempFilterProvider;

  @override
  void initState() {
    super.initState();
    // Create a temporary filter provider to hold changes until applied
    final currentProvider = context.read<FilterProvider>();
    _tempFilterProvider = FilterProvider()
      ..copyFrom(currentProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tempFilterProvider,
      child: Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Filter Options',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range Section
                      _buildSection(
                        'Date Range',
                        _buildDateRangeFilter(),
                      ),

                      // Duration Section
                      _buildSection(
                        'Travel Duration',
                        _buildDurationFilter(),
                      ),

                      // Location Section
                      _buildSection(
                        'Locations',
                        _buildLocationFilter(),
                      ),

                      // Sort Section
                      _buildSection(
                        'Sort By',
                        _buildSortFilter(),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              const Divider(),
              Row(
                children: [
                  Consumer<FilterProvider>(
                    builder: (context, filterProvider, _) {
                      return TextButton.icon(
                        onPressed: filterProvider.hasActiveFilters
                            ? () {
                                _tempFilterProvider.clearAllFilters();
                              }
                            : null,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear All'),
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        content,
        const SizedBox(height: AppConstants.largePadding),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        return DateRangePickerWidget(
          initialStartDate: filterProvider.startDate,
          initialEndDate: filterProvider.endDate,
          onDateRangeSelected: (start, end) {
            filterProvider.setDateRange(start, end);
          },
          onClear: () {
            filterProvider.clearDateRange();
          },
          showQuickSelects: true,
        );
      },
    );
  }

  Widget _buildDurationFilter() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        return Column(
          children: [
            // Predefined duration ranges
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: [
                _buildDurationChip('< 30 min', 'short', 0, 30, filterProvider),
                _buildDurationChip('30-60 min', 'medium', 30, 60, filterProvider),
                _buildDurationChip('1-2 hours', 'long', 60, 120, filterProvider),
                _buildDurationChip('> 2 hours', 'veryLong', 120, null, filterProvider),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Custom duration range
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Min Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null) {
                        filterProvider.setCustomDurationRange(
                          minMinutes: minutes,
                          maxMinutes: filterProvider.maxDurationMinutes,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Max Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null) {
                        filterProvider.setCustomDurationRange(
                          minMinutes: filterProvider.minDurationMinutes,
                          maxMinutes: minutes,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationChip(
    String label,
    String key,
    int min,
    int? max,
    FilterProvider filterProvider,
  ) {
    final isSelected = filterProvider.selectedDurationRanges.contains(key);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          filterProvider.addDurationRange(key, min, max);
        } else {
          filterProvider.removeDurationRange(key);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildLocationFilter() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        final locations = filterProvider.availableLocations;
        
        if (locations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                const Text('No saved locations available'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search locations
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                // Filter locations based on search
                // This would be implemented in the FilterProvider
              },
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Location list
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = filterProvider.selectedLocations.contains(location.id);
                  
                  return CheckboxListTile(
                    title: Text(location.name),
                    subtitle: Text(
                      location.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: location.isFavorite
                        ? Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 20,
                          )
                        : null,
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
          ],
        );
      },
    );
  }

  Widget _buildSortFilter() {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, _) {
        return Column(
          children: [
            // Sort by options
            RadioListTile<String>(
              title: const Text('Date (Newest First)'),
              value: 'date_desc',
              groupValue: filterProvider.sortBy,
              onChanged: (value) => filterProvider.setSortBy(value!),
            ),
            RadioListTile<String>(
              title: const Text('Date (Oldest First)'),
              value: 'date_asc',
              groupValue: filterProvider.sortBy,
              onChanged: (value) => filterProvider.setSortBy(value!),
            ),
            RadioListTile<String>(
              title: const Text('Duration (Longest First)'),
              value: 'duration_desc',
              groupValue: filterProvider.sortBy,
              onChanged: (value) => filterProvider.setSortBy(value!),
            ),
            RadioListTile<String>(
              title: const Text('Duration (Shortest First)'),
              value: 'duration_asc',
              groupValue: filterProvider.sortBy,
              onChanged: (value) => filterProvider.setSortBy(value!),
            ),
            RadioListTile<String>(
              title: const Text('Location (A-Z)'),
              value: 'location_asc',
              groupValue: filterProvider.sortBy,
              onChanged: (value) => filterProvider.setSortBy(value!),
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    // Apply the temporary filters to the main provider
    final mainProvider = context.read<FilterProvider>();
    mainProvider.copyFrom(_tempFilterProvider);
    
    // Notify callback
    if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!(mainProvider.activeFilters);
    }
    
    Navigator.of(context).pop();
  }
}

// Extension to add copyFrom method to FilterProvider
extension FilterProviderExtension on FilterProvider {
  void copyFrom(FilterProvider other) {
    // Copy all filter states from another provider
    if (other.startDate != null && other.endDate != null) {
      setDateRange(other.startDate!, other.endDate!);
    }
    
    for (final range in other.selectedDurationRanges) {
      // This would need to be implemented based on the actual FilterProvider structure
    }
    
    for (final locationId in other.selectedLocations) {
      addLocation(locationId);
    }
    
    if (other.selectedTimePeriod != null) {
      setTimePeriod(other.selectedTimePeriod!);
    }
    
    setSortBy(other.sortBy);
  }
}