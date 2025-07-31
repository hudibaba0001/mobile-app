import 'package:hive/hive.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import 'location_repository.dart';

class HiveLocationRepository implements LocationRepository {
  Box<Location>? _box;

  Future<Box<Location>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Location>(AppConstants.locationsBox);
    }
    return _box!;
  }

  @override
  Future<List<Location>> getAllLocations() async {
    final box = await _getBox();
    final locations = box.values.toList();
    // Sort by usage count descending, then by name
    locations.sort((a, b) {
      final usageComparison = b.usageCount.compareTo(a.usageCount);
      if (usageComparison != 0) return usageComparison;
      return a.name.compareTo(b.name);
    });
    return locations;
  }

  @override
  Future<void> addLocation(Location location) async {
    final box = await _getBox();
    await box.add(location);
  }

  @override
  Future<void> updateLocation(Location location) async {
    final box = await _getBox();
    final index = box.values.toList().indexWhere((l) => l.id == location.id);
    if (index != -1) {
      await box.putAt(index, location);
    } else {
      throw Exception('Location not found for update');
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    final box = await _getBox();
    final locations = box.values.toList();
    for (int i = 0; i < locations.length; i++) {
      if (locations[i].id == id) {
        await box.deleteAt(i);
        return;
      }
    }
    throw Exception('Location not found for deletion');
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      return getAllLocations();
    }

    final allLocations = await getAllLocations();
    final lowercaseQuery = query.toLowerCase();

    return allLocations.where((location) {
      return location.name.toLowerCase().contains(lowercaseQuery) ||
          location.address.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  Future<void> incrementUsageCount(String id) async {
    final location = await getLocationById(id);
    if (location != null) {
      final updatedLocation = location.incrementUsage();
      await updateLocation(updatedLocation);
    }
  }

  @override
  Future<List<Location>> getFrequentLocations({int limit = 10}) async {
    final allLocations = await getAllLocations();
    final frequentLocations = allLocations
        .where((l) => l.usageCount > 0)
        .toList();

    // Sort by usage count descending
    frequentLocations.sort((a, b) => b.usageCount.compareTo(a.usageCount));

    return frequentLocations.take(limit).toList();
  }

  @override
  Future<List<Location>> getFavoriteLocations() async {
    final allLocations = await getAllLocations();
    return allLocations.where((location) => location.isFavorite).toList();
  }

  @override
  Future<Location?> getLocationById(String id) async {
    final box = await _getBox();
    final locations = box.values.toList();
    try {
      return locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Location?> findLocationByAddress(String address) async {
    final box = await _getBox();
    final locations = box.values.toList();
    try {
      return locations.firstWhere(
        (location) => location.address.toLowerCase() == address.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get location suggestions for autocomplete
  Future<List<String>> getLocationSuggestions(
    String query, {
    int limit = 5,
  }) async {
    final locations = await searchLocations(query);
    return locations.take(limit).map((location) => location.address).toList();
  }

  // Helper method to get locations count
  Future<int> getLocationsCount() async {
    final box = await _getBox();
    return box.length;
  }

  // Helper method to toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final location = await getLocationById(id);
    if (location != null) {
      final updatedLocation = location.toggleFavorite();
      await updateLocation(updatedLocation);
    }
  }

  // Helper method to get most used locations
  Future<List<Location>> getMostUsedLocations({int limit = 5}) async {
    final locations = await getFrequentLocations(limit: limit);
    return locations;
  }

  // Helper method to get recently added locations
  Future<List<Location>> getRecentlyAddedLocations({int limit = 5}) async {
    final box = await _getBox();
    final allLocations = box.values.toList();
    allLocations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allLocations.take(limit).toList();
  }
}
