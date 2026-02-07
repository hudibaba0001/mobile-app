import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class BackupService {
  static const String backupFileName = 'travel_time_backup.json';
  static const String backupVersion = '1.0';

  /// Create a backup of all data
  static Future<String> createBackup() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _performBackup(),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  static Future<String> _performBackup() async {
    final travelBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    final locationBox = Hive.box<Location>(AppConstants.locationsBox);

    final backupData = {
      'version': backupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'travelEntries': travelBox.values
          .map((entry) => {
                'id': entry.id,
                'date': entry.date.toIso8601String(),
                'departure': entry.departure,
                'arrival': entry.arrival,
                'info': entry.info,
                'minutes': entry.minutes,
                'createdAt': entry.createdAt.toIso8601String(),
                'updatedAt': entry.updatedAt?.toIso8601String(),
                'departureLocationId': entry.departureLocationId,
                'arrivalLocationId': entry.arrivalLocationId,
              })
          .toList(),
      'locations': locationBox.values
          .map((location) => {
                'id': location.id,
                'name': location.name,
                'address': location.address,
                'createdAt': location.createdAt.toIso8601String(),
                'usageCount': location.usageCount,
                'isFavorite': location.isFavorite,
              })
          .toList(),
    };

    final jsonString = jsonEncode(backupData);

    // Save to documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$backupFileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Restore data from backup
  static Future<void> restoreFromBackup(String filePath) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _performRestore(filePath),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  static Future<void> _performRestore(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validate backup version
    final version = backupData['version'] as String?;
    if (version != backupVersion) {
      throw Exception('Incompatible backup version: $version');
    }

    // Clear existing data
    final travelBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    final locationBox = Hive.box<Location>(AppConstants.locationsBox);

    await travelBox.clear();
    await locationBox.clear();

    // Restore locations first (they might be referenced by travel entries)
    final locations = backupData['locations'] as List<dynamic>;
    for (final locationData in locations) {
      final location = Location(
        id: locationData['id'] as String,
        name: locationData['name'] as String,
        address: locationData['address'] as String,
        createdAt: DateTime.parse(locationData['createdAt'] as String),
        usageCount: locationData['usageCount'] as int? ?? 0,
        isFavorite: locationData['isFavorite'] as bool? ?? false,
      );
      await locationBox.add(location);
    }

    // Restore travel entries
    final travelEntries = backupData['travelEntries'] as List<dynamic>;
    for (final entryData in travelEntries) {
      final entry = TravelTimeEntry(
        id: entryData['id'] as String,
        date: DateTime.parse(entryData['date'] as String),
        departure: entryData['departure'] as String,
        arrival: entryData['arrival'] as String,
        info: entryData['info'] as String?,
        minutes: entryData['minutes'] as int,
        createdAt: DateTime.parse(entryData['createdAt'] as String),
        updatedAt: entryData['updatedAt'] != null
            ? DateTime.parse(entryData['updatedAt'] as String)
            : null,
        departureLocationId: entryData['departureLocationId'] as String?,
        arrivalLocationId: entryData['arrivalLocationId'] as String?,
      );
      await travelBox.add(entry);
    }
  }

  /// Validate backup file
  static Future<bool> validateBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check required fields
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('timestamp') ||
          !backupData.containsKey('travelEntries') ||
          !backupData.containsKey('locations')) {
        return false;
      }

      // Check version compatibility
      final version = backupData['version'] as String?;
      if (version != backupVersion) {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /// Get backup info without restoring
  static Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final travelEntries = backupData['travelEntries'] as List<dynamic>;
      final locations = backupData['locations'] as List<dynamic>;

      return {
        'version': backupData['version'],
        'timestamp': backupData['timestamp'],
        'travelEntriesCount': travelEntries.length,
        'locationsCount': locations.length,
        'fileSize': await file.length(),
      };
    } catch (error) {
      return null;
    }
  }

  /// Create automatic backup (called periodically)
  static Future<void> createAutoBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final autoBackupFileName = 'auto_backup_$timestamp.json';

      final travelBox =
          Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
      final locationBox = Hive.box<Location>(AppConstants.locationsBox);

      // Only create backup if there's data
      if (travelBox.isEmpty && locationBox.isEmpty) {
        return;
      }

      final backupData = {
        'version': backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'travelEntries': travelBox.values
            .map((entry) => {
                  'id': entry.id,
                  'date': entry.date.toIso8601String(),
                  'departure': entry.departure,
                  'arrival': entry.arrival,
                  'info': entry.info,
                  'minutes': entry.minutes,
                  'createdAt': entry.createdAt.toIso8601String(),
                  'updatedAt': entry.updatedAt?.toIso8601String(),
                  'departureLocationId': entry.departureLocationId,
                  'arrivalLocationId': entry.arrivalLocationId,
                })
            .toList(),
        'locations': locationBox.values
            .map((location) => {
                  'id': location.id,
                  'name': location.name,
                  'address': location.address,
                  'createdAt': location.createdAt.toIso8601String(),
                  'usageCount': location.usageCount,
                  'isFavorite': location.isFavorite,
                })
            .toList(),
      };

      final jsonString = jsonEncode(backupData);
      final file = File('${directory.path}/$autoBackupFileName');
      await file.writeAsString(jsonString);

      // Clean up old auto backups (keep only last 5)
      await _cleanupOldBackups(directory);
    } catch (error) {
      // Auto backup failures should not crash the app
      final appError = ErrorHandler.handleStorageError(error);
      ErrorHandler.handleError(appError);
    }
  }

  static Future<void> _cleanupOldBackups(Directory directory) async {
    try {
      final files = directory
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('auto_backup_'))
          .cast<File>()
          .toList();

      if (files.length <= 5) return;

      // Sort by modification time (newest first)
      files
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete old backups (keep only the 5 most recent)
      for (int i = 5; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (error) {
      // Cleanup failures should not crash the app
    }
  }
}
