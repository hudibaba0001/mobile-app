import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/location.dart';
import '../utils/constants.dart';

class LocationProvider extends ChangeNotifier {
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Refresh locations from Hive storage
  Future<void> refreshLocations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final box = Hive.box<Location>(AppConstants.locationsBox);
      final locations = box.values.toList();
      
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load locations: $e';
        _isLoading = false;
      });
    }
  }

  /// Add a new location
  Future<void> addLocation(Location location) async {
    try {
      final box = Hive.box<Location>(AppConstants.locationsBox);
      await box.add(location);
      await refreshLocations();
    } catch (e) {
      setState(() {
        _error = 'Failed to add location: $e';
      });
    }
  }

  /// Delete a location by index
  Future<void> deleteLocation(int index) async {
    try {
      final box = Hive.box<Location>(AppConstants.locationsBox);
      await box.deleteAt(index);
      await refreshLocations();
    } catch (e) {
      setState(() {
        _error = 'Failed to delete location: $e';
      });
    }
  }

  /// Get locations by name (for search/filtering)
  List<Location> getLocationsByName(String query) {
    if (query.isEmpty) return _locations;
    
    return _locations.where((location) =>
        location.name.toLowerCase().contains(query.toLowerCase()) ||
        location.address.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Get favorite locations
  List<Location> get favoriteLocations {
    // For now, return all locations. In the future, we can add a favorite field to Location model
    return _locations;
  }

  /// Get most used locations (for analytics)
  List<Location> get mostUsedLocations {
    // For now, return all locations. In the future, we can track usage
    return _locations;
  }

  /// Get address suggestions for search
  List<String> getAddressSuggestions(String query, {int limit = 5}) {
    if (query.isEmpty) return [];
    
    final suggestions = <String>{};
    for (final location in _locations) {
      if (location.address.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(location.address);
        if (suggestions.length >= limit) break;
      }
    }
    return suggestions.toList();
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
      final box = Hive.box<Location>(AppConstants.locationsBox);
      final location = box.values.firstWhere((loc) => loc.id == locationId);
      final updatedLocation = location.copyWith(isFavorite: !location.isFavorite);
      await box.put(locationId, updatedLocation);
      await refreshLocations();
    } catch (e) {
      setState(() {
        _error = 'Failed to toggle favorite: $e';
      });
    }
  }

  /// Increment usage count for a location
  Future<void> incrementUsageCount(String locationId) async {
    try {
      final box = Hive.box<Location>(AppConstants.locationsBox);
      final location = box.values.firstWhere((loc) => loc.id == locationId);
      final updatedLocation = location.copyWith(usageCount: location.usageCount + 1);
      await box.put(locationId, updatedLocation);
      await refreshLocations();
    } catch (e) {
      setState(() {
        _error = 'Failed to increment usage count: $e';
      });
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 