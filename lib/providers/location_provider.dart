import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../location.dart';
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

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 