import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/travel_time_entry.dart';
import 'package:myapp/repositories/hive_travel_repository.dart';
import 'package:myapp/utils/constants.dart';

void main() {
  group('HiveTravelRepository Tests', () {
    late HiveTravelRepository repository;
    late Box<TravelTimeEntry> testBox;

    setUpAll(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(TravelTimeEntryAdapter());
    });

    setUp(() async {
      testBox = await Hive.openBox<TravelTimeEntry>('test_${AppConstants.travelEntriesBox}');
      repository = HiveTravelRepository();
    });

    tearDown(() async {
      await testBox.clear();
      await testBox.close();
    });

    test('should add and retrieve travel entry', () async {
      final entry = TravelTimeEntry(
        date: DateTime.now(),
        departure: 'Test Departure',
        arrival: 'Test Arrival',
        minutes: 30,
      );

      await repository.addEntry(entry);
      final entries = await repository.getAllEntries();

      expect(entries.length, 1);
      expect(entries.first.departure, 'Test Departure');
      expect(entries.first.arrival, 'Test Arrival');
      expect(entries.first.minutes, 30);
    });

    test('should update existing entry', () async {
      final entry = TravelTimeEntry(
        date: DateTime.now(),
        departure: 'Original Departure',
        arrival: 'Original Arrival',
        minutes: 30,
      );

      await repository.addEntry(entry);
      
      final updatedEntry = entry.copyWith(
        departure: 'Updated Departure',
        minutes: 45,
      );

      await repository.updateEntry(updatedEntry);
      final entries = await repository.getAllEntries();

      expect(entries.length, 1);
      expect(entries.first.departure, 'Updated Departure');
      expect(entries.first.minutes, 45);
      expect(entries.first.arrival, 'Original Arrival'); // Should remain unchanged
    });

    test('should delete entry by id', () async {
      final entry = TravelTimeEntry(
        date: DateTime.now(),
        departure: 'Test Departure',
        arrival: 'Test Arrival',
        minutes: 30,
      );

      await repository.addEntry(entry);
      expect((await repository.getAllEntries()).length, 1);

      await repository.deleteEntry(entry.id);
      expect((await repository.getAllEntries()).length, 0);
    });

    test('should search entries by query', () async {
      final entries = [
        TravelTimeEntry(
          date: DateTime.now(),
          departure: 'Stockholm Central',
          arrival: 'Gothenburg',
          minutes: 180,
        ),
        TravelTimeEntry(
          date: DateTime.now(),
          departure: 'Malmö',
          arrival: 'Stockholm',
          minutes: 120,
        ),
        TravelTimeEntry(
          date: DateTime.now(),
          departure: 'Uppsala',
          arrival: 'Västerås',
          minutes: 60,
        ),
      ];

      for (final entry in entries) {
        await repository.addEntry(entry);
      }

      final stockholmResults = await repository.searchEntries('Stockholm');
      expect(stockholmResults.length, 2);

      final gothenburgResults = await repository.searchEntries('Gothenburg');
      expect(gothenburgResults.length, 1);

      final emptyResults = await repository.searchEntries('NonExistent');
      expect(emptyResults.length, 0);
    });

    test('should get entries in date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final entries = [
        TravelTimeEntry(
          date: yesterday,
          departure: 'Yesterday Trip',
          arrival: 'Destination',
          minutes: 30,
        ),
        TravelTimeEntry(
          date: today,
          departure: 'Today Trip',
          arrival: 'Destination',
          minutes: 45,
        ),
        TravelTimeEntry(
          date: tomorrow,
          departure: 'Tomorrow Trip',
          arrival: 'Destination',
          minutes: 60,
        ),
      ];

      for (final entry in entries) {
        await repository.addEntry(entry);
      }

      final todayEntries = await repository.getEntriesInDateRange(today, today);
      expect(todayEntries.length, 1);
      expect(todayEntries.first.departure, 'Today Trip');

      final allEntries = await repository.getEntriesInDateRange(yesterday, tomorrow);
      expect(allEntries.length, 3);
    });

    test('should get recent routes', () async {
      final entries = [
        TravelTimeEntry(
          date: DateTime.now(),
          departure: 'A',
          arrival: 'B',
          minutes: 30,
        ),
        TravelTimeEntry(
          date: DateTime.now().subtract(const Duration(hours: 1)),
          departure: 'C',
          arrival: 'D',
          minutes: 45,
        ),
        TravelTimeEntry(
          date: DateTime.now().subtract(const Duration(hours: 2)),
          departure: 'A',
          arrival: 'B', // Duplicate route
          minutes: 30,
        ),
      ];

      for (final entry in entries) {
        await repository.addEntry(entry);
      }

      final routes = await repository.getRecentRoutes(limit: 5);
      expect(routes.length, 2); // Should deduplicate
      expect(routes.contains('A → B'), true);
      expect(routes.contains('C → D'), true);
    });
  });
}