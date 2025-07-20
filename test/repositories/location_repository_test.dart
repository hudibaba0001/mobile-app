import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/location.dart';
import 'package:myapp/repositories/hive_location_repository.dart';
import 'package:myapp/utils/constants.dart';

void main() {
  group('HiveLocationRepository Tests', () {
    late HiveLocationRepository repository;
    late Box<Location> testBox;

    setUpAll(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(LocationAdapter());
    });

    setUp(() async {
      testBox = await Hive.openBox<Location>('test_${AppConstants.locationsBox}');
      repository = HiveLocationRepository();
    });

    tearDown(() async {
      await testBox.clear();
      await testBox.close();
    });

    test('should add and retrieve location', () async {
      final location = Location(
        name: 'Test Location',
        address: '123 Test Street, Test City',
      );

      await repository.addLocation(location);
      final locations = await repository.getAllLocations();

      expect(locations.length, 1);
      expect(locations.first.name, 'Test Location');
      expect(locations.first.address, '123 Test Street, Test City');
      expect(locations.first.usageCount, 0);
      expect(locations.first.isFavorite, false);
    });

    test('should update existing location', () async {
      final location = Location(
        name: 'Original Name',
        address: 'Original Address',
      );

      await repository.addLocation(location);
      
      final updatedLocation = location.copyWith(
        name: 'Updated Name',
        usageCount: 5,
        isFavorite: true,
      );

      await repository.updateLocation(updatedLocation);
      final locations = await repository.getAllLocations();

      expect(locations.length, 1);
      expect(locations.first.name, 'Updated Name');
      expect(locations.first.address, 'Original Address'); // Should remain unchanged
      expect(locations.first.usageCount, 5);
      expect(locations.first.isFavorite, true);
    });

    test('should delete location by id', () async {
      final location = Location(
        name: 'Test Location',
        address: 'Test Address',
      );

      await repository.addLocation(location);
      expect((await repository.getAllLocations()).length, 1);

      await repository.deleteLocation(location.id);
      expect((await repository.getAllLocations()).length, 0);
    });

    test('should search locations by query', () async {
      final locations = [
        Location(name: 'Stockholm Central', address: 'Central Station, Stockholm'),
        Location(name: 'Gothenburg Office', address: 'Business District, Gothenburg'),
        Location(name: 'Home', address: 'Residential Area, Stockholm'),
      ];

      for (final location in locations) {
        await repository.addLocation(location);
      }

      final stockholmResults = await repository.searchLocations('Stockholm');
      expect(stockholmResults.length, 2);

      final gothenburgResults = await repository.searchLocations('Gothenburg');
      expect(gothenburgResults.length, 1);

      final officeResults = await repository.searchLocations('Office');
      expect(officeResults.length, 1);

      final emptyResults = await repository.searchLocations('NonExistent');
      expect(emptyResults.length, 0);
    });

    test('should increment usage count', () async {
      final location = Location(
        name: 'Test Location',
        address: 'Test Address',
        usageCount: 0,
      );

      await repository.addLocation(location);
      
      await repository.incrementUsageCount(location.id);
      
      final updatedLocation = await repository.getLocationById(location.id);
      expect(updatedLocation?.usageCount, 1);

      await repository.incrementUsageCount(location.id);
      final againUpdatedLocation = await repository.getLocationById(location.id);
      expect(againUpdatedLocation?.usageCount, 2);
    });

    test('should get frequent locations', () async {
      final locations = [
        Location(name: 'High Usage', address: 'Address 1', usageCount: 10),
        Location(name: 'Medium Usage', address: 'Address 2', usageCount: 5),
        Location(name: 'Low Usage', address: 'Address 3', usageCount: 1),
        Location(name: 'No Usage', address: 'Address 4', usageCount: 0),
      ];

      for (final location in locations) {
        await repository.addLocation(location);
      }

      final frequentLocations = await repository.getFrequentLocations(limit: 5);
      expect(frequentLocations.length, 3); // Only locations with usage > 0
      expect(frequentLocations.first.name, 'High Usage');
      expect(frequentLocations.last.name, 'Low Usage');
    });

    test('should get favorite locations', () async {
      final locations = [
        Location(name: 'Favorite 1', address: 'Address 1', isFavorite: true),
        Location(name: 'Regular 1', address: 'Address 2', isFavorite: false),
        Location(name: 'Favorite 2', address: 'Address 3', isFavorite: true),
      ];

      for (final location in locations) {
        await repository.addLocation(location);
      }

      final favoriteLocations = await repository.getFavoriteLocations();
      expect(favoriteLocations.length, 2);
      expect(favoriteLocations.every((l) => l.isFavorite), true);
    });

    test('should find location by address', () async {
      final location = Location(
        name: 'Test Location',
        address: '123 Unique Address, City',
      );

      await repository.addLocation(location);

      final foundLocation = await repository.findLocationByAddress('123 Unique Address, City');
      expect(foundLocation, isNotNull);
      expect(foundLocation?.name, 'Test Location');

      final notFoundLocation = await repository.findLocationByAddress('Non-existent Address');
      expect(notFoundLocation, isNull);
    });

    test('should toggle favorite status', () async {
      final location = Location(
        name: 'Test Location',
        address: 'Test Address',
        isFavorite: false,
      );

      await repository.addLocation(location);

      await repository.toggleFavorite(location.id);
      var updatedLocation = await repository.getLocationById(location.id);
      expect(updatedLocation?.isFavorite, true);

      await repository.toggleFavorite(location.id);
      updatedLocation = await repository.getLocationById(location.id);
      expect(updatedLocation?.isFavorite, false);
    });

    test('should get location suggestions', () async {
      final locations = [
        Location(name: 'Stockholm Central', address: 'Central Station, Stockholm'),
        Location(name: 'Stockholm Airport', address: 'Arlanda Airport, Stockholm'),
        Location(name: 'Gothenburg', address: 'City Center, Gothenburg'),
      ];

      for (final location in locations) {
        await repository.addLocation(location);
      }

      final suggestions = await repository.getLocationSuggestions('Stockholm', limit: 5);
      expect(suggestions.length, 2);
      expect(suggestions.every((s) => s.contains('Stockholm')), true);
    });
  });
}