import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../providers/filter_provider.dart';
import '../providers/location_provider.dart';
import '../utils/constants.dart';
import 'date_range_picker_widget.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late FilterProvider _filterProvider;
  late LocationProvider _locationProvider;
  
  // Local state for dialog
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minDuration;
  int? _maxDuration;
  List<Location> _selectedLocations = [];
  
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterProvider = Provider.of<FilterProvider>(context, listen: false);
    _locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Initialize with current filter values
    _startDate = _filterProvider.startDate;
    _endDate = _filterProvider.endDate;
    _minDuration = _filterProvider.minDuration;
    _maxDuration = _filterProvider.maxDuration;
    _selectedLocations = List.from(_filterProvider.selectedLocations);
    
    if (_minDuration != null) {
      _minDurationController.text = _minDuration.toString();
    }
    if (_maxDuration != null) {
      _maxDurationController.text = _maxDuration.toString();
    }
  }

  @override
  void dispose() {
    _minDurationController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Travel Entries',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Section
                    _buildSectionHeader('Date Range'),
                    DateRangePickerWidget(
                      initialStartDate: _startDate,
                      initialEndDate: _endDate,
                      onDateRangeSelected: (start, end) {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // Duration Range Section
                    _buildSectionHeader('Travel Duration (minutes)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minDurationController,
                            decoration: const InputDecoration(
                              labelText: 'Min Duration',
                              hintText: 'e.g., 15',
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _minDuration = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.defaultPadding),
                        Expanded(
                          child: TextFormField(
                            controller: _maxDurationController,
                            decoration: const InputDecoration(
                              labelText: 'Max Duration',
                              hintText: 'e.g., 120',
                              prefixIcon: Icon(Icons.timer_off),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _maxDuration = int.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Quick duration presets
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildDurationPreset('Short (< 30min)', 0, 29),
                        _buildDurationPreset('Medium (30-60min)', 30, 60),
                        _buildDurationPreset('Long (> 60min)', 61, null),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // Locations Section
                    _buildSectionHeader('Locations'),
                    _buildLocationSelector(),
                    
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Selected locations
                    if (_selectedLocations.isNotEmpty) ...[
                      Text(
                        'Selected Locations:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedLocations.map((location) => 
                          Chip(
                            label: Text(location.name),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedLocations.remove(location);
                              });
                            },
                          ),
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDurationPreset(String label, int min, int? max) {
    final isSelected = _minDuration == min && _maxDuration == max;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _minDuration = min;
            _maxDuration = max;
            _minDurationController.text = min.toString();
            _maxDurationController.text = max?.toString() ?? '';
          });
        }
      },
    );
  }

  Widget _buildLocationSelector() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final locations = locationProvider.locations;
        
        if (locations.isEmpty) {
          return const Text('No saved locations available');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select locations to filter by:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = _selectedLocations.contains(location);
                  
                  return CheckboxListTile(
                    title: Text(location.name),
                    subtitle: Text(
                      location.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: location.isFavorite 
                        ? const Icon(Icons.star, color: Colors.amber)
                        : null,
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedLocations.add(location);
                        } else {
                          _selectedLocations.remove(location);
                        }
                      });
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

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _minDuration = null;
      _maxDuration = null;
      _selectedLocations.clear();
      _minDurationController.clear();
      _maxDurationController.clear();
    });
  }

  void _applyFilters() {
    // Apply filters to the provider
    if (_startDate != null && _endDate != null) {
      _filterProvider.setDateRange(_startDate!, _endDate!);
    } else {
      _filterProvider.clearDateRange();
    }
    
    if (_minDuration != null || _maxDuration != null) {
      _filterProvider.setDurationRange(_minDuration, _maxDuration);
    } else {
      _filterProvider.clearDurationRange();
    }
    
    _filterProvider.setLocationFilters(_selectedLocations);
    
    Navigator.of(context).pop(true); // Return true to indicate filters were applied
  }
}