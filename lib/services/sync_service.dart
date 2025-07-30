import 'package:hive/hive.dart';
import '../models/entry.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

/// Service for syncing unified Entry data (replaces old sync services)
/// Only syncs travel entries (type == EntryType.travel) to maintain compatibility
class SyncService {
  static const String _entriesBoxName = 'entries';
  static const String _syncStatusKey = 'last_sync_timestamp';

  /// Get the Hive box for entries
  Future<Box<Entry>> _getEntriesBox() async {
    return await Hive.openBox<Entry>(_entriesBoxName);
  }

  /// Get the settings box for sync metadata
  Future<Box> _getSettingsBox() async {
    return await Hive.openBox('app_settings');
  }

  /// Get all travel entries that need to be synced
  Future<List<Entry>> getTravelEntriesToSync() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Filter only travel entries from unified box for syncing
          return box.values
              .where((entry) => entry.type == EntryType.travel)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get travel entries modified since last sync
  Future<List<Entry>> getTravelEntriesModifiedSince(DateTime lastSync) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Filter travel entries modified since last sync
          return box.values
              .where((entry) => 
                  entry.type == EntryType.travel &&
                  (entry.updatedAt?.isAfter(lastSync) == true ||
                   entry.createdAt.isAfter(lastSync)))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Sync travel entries to cloud (placeholder for future cloud implementation)
  Future<bool> syncTravelEntriesToCloud() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          // Get only travel entries for syncing
          final travelEntries = await getTravelEntriesToSync();
          
          // TODO: Implement actual cloud sync logic here
          // For now, just simulate sync success
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Update last sync timestamp
          await _updateLastSyncTimestamp();
          
          return true;
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Sync travel entries from cloud (placeholder for future cloud implementation)
  Future<List<Entry>> syncTravelEntriesFromCloud() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          // TODO: Implement actual cloud sync logic here
          // For now, return empty list
          await Future.delayed(const Duration(milliseconds: 500));
          
          return <Entry>[];
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Add synced travel entry to local storage
  Future<void> addSyncedTravelEntry(Entry entry) async {
    try {
      // Ensure this is a travel entry
      if (entry.type != EntryType.travel) {
        throw ArgumentError('SyncService only handles travel entries');
      }

      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Add to unified entries box
          await box.put(entry.id, entry);
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Update synced travel entry in local storage
  Future<void> updateSyncedTravelEntry(Entry entry) async {
    try {
      // Ensure this is a travel entry
      if (entry.type != EntryType.travel) {
        throw ArgumentError('SyncService only handles travel entries');
      }

      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Update in unified entries box
          await box.put(entry.id, entry);
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Delete synced travel entry from local storage
  Future<void> deleteSyncedTravelEntry(String entryId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final entry = box.get(entryId);
          
          // Only delete if it's a travel entry
          if (entry != null && entry.type == EntryType.travel) {
            await box.delete(entryId);
          }
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final box = await _getSettingsBox();
      final timestamp = box.get(_syncStatusKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (error) {
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final box = await _getSettingsBox();
      await box.put(_syncStatusKey, DateTime.now().toIso8601String());
    } catch (error) {
      // Ignore sync timestamp update errors
    }
  }

  /// Check if sync is needed (has unsync travel entries)
  Future<bool> isSyncNeeded() async {
    try {
      final lastSync = await getLastSyncTimestamp();
      if (lastSync == null) return true;

      final modifiedEntries = await getTravelEntriesModifiedSince(lastSync);
      return modifiedEntries.isNotEmpty;
    } catch (error) {
      return true; // Assume sync is needed if we can't determine
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final travelEntries = await getTravelEntriesToSync();
      final lastSync = await getLastSyncTimestamp();
      final needsSync = await isSyncNeeded();

      return {
        'totalTravelEntries': travelEntries.length,
        'lastSyncAt': lastSync?.toIso8601String(),
        'needsSync': needsSync,
        'syncEnabled': true, // TODO: Make this configurable
      };
    } catch (error) {
      return {
        'totalTravelEntries': 0,
        'lastSyncAt': null,
        'needsSync': false,
        'syncEnabled': false,
      };
    }
  }

  /// Perform full sync (both directions)
  Future<SyncResult> performFullSync() async {
    try {
      final startTime = DateTime.now();
      int uploadedCount = 0;
      int downloadedCount = 0;
      final errors = <String>[];

      // Upload travel entries to cloud
      try {
        final success = await syncTravelEntriesToCloud();
        if (success) {
          final travelEntries = await getTravelEntriesToSync();
          uploadedCount = travelEntries.length;
        }
      } catch (error) {
        errors.add('Upload failed: $error');
      }

      // Download travel entries from cloud
      try {
        final downloadedEntries = await syncTravelEntriesFromCloud();
        downloadedCount = downloadedEntries.length;
        
        // Add downloaded entries to local storage
        for (final entry in downloadedEntries) {
          await addSyncedTravelEntry(entry);
        }
      } catch (error) {
        errors.add('Download failed: $error');
      }

      final duration = DateTime.now().difference(startTime);
      final success = errors.isEmpty;

      return SyncResult(
        success: success,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      return SyncResult(
        success: false,
        uploadedCount: 0,
        downloadedCount: 0,
        duration: Duration.zero,
        errors: [appError.message],
      );
    }
  }
}

/// Result object for sync operations
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final Duration duration;
  final List<String> errors;

  const SyncResult({
    required this.success,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.duration,
    required this.errors,
  });

  /// Human-readable summary
  String get summary {
    if (success) {
      return 'Sync completed: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inSeconds}s';
    } else {
      return 'Sync failed: ${errors.join(', ')}';
    }
  }

  @override
  String toString() {
    return 'SyncResult(success: $success, uploaded: $uploadedCount, downloaded: $downloadedCount, duration: ${duration.inMilliseconds}ms)';
  }
}