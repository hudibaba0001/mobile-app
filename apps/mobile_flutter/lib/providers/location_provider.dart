// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../models/autocomplete_suggestion.dart';
import '../repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  LocationProvider(this._repository) {
    refreshLocations();
  }

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Refresh locations from Hive storage
  Future<void> refreshLocations() async {
    try {
      _updateState(() {
        _isLoading = true;
        _error = null;
      });

      final locations = _repository.getAll();

      _updateState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      _updateState(() {
        _error = 'Unable to load your locations. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Add a new location
  Future<void> addLocation(Location location) async {
    try {
      await _repository.add(location);
      await refreshLocations();
    } catch (e) {
      debugPrint('Error adding location: $e');
      _updateState(() {
        _error = 'Unable to add the location. Please try again.';
      });
    }
  }

  /// Delete a location
  Future<void> deleteLocation(Location location) async {
    try {
      await _repository.delete(location);
      await refreshLocations();
    } catch (e) {
      debugPrint('Error deleting location: $e');
      _updateState(() {
        _error = 'Unable to delete the location. Please try again.';
      });
    }
  }

  /// Update a location
  Future<void> updateLocation(Location location) async {
    try {
      await _repository.update(location);
      await refreshLocations();
    } catch (e) {
      debugPrint('Error updating location: $e');
      _updateState(() {
        _error = 'Unable to update the location. Please try again.';
      });
    }
  }

  /// Get locations by name (for search/filtering)
  List<Location> getLocationsByName(String query) {
    if (query.isEmpty) return _locations;

    final lowercaseQuery = query.toLowerCase();
    return _locations
        .where((location) =>
            location.name.toLowerCase().contains(lowercaseQuery) ||
            location.address.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Get favorite locations
  List<Location> getFavoriteLocations() {
    return _locations.where((location) => location.isFavorite).toList();
  }

  /// Get most used locations
  List<Location> getMostUsedLocations({int limit = 5}) {
    final sortedLocations = List<Location>.from(_locations);
    sortedLocations.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sortedLocations.take(limit).toList();
  }

  /// Get recent locations based on usage
  List<Location> getRecentLocations({int limit = 5}) {
    final usedLocations =
        _locations.where((loc) => loc.usageCount > 0).toList();
    usedLocations.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return usedLocations.take(limit).toList();
  }

  /// Search locations by name or address
  List<Location> searchLocations(String query) {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _locations.where((location) {
      return location.name.toLowerCase().contains(lowercaseQuery) ||
          location.address.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get autocomplete suggestions for a location query
  List<AutocompleteSuggestion> getAutocompleteSuggestions(String query,
      {int limit = 5}) {
    if (query.trim().isEmpty) {
      // Return recent and favorite locations when no query
      final suggestions = <AutocompleteSuggestion>[];

      // Add favorites first
      for (final location in getFavoriteLocations()) {
        suggestions.add(AutocompleteSuggestion(
          text: location.name,
          subtitle: location.address,
          type: SuggestionType.favorite,
          location: location,
        ));
      }

      // Add recent locations
      for (final location in getRecentLocations()) {
        if (!suggestions.any((s) => s.location?.id == location.id)) {
          suggestions.add(AutocompleteSuggestion(
            text: location.name,
            subtitle: location.address,
            type: SuggestionType.recent,
            location: location,
          ));
        }
      }

      return suggestions.take(limit).toList();
    }

    final suggestions = <AutocompleteSuggestion>[];
    final lowercaseQuery = query.toLowerCase();
    final seenLocationIds = <String>{};
    var hasExactTextMatch = false;

    for (final location in _locations) {
      final nameLower = location.name.toLowerCase();
      final addressLower = location.address.toLowerCase();
      final isExactMatch =
          nameLower == lowercaseQuery || addressLower == lowercaseQuery;
      final isPartialMatch = nameLower.contains(lowercaseQuery) ||
          addressLower.contains(lowercaseQuery);

      if (!isExactMatch && !isPartialMatch) {
        continue;
      }

      if (seenLocationIds.add(location.id)) {
        suggestions.add(AutocompleteSuggestion(
          text: location.name,
          subtitle: location.address,
          type: SuggestionType.saved,
          location: location,
        ));
      }

      if (isExactMatch) {
        hasExactTextMatch = true;
      }
    }

    // Finally, add the raw input as a custom suggestion if it doesn't match any saved location
    if (!hasExactTextMatch) {
      suggestions.add(AutocompleteSuggestion(
        text: query,
        subtitle: 'Custom location',
        type: SuggestionType.custom,
      ));
    }

    return suggestions.take(limit).toList();
  }

  // Backward-compatible alias used by some widgets/tests that expect raw strings
  List<String> getAddressSuggestions(String query, {int limit = 5}) {
    final suggestions = getAutocompleteSuggestions(query, limit: limit);
    return suggestions.map((s) => s.text).toList();
  }

  /// Get recently added locations
  List<Location> getRecentlyAddedLocations({int limit = 5}) {
    final sortedLocations = List<Location>.from(_locations);
    sortedLocations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedLocations.take(limit).toList();
  }

  /// Toggle favorite status for a location
  Future<void> toggleFavorite(String locationId) async {
    try {
      final location =
          _repository.getAll().firstWhere((loc) => loc.id == locationId);
      final updatedLocation =
          location.copyWith(isFavorite: !location.isFavorite);
      await _repository.update(updatedLocation);
      await refreshLocations();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _updateState(() {
        _error = 'Unable to update favorite status. Please try again.';
      });
    }
  }

  /// Increment usage count for a location
  Future<void> incrementUsageCount(String locationId) async {
    try {
      final location =
          _repository.getAll().firstWhere((loc) => loc.id == locationId);
      final updatedLocation =
          location.copyWith(usageCount: location.usageCount + 1);
      await _repository.update(updatedLocation);
      await refreshLocations();
    } catch (e) {
      debugPrint('Error incrementing usage count: $e');
      _updateState(() {
        _error = 'Unable to update location usage. Please try again.';
      });
    }
  }

  // Helper method to update state and notify listeners
  void _updateState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
