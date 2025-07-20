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
  Map<String, dynamic> _filterPresets = {};
  String? _activePresetName;
  AppError? _lastError;

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
  Map<String, dynamic> get filterPresets => Map.unmodifiable(_filterPresets);
  String? get activePresetName => _activePresetName;
  AppError? get lastError => _lastError;
  
  bool get hasDateFilter => _startDate != null || _endDate != null;
  bool get hasLocationFilter => _selectedLocationIds.isNotEmpty;
  bool get hasDurationFilter => _minMinutes != null || _maxMinutes != null;
  bool get hasAnyFilter => hasDateFilter || hasLocationFilter || hasDurationFilter || 
                          _showFavoritesOnly || _showRecentOnly;

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

  // Set location filters
  void setLocationFilters(List<String> locationIds) {
    _selectedLocationIds = List.from(locationIds);
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

  // Clear all filters
  void clearAllFilters() {
    _startDate = null;
    _endDate = null;
    _selectedLocationIds.clear();
    _minMinutes = null;
    _maxMinutes = null;
    _showFavoritesOnly = false;
    _showRecentOnly = false;
    _activePresetName = null;
    _updateActiveState();
    _clearError();
    notifyListeners();
  }

  // Save current filters as preset
  void saveAsPreset(String name) {
    if (name.trim().isEmpty) {
      _handleError(ErrorHandler.handleValidationError('Preset name cannot be empty'));
      return;
    }

    _filterPresets[name] = {
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'selectedLocationIds': List.from(_selectedLocationIds),
      'minMinutes': _minMinutes,
      'maxMinutes': _maxMinutes,
      'showFavoritesOnly': _showFavoritesOnly,
      'showRecentOnly': _showRecentOnly,
      'sortOption': _sortOption.index,
    };
    
    _activePresetName = name;
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

    _startDate = preset['startDate'] != null ? DateTime.parse(preset['startDate']) : null;
    _endDate = preset['endDate'] != null ? DateTime.parse(preset['endDate']) : null;
    _selectedLocationIds = List<String>.from(preset['selectedLocationIds'] ?? []);
    _minMinutes = preset['minMinutes'];
    _maxMinutes = preset['maxMinutes'];
    _showFavoritesOnly = preset['showFavoritesOnly'] ?? false;
    _showRecentOnly = preset['showRecentOnly'] ?? false;
    _sortOption = SortOption.values[preset['sortOption'] ?? 0];
    _activePresetName = name;
    
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