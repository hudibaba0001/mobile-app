// ignore_for_file: avoid_print
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../utils/constants.dart';

class MigrationService {
  static const String _versionKey = 'data_version';
  static const int _currentVersion = 1;

  static Future<void> migrateIfNeeded() async {
    final box = await Hive.openBox('app_settings');
    final currentVersion = box.get(_versionKey, defaultValue: 0);

    if (currentVersion < _currentVersion) {
      await _performMigration(currentVersion);
      await box.put(_versionKey, _currentVersion);
    }
  }

  static Future<void> _performMigration(int fromVersion) async {
    if (fromVersion == 0) {
      await _migrateFromV0ToV1();
    }
  }

  static Future<void> _migrateFromV0ToV1() async {
    try {
      // Migrate travel entries
      final travelBox = await Hive.openBox<TravelTimeEntry>('travelEntriesBox');
      final entries = travelBox.values.toList();

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        // Check if entry already has new fields (to avoid re-migration)
        if (entry.id.isEmpty) {
          final updatedEntry = TravelTimeEntry(
            date: entry.date,
            departure: entry.departure,
            arrival: entry.arrival,
            info: entry.info,
            minutes: entry.minutes,
            id: const Uuid().v4(),
            createdAt:
                entry.date, // Use travel date as creation date for old entries
          );
          await travelBox.putAt(i, updatedEntry);
        }
      }

      // Migrate locations
      final locationBox = Hive.box<Location>(AppConstants.locationsBox);
      final locations = locationBox.values.toList();

      for (int i = 0; i < locations.length; i++) {
        final location = locations[i];
        // Check if location already has new fields
        if (location.id.isEmpty) {
          final updatedLocation = Location(
            name: location.name,
            address: location.address,
            id: const Uuid().v4(),
            createdAt: DateTime.now(),
            usageCount: 0,
            isFavorite: false,
          );
          await locationBox.putAt(i, updatedLocation);
        }
      }

      print('Migration from v0 to v1 completed successfully');
    } catch (e) {
      print('Migration failed: $e');
      // Don't rethrow - app should still work with old data
    }
  }
}
