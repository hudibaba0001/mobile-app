import '../models/location.dart';

abstract class LocationRepository {
  Future<List<Location>> getAllLocations();
  Future<Location?> getLocationById(String id);
  Future<void> addLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String id);
  Future<List<Location>> searchLocations(String query);
}

class HiveLocationRepository implements LocationRepository {
  @override
  Future<List<Location>> getAllLocations() async {
    // TODO: Implement actual data fetching
    return [];
  }

  @override
  Future<Location?> getLocationById(String id) async {
    // TODO: Implement actual data fetching
    return null;
  }

  @override
  Future<void> addLocation(Location location) async {
    // TODO: Implement actual data saving
  }

  @override
  Future<void> updateLocation(Location location) async {
    // TODO: Implement actual data updating
  }

  @override
  Future<void> deleteLocation(String id) async {
    // TODO: Implement actual data deletion
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    // TODO: Implement actual search
    return [];
  }
} 