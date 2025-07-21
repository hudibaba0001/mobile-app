import 'package:flutter/foundation.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../utils/data_validator.dart';
import '../utils/error_handler.dart';

class FilterProvider extends ChangeNotifier {
  // Date filters
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Location filters
  List<String> _selectedLocationIds = [];
  
  // Duration filters
  int? _minMinutes;
  int? _maxMinutes;
  
  // Other filters
  bool _showFavoritesOnly = false;
  bool _showRecentOnly = false;
  SortOption _sortOption = SortOption.dateDesc;
  
  // Filter state
  bool _isActive = false;
  Map<String, FilterPreset> _filterPresets = {};
  String? _activePresetName;
  AppError? _lastError;
  
  // Advanced filtering options
  FilterCombination _filterCombination = FilterCombination.and;
  List<FilterRule> _customRules = [];
  bool _enableSmartFiltering = true;
  
  // Filter statistics
  Map<String, int> _filterUsageStats = {};
  DateTime? _lastFilterApplied;

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<String> get selectedLocationIds => List.unmodifiable(_selectedLocationIds);
  int? get minMinutes => _minMinutes;
  int? get maxMinutes => _maxMinutes;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get showRecentOnly => _showRecentOnly;
  SortOption get sortOption => _sortOption;
  bool get isActive => _isActive;
  Map<String, FilterPreset> get filterPresets => Map.unmodifiable(_filterPresets);
  String? get activePresetName => _activePresetName;
  AppError? get lastError => _lastError;
  FilterCombination get filterCombination => _filterCombination;
  List<FilterRule> get customRules => List.unmodifiable(_customRules);
  bool get enableSmartFiltering => _enableSmartFiltering;
  Map<String, int> get filterUsageStats => Map.unmodifiable(_filterUsageStats);
  DateTime? get lastFilterApplied => _lastFilterApplied;
  
  bool get hasDateFilter => _startDate != null || _endDate != null;
  bool get hasLocationFilter => _selectedLocationIds.isNotEmpty;
  bool get hasDurationFilter => _minMinutes != null || _maxMinutes != null;
  bool get hasAnyFilter => hasDateFilter || hasLocationFilter || hasDurationFilter || 
                          _showFavoritesOnly || _showRecentOnly;
  
  // Additional getters for UI components
  bool get hasActiveFilters => hasAnyFilter;
  bool get hasDateRange => hasDateFilter;
  bool get hasDurationRange => hasDurationFilter;
  int? get minDuration => _minMinutes;
  int? get maxDuration => _maxMinutes;
  List<Location> get selectedLocations => _selectedLocationsList;
  
  // Internal list to store actual Location objects
  List<Location> _selectedLocationsList = [];

  // Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    // Validate date range
    if (start != null && end != null) {
      final validationErrors = DataValidator.validateDateRange(start, end);
      if (validationErrors.isNotEmpty) {
        _handleError(validationErrors.first);
        return;
      }
    }

    _startDate = start;
    _endDate = end;
    _updateActiveState();
    _clearError();
    notifyListeners();
  }

  // Set start date
  void setStartDate(DateTime? date) {
    setDateRange(date, _endDate);
  }

  // Set end date
  void setEndDate(DateTime? date) {
    setDateRange(_startDate, date);
  }

  // Add location to filter
  void addLocationFilter(String locationId) {
    if (!_selectedLocationIds.contains(locationId)) {
      _selectedLocationIds.add(locationId);
      _updateActiveState();
      notifyListeners();
    }
  }

  // Remove location from filter
  void removeLocationFilter(String locationId) {
    if (_selectedLocationIds.remove(locationId)) {
      _updateActiveState();
      notifyListeners();
    }
  }

  // Toggle location filter
  void toggleLocationFilter(String locationId) {
    if (_selectedLocationIds.contains(locationId)) {
      removeLocationFilter(locationId);
    } else {
      addLocationFilter(locationId);
    }
  }

  // Set location filters by IDs
  void setLocationFilterIds(List<String> locationIds) {
    _selectedLocationIds = List.from(locationIds);
    _updateActiveState();
    notifyListeners();
  }

  // Set location filters with Location objects
  void setLocationFilters(List<Location> locations) {
    _selectedLocationsList = List.from(locations);
    _selectedLocationIds = locations.map((loc) => loc.id).toList();
    _updateActiveState();
    notifyListeners();
  }

  // Set duration range filter
  void setDurationRange(int? minMinutes, int? maxMinutes) {
    // Validate duration range
    if (minMinutes != null && minMinutes < 0) {
      _handleError(ErrorHandler.handleValidationError('Minimum duration cannot be negative'));
      return;
    }
    
    if (maxMinutes != null && maxMinutes < 0) {
      _handleError(ErrorHandler.handleValidationError('Maximum duration cannot be negative'));
      return;
    }
    
    if (minMinutes != null && maxMinutes != null && minMinutes > maxMinutes) {
      _handleError(ErrorHandler.handleValidationError('Minimum duration cannot be greater than maximum'));
      return;
    }

    _minMinutes = minMinutes;
    _maxMinutes = maxMinutes;
    _updateActiveState();
    _clearError();
    notifyListeners();
  }

  // Set minimum duration
  void setMinDuration(int? minutes) {
    setDurationRange(minutes, _maxMinutes);
  }

  // Set maximum duration
  void setMaxDuration(int? minutes) {
    setDurationRange(_minMinutes, minutes);
  }

  // Toggle favorites only filter
  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _updateActiveState();
    notifyListeners();
  }

  // Toggle recent only filter
  void toggleRecentOnly() {
    _showRecentOnly = !_showRecentOnly;
    _updateActiveState();
    notifyListeners();
  }

  // Set sort option
  void setSortOption(SortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  // Apply filters to travel entries
  List<TravelTimeEntry> applyToTravelEntries(List<TravelTimeEntry> entries) {
    List<TravelTimeEntry> filtered = List.from(entries);

    // Date filter
    if (hasDateFilter) {
      filtered = filtered.where((entry) {
        if (_startDate != null && entry.date.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && entry.date.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Location filter
    if (hasLocationFilter) {
      filtered = filtered.where((entry) {
        return _selectedLocationIds.contains(entry.departureLocationId) ||
               _selectedLocationIds.contains(entry.arrivalLocationId);
      }).toList();
    }

    // Duration filter
    if (hasDurationFilter) {
      filtered = filtered.where((entry) {
        if (_minMinutes != null && entry.minutes < _minMinutes!) {
          return false;
        }
        if (_maxMinutes != null && entry.minutes > _maxMinutes!) {
          return false;
        }
        return true;
      }).toList();
    }

    // Recent only filter
    if (_showRecentOnly) {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      filtered = filtered.where((entry) => entry.date.isAfter(cutoffDate)).toList();
    }

    // Apply sorting
    _applySorting(filtered);

    return filtered;
  }

  // Apply filters to locations
  List<Location> applyToLocations(List<Location> locations) {
    List<Location> filtered = List.from(locations);

    // Favorites only filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((location) => location.isFavorite).toList();
    }

    // Recent only filter
    if (_showRecentOnly) {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      filtered = filtered.where((location) => location.createdAt.isAfter(cutoffDate)).toList();
    }

    // Apply sorting
    _applyLocationSorting(filtered);

    return filtered;
  }

  // Apply sorting to travel entries
  void _applySorting(List<TravelTimeEntry> entries) {
    switch (_sortOption) {
      case SortOption.dateAsc:
        entries.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.dateDesc:
        entries.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.durationAsc:
        entries.sort((a, b) => a.minutes.compareTo(b.minutes));
        break;
      case SortOption.durationDesc:
        entries.sort((a, b) => b.minutes.compareTo(a.minutes));
        break;
      case SortOption.departureAZ:
        entries.sort((a, b) => a.departure.compareTo(b.departure));
        break;
      case SortOption.arrivalAZ:
        entries.sort((a, b) => a.arrival.compareTo(b.arrival));
        break;
    }
  }

  // Apply sorting to locations
  void _applyLocationSorting(List<Location> locations) {
    switch (_sortOption) {
      case SortOption.nameAZ:
        locations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.usageDesc:
        locations.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case SortOption.dateDesc:
        locations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Default to usage-based sorting for locations
        locations.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
    }
  }

  // Clear specific filters
  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    _updateActiveState();
    notifyListeners();
  }

  void clearDurationRange() {
    _minMinutes = null;
    _maxMinutes = null;
    _updateActiveState();
    notifyListeners();
  }

  void clearLocationFilters() {
    _selectedLocationIds.clear();
    _selectedLocationsList.clear();
    _updateActiveState();
    notifyListeners();
  }

  // Clear all filters
  void clearAllFilters() {
    _startDate = null;
    _endDate = null;
    _selectedLocationIds.clear();
    _selectedLocationsList.clear();
    _minMinutes = null;
    _maxMinutes = null;
    _showFavoritesOnly = false;
    _showRecentOnly = false;
    _activePresetName = null;
    _updateActiveState();
    _clearError();
    notifyListeners();
  }

  // Helper methods for UI text display
  String getDateRangeText() {
    if (_startDate == null && _endDate == null) return '';
    
    final dateFormat = 'MMM dd, yyyy';
    if (_startDate != null && _endDate != null) {
      // Check if same day
      if (_startDate!.year == _endDate!.year && 
          _startDate!.month == _endDate!.month && 
          _startDate!.day == _endDate!.day) {
        return _formatDate(_startDate!);
      }
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${_formatDate(_startDate!)}';
    } else {
      return 'Until ${_formatDate(_endDate!)}';
    }
  }

  String getDurationRangeText() {
    if (_minMinutes == null && _maxMinutes == null) return '';
    
    if (_minMinutes != null && _maxMinutes != null) {
      return '${_minMinutes}min - ${_maxMinutes}min';
    } else if (_minMinutes != null) {
      return '${_minMinutes}min+';
    } else {
      return 'Up to ${_maxMinutes}min';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Save current filters as preset
  void saveAsPreset(String name, {String? description}) {
    if (name.trim().isEmpty) {
      _handleError(ErrorHandler.handleValidationError('Preset name cannot be empty'));
      return;
    }

    final preset = FilterPreset(
      name: name.trim(),
      description: description?.trim(),
      startDate: _startDate,
      endDate: _endDate,
      selectedLocationIds: List.from(_selectedLocationIds),
      minMinutes: _minMinutes,
      maxMinutes: _maxMinutes,
      showFavoritesOnly: _showFavoritesOnly,
      showRecentOnly: _showRecentOnly,
      sortOption: _sortOption,
      filterCombination: _filterCombination,
      customRules: List.from(_customRules),
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );
    
    _filterPresets[name.trim()] = preset;
    _activePresetName = name.trim();
    _updateFilterUsageStats('preset_saved');
    _clearError();
    notifyListeners();
  }

  // Load preset
  void loadPreset(String name) {
    final preset = _filterPresets[name];
    if (preset == null) {
      _handleError(ErrorHandler.handleValidationError('Preset not found'));
      return;
    }

    _startDate = preset.startDate;
    _endDate = preset.endDate;
    _selectedLocationIds = List.from(preset.selectedLocationIds);
    _minMinutes = preset.minMinutes;
    _maxMinutes = preset.maxMinutes;
    _showFavoritesOnly = preset.showFavoritesOnly;
    _showRecentOnly = preset.showRecentOnly;
    _sortOption = preset.sortOption;
    _filterCombination = preset.filterCombination;
    _customRules = List.from(preset.customRules);
    _activePresetName = name;
    
    // Update last used timestamp
    _filterPresets[name] = preset.copyWith(lastUsed: DateTime.now());
    
    _updateActiveState();
    _clearError();
    notifyListeners();
  }

  // Delete preset
  void deletePreset(String name) {
    if (_filterPresets.remove(name) != null) {
      if (_activePresetName == name) {
        _activePresetName = null;
      }
      notifyListeners();
    }
  }

  // Quick filter presets
  void applyTodayFilter() {
    final today = DateTime.now();
    setDateRange(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
  }

  void applyThisWeekFilter() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    setDateRange(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  void applyThisMonthFilter() {
    final now = DateTime.now();
    setDateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  void applyLast30DaysFilter() {
    final now = DateTime.now();
    setDateRange(
      now.subtract(const Duration(days: 30)),
      now,
    );
  }

  // Update active state
  void _updateActiveState() {
    _isActive = hasAnyFilter;
  }

  // Helper methods
  void _handleError(dynamic error) {
    if (error is AppError) {
      _lastError = error;
    } else {
      _lastError = ErrorHandler.handleUnknownError(error);
    }
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Advanced filtering methods
  void setFilterCombination(FilterCombination combination) {
    if (_filterCombination != combination) {
      _filterCombination = combination;
      _updateFilterUsageStats('combination_changed');
      notifyListeners();
    }
  }

  void addCustomRule(FilterRule rule) {
    _customRules.add(rule);
    _updateActiveState();
    _updateFilterUsageStats('custom_rule_added');
    notifyListeners();
  }

  void removeCustomRule(FilterRule rule) {
    if (_customRules.remove(rule)) {
      _updateActiveState();
      notifyListeners();
    }
  }

  void clearCustomRules() {
    if (_customRules.isNotEmpty) {
      _customRules.clear();
      _updateActiveState();
      notifyListeners();
    }
  }

  void setSmartFiltering(bool enabled) {
    if (_enableSmartFiltering != enabled) {
      _enableSmartFiltering = enabled;
      _updateFilterUsageStats('smart_filtering_toggled');
      notifyListeners();
    }
  }

  // Filter statistics and analytics
  void _updateFilterUsageStats(String action) {
    _filterUsageStats[action] = (_filterUsageStats[action] ?? 0) + 1;
    _lastFilterApplied = DateTime.now();
  }

  Map<String, dynamic> getFilterStatistics() {
    return {
      'totalFiltersApplied': _filterUsageStats.values.fold(0, (sum, count) => sum + count),
      'mostUsedFilter': _getMostUsedFilter(),
      'presetsCreated': _filterPresets.length,
      'lastFilterApplied': _lastFilterApplied?.toIso8601String(),
      'usageBreakdown': Map.from(_filterUsageStats),
    };
  }

  String? _getMostUsedFilter() {
    if (_filterUsageStats.isEmpty) return null;
    
    final sorted = _filterUsageStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  // Filter presets management
  List<FilterPreset> getPresetsSorted({PresetSortBy sortBy = PresetSortBy.lastUsed}) {
    final presets = _filterPresets.values.toList();
    
    switch (sortBy) {
      case PresetSortBy.name:
        presets.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PresetSortBy.created:
        presets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PresetSortBy.lastUsed:
        presets.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        break;
    }
    
    return presets;
  }

  void updatePreset(String name, {String? newName, String? description}) {
    final preset = _filterPresets[name];
    if (preset == null) return;
    
    final updatedPreset = preset.copyWith(
      name: newName ?? preset.name,
      description: description,
      lastUsed: DateTime.now(),
    );
    
    if (newName != null && newName != name) {
      _filterPresets.remove(name);
      _filterPresets[newName] = updatedPreset;
      if (_activePresetName == name) {
        _activePresetName = newName;
      }
    } else {
      _filterPresets[name] = updatedPreset;
    }
    
    notifyListeners();
  }

  // Smart filtering suggestions
  List<FilterSuggestion> getSmartFilterSuggestions(List<TravelTimeEntry> entries) {
    if (!_enableSmartFiltering || entries.isEmpty) return [];
    
    final suggestions = <FilterSuggestion>[];
    
    // Suggest frequent routes
    final routeFrequency = <String, int>{};
    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    }
    
    final frequentRoutes = routeFrequency.entries
        .where((e) => e.value >= 3)
        .take(3)
        .toList();
    
    for (final route in frequentRoutes) {
      suggestions.add(FilterSuggestion(
        title: 'Filter by ${route.key}',
        description: 'Show only trips for this route (${route.value} trips)',
        type: FilterSuggestionType.route,
        action: () {
          // This would need to be implemented based on route filtering
        },
      ));
    }
    
    // Suggest recent period if there are recent entries
    final recentEntries = entries.where((e) => 
        DateTime.now().difference(e.date).inDays <= 7).length;
    
    if (recentEntries > 0) {
      suggestions.add(FilterSuggestion(
        title: 'This Week',
        description: 'Show trips from the last 7 days ($recentEntries trips)',
        type: FilterSuggestionType.dateRange,
        action: () => applyThisWeekFilter(),
      ));
    }
    
    return suggestions;
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum SortOption {
  dateAsc,
  dateDesc,
  durationAsc,
  durationDesc,
  departureAZ,
  arrivalAZ,
  nameAZ,
  usageDesc,
}

enum FilterCombination {
  and,
  or,
}

enum PresetSortBy {
  name,
  created,
  lastUsed,
}

enum FilterSuggestionType {
  route,
  dateRange,
  duration,
  location,
}

class FilterPreset {
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> selectedLocationIds;
  final int? minMinutes;
  final int? maxMinutes;
  final bool showFavoritesOnly;
  final bool showRecentOnly;
  final SortOption sortOption;
  final FilterCombination filterCombination;
  final List<FilterRule> customRules;
  final DateTime createdAt;
  final DateTime lastUsed;

  const FilterPreset({
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    required this.selectedLocationIds,
    this.minMinutes,
    this.maxMinutes,
    required this.showFavoritesOnly,
    required this.showRecentOnly,
    required this.sortOption,
    required this.filterCombination,
    required this.customRules,
    required this.createdAt,
    required this.lastUsed,
  });

  FilterPreset copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedLocationIds,
    int? minMinutes,
    int? maxMinutes,
    bool? showFavoritesOnly,
    bool? showRecentOnly,
    SortOption? sortOption,
    FilterCombination? filterCombination,
    List<FilterRule>? customRules,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return FilterPreset(
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedLocationIds: selectedLocationIds ?? this.selectedLocationIds,
      minMinutes: minMinutes ?? this.minMinutes,
      maxMinutes: maxMinutes ?? this.maxMinutes,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      showRecentOnly: showRecentOnly ?? this.showRecentOnly,
      sortOption: sortOption ?? this.sortOption,
      filterCombination: filterCombination ?? this.filterCombination,
      customRules: customRules ?? this.customRules,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'selectedLocationIds': selectedLocationIds,
      'minMinutes': minMinutes,
      'maxMinutes': maxMinutes,
      'showFavoritesOnly': showFavoritesOnly,
      'showRecentOnly': showRecentOnly,
      'sortOption': sortOption.index,
      'filterCombination': filterCombination.index,
      'customRules': customRules.map((rule) => rule.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    return FilterPreset(
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      selectedLocationIds: List<String>.from(json['selectedLocationIds'] as List),
      minMinutes: json['minMinutes'] as int?,
      maxMinutes: json['maxMinutes'] as int?,
      showFavoritesOnly: json['showFavoritesOnly'] as bool,
      showRecentOnly: json['showRecentOnly'] as bool,
      sortOption: SortOption.values[json['sortOption'] as int],
      filterCombination: FilterCombination.values[json['filterCombination'] as int],
      customRules: (json['customRules'] as List)
          .map((rule) => FilterRule.fromJson(rule as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  @override
  String toString() {
    return 'FilterPreset(name: $name, active: ${selectedLocationIds.length} locations, ${startDate != null ? 'date range' : 'no date'})';
  }
}

class FilterRule {
  final String field;
  final FilterOperator operator;
  final dynamic value;
  final bool enabled;

  const FilterRule({
    required this.field,
    required this.operator,
    required this.value,
    this.enabled = true,
  });

  FilterRule copyWith({
    String? field,
    FilterOperator? operator,
    dynamic value,
    bool? enabled,
  }) {
    return FilterRule(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator.index,
      'value': value,
      'enabled': enabled,
    };
  }

  factory FilterRule.fromJson(Map<String, dynamic> json) {
    return FilterRule(
      field: json['field'] as String,
      operator: FilterOperator.values[json['operator'] as int],
      value: json['value'],
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'FilterRule($field $operator $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterRule &&
        other.field == field &&
        other.operator == operator &&
        other.value == value &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(field, operator, value, enabled);
  }
}

enum FilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  startsWith,
  endsWith,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  between,
  notBetween,
}

class FilterSuggestion {
  final String title;
  final String description;
  final FilterSuggestionType type;
  final VoidCallback action;

  const FilterSuggestion({
    required this.title,
    required this.description,
    required this.type,
    required this.action,
  });

  @override
  String toString() {
    return 'FilterSuggestion($title: $description)';
  }
}