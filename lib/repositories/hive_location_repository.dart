import 'package:hive/hive.dart';
import '../models/location.dart';
import '../utils/constants.dart';

class HiveLocationRepository {
  Box<Location>? _box;

  Future<Box<Location>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Location>(AppConstants.locationsBox);
    }
    return _box!;
  }

  Future<void> initialize() async {
    await _getBox();
  }

  Future<List<Location>> getAllLocations() async {
    final box = await _getBox();
    final locations = box.values.toList();
    // Sort by usage count descending, then by name
    locations.sort((a, b) {
      if (a.usageCount != b.usageCount) {
        return b.usageCount.compareTo(a.usageCount);
      }
      return a.name.compareTo(b.name);
    });
    return locations;
  }

  Future<Location> addLocation(Location location) async {
    final box = await _getBox();
    final newLocation = location.copyWith(
      id: location.id,
      createdAt: DateTime.now(),
    );
    await box.put(newLocation.id, newLocation);
    return newLocation;
  }

  Future<Location> updateLocation(Location location) async {
    final box = await _getBox();
    final updatedLocation = location.copyWith(
      usageCount: location.usageCount + 1,
    );
    await box.put(location.id, updatedLocation);
    return updatedLocation;
  }

  Future<void> deleteLocation(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

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

  Future<Location?> getLocationById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  Future<List<Location>> getFavoriteLocations() async {
    final allLocations = await getAllLocations();
    return allLocations.where((location) => location.isFavorite).toList();
  }

  Future<void> toggleFavorite(String id) async {
    final box = await _getBox();
    final location = box.get(id);
    if (location != null) {
      final updatedLocation = location.copyWith(
        isFavorite: !location.isFavorite,
      );
      await box.put(id, updatedLocation);
    }
  }

  Future<void> incrementUsageCount(String id) async {
    final box = await _getBox();
    final location = box.get(id);
    if (location != null) {
      final updatedLocation = location.copyWith(
        usageCount: location.usageCount + 1,
      );
      await box.put(id, updatedLocation);
    }
  }

  Future<void> close() async {
    await _box?.close();
  }
} 