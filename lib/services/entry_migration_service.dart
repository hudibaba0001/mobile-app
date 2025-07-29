import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/travel_time_entry.dart';
import '../models/entry.dart';

/// Service responsible for migrating data from old TravelTimeEntry model to new unified Entry model
class EntryMigrationService {
  
  /// Main migration method that converts TravelTimeEntry objects to Entry objects
  Future<MigrationResult> migrate() async {
    final stopwatch = Stopwatch()..start();
    try {
      debugPrint('Starting migration from TravelTimeEntry to Entry...');
      
      // Step 1: Open the old Hive box containing TravelTimeEntry objects
      debugPrint('Opening old TravelTimeEntry box...');
      final oldBox = await Hive.openBox<TravelTimeEntry>('travelEntries');
      
      // Step 2: Open the new Hive box for Entry objects
      debugPrint('Opening new Entry box...');
      final newBox = await Hive.openBox<Entry>('entries');
      
      // Check if there are entries to migrate
      final totalEntries = oldBox.length;
      debugPrint('Found $totalEntries entries to migrate');
      
      if (totalEntries == 0) {
        debugPrint('No entries to migrate');
        stopwatch.stop();
        return MigrationResult(
          migrationCount: 0,
          duration: stopwatch.elapsed,
          success: true,
        );
      }
      
      int migratedCount = 0;
      
      // Step 3: Iterate over all old entries and convert them
      debugPrint('Starting migration process...');
      for (var old in oldBox.values) {
        try {
          // Convert TravelTimeEntry to Entry
          final entry = Entry(
            id: old.id,
            userId: 'local_user', // Default user ID for local entries
            type: EntryType.travel,
            from: old.departure,
            to: old.arrival,
            travelMinutes: old.minutes,
            shifts: null,
            date: old.date,
            notes: old.info,
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
            journeyId: old.journeyId,
            segmentOrder: old.segmentOrder,
            totalSegments: old.totalSegments,
          );
          
          // Save the converted entry to the new box
          await newBox.put(entry.id, entry);
          migratedCount++;
          
        } catch (e) {
          debugPrint('Error migrating entry ${old.id}: $e');
          continue;
        }
      }
      
      // Step 4: Optionally archive old box for rollback safety
      // Note: We keep the old box intact for rollback purposes
      // To clear it later, you can call: await oldBox.clear();
      debugPrint('Keeping old data for rollback safety');
      
      // Step 5: Log migration summary
      debugPrint('=== Migration Summary ===');
      debugPrint('Total entries found: $totalEntries');
      debugPrint('Successfully migrated: $migratedCount');
      debugPrint('Migration completed successfully!');
      
      stopwatch.stop();
      return MigrationResult(
        migrationCount: migratedCount,
        duration: stopwatch.elapsed,
        success: true,
      );
      
    } catch (e) {
      stopwatch.stop();
      debugPrint('Critical error during migration: $e');
      return MigrationResult(
        migrationCount: 0,
        duration: stopwatch.elapsed,
        success: false,
      );
    }
  }
  
  /// Optional method to clear old data after successful migration
  Future<void> clearOldData() async {
    try {
      debugPrint('Clearing old TravelTimeEntry data...');
      final oldBox = await Hive.openBox<TravelTimeEntry>('travelEntries');
      await oldBox.clear();
      debugPrint('Old data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing old data: $e');
      rethrow;
    }
  }
  
  /// Check if migration is needed (old box has data, new box is empty or smaller)
  Future<bool> isMigrationNeeded() async {
    try {
      final oldBox = await Hive.openBox<TravelTimeEntry>('travelEntries');
      final newBox = await Hive.openBox<Entry>('entries');
      
      final hasOldData = oldBox.isNotEmpty;
      final hasNewData = newBox.isNotEmpty;
      
      // Migration needed if we have old data but no new data
      return hasOldData && !hasNewData;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }

}