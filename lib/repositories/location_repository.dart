import '../models/location.dart';

abstract class LocationRepository {
  Future<List<Location>> getAllLocations();
  Future<void> addLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String id);
  Future<List<Location>> searchLocations(String query);
  Future<void> incrementUsageCount(String id);
  Future<List<Location>> getFrequentLocations({int limit = 10});
  Future<List<Location>> getFavoriteLocations();
  Future<Location?> getLocationById(String id);
  Future<Location?> findLocationByAddress(String address);
}