import 'package:hive/hive.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import 'location_repository.dart';

class HiveLocationRepository implements LocationRepository {
  final Box<Location> _box;

  HiveLocationRepository(this._box);

  Future<void> initialize() async {
    // Box is already provided in constructor, no need to open
  }

  Future<List<Location>> getAllLocations() async {
    final locations = _box.values.toList();
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
    final newLocation = location.copyWith(
      id: location.id,
      createdAt: DateTime.now(),
    );
    await _box.put(newLocation.id, newLocation);
    return newLocation;
  }

  Future<Location> updateLocation(Location location) async {
    final updatedLocation = location.copyWith(
      usageCount: location.usageCount + 1,
    );
    await _box.put(location.id, updatedLocation);
    return updatedLocation;
  }

  Future<void> deleteLocation(String id) async {
    await _box.delete(id);
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
    return _box.get(id);
  }

  Future<List<Location>> getFavoriteLocations() async {
    final allLocations = await getAllLocations();
    return allLocations.where((location) => location.isFavorite).toList();
  }

  Future<void> toggleFavorite(String id) async {
    final location = _box.get(id);
    if (location != null) {
      final updatedLocation = location.copyWith(
        isFavorite: !location.isFavorite,
      );
      await _box.put(id, updatedLocation);
    }
  }

  Future<void> incrementUsageCount(String id) async {
    final location = _box.get(id);
    if (location != null) {
      final updatedLocation = location.copyWith(
        usageCount: location.usageCount + 1,
      );
      await _box.put(id, updatedLocation);
    }
  }

  Future<void> close() async {
    // Box is managed by RepositoryProvider, don't close here
  }

  // Implement LocationRepository interface methods
  @override
  List<Location> getAll() {
    return _box.values.toList();
  }

  @override
  Future<void> add(Location location) async {
    await _box.put(location.id, location);
  }

  @override
  Future<void> update(Location location) async {
    await _box.put(location.id, location);
  }

  @override
  Future<void> delete(Location location) async {
    await _box.delete(location.id);
  }
}
