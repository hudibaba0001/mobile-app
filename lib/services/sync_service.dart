import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/entry.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

/// Service for syncing unified Entry data with Firestore
/// Updated to work with the unified Entry model instead of TravelTimeEntry
/// Syncs only travel entries (EntryType.travel) to maintain backward compatibility
/// 
/// Key Changes:
/// 1. Changed Firestore collection from 'travelEntries' to unified 'entries'
/// 2. All sync methods now filter by EntryType.travel
/// 3. Uses Entry.toFirestore() and Entry.fromFirestore() for serialization
/// 4. Maintains conflict resolution and error handling
/// 5. Supports future expansion to other entry types
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Changed from 'travelEntries' to unified 'entries' collection
  static const String _entriesCollection = 'entries';
  static const String _entriesBoxName = 'entries';
  static const String _settingsBoxName = 'app_settings';
  static const String _syncStatusKey = 'last_sync_timestamp';

  /// Get the Hive box for unified entries
  Future<Box<Entry>> _getEntriesBox() async {
    return await Hive.openBox<Entry>(_entriesBoxName);
  }

  /// Get the settings box for sync metadata
  Future<Box> _getSettingsBox() async {
    return await Hive.openBox(_settingsBoxName);
  }

  /// Sync entries by type to Firestore using unified Entry model
  /// Only syncs entries where type == specified EntryType
  /// 
  /// This replaces the old syncTravelEntries method with type-specific filtering
  Future<SyncResult> syncEntriesByType(EntryType entryType, String userId) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _syncEntriesByTypeInternal(entryType, userId),
        shouldRetry: RetryHelper.shouldRetryNetworkError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      throw appError;
    }
  }

  /// Internal method to sync entries by type to Firestore
  Future<SyncResult> _syncEntriesByTypeInternal(EntryType entryType, String userId) async {
    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Get last sync timestamp for this entry type
      final lastSync = await getLastSyncTimeByType(entryType, userId);
      final cutoffDate = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Upload local entries of specified type to Firestore
      final localEntries = await getEntriesModifiedSince(entryType, cutoffDate);
      for (final entry in localEntries) {
        try {
          // Upload to unified 'entries' collection with Entry.toFirestore()
          await _firestore
              .collection(_entriesCollection)
              .doc('${userId}_${entry.id}')
              .set(entry.toFirestore());
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload entry ${entry.id}: $e');
        }
      }

      // Download entries of specified type from Firestore
      await _downloadEntriesByType(entryType, userId, cutoffDate, (count, errorList) {
        downloadedCount = count;
        errors.addAll(errorList);
      });

      // Update last sync timestamp for this entry type
      await updateLastSyncTimeByType(entryType, userId);

      stopwatch.stop();

      return SyncResult(
        success: errors.isEmpty,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: stopwatch.elapsed,
        errors: errors,
        entryType: entryType,
      );

    } catch (e) {
      stopwatch.stop();
      return SyncResult(
        success: false,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: stopwatch.elapsed,
        errors: [...errors, 'Sync failed: $e'],
        entryType: entryType,
      );
    }
  }

  /// Download entries by type from Firestore using unified Entry model
  /// Only downloads entries where type == specified EntryType
  Future<void> _downloadEntriesByType(
    EntryType entryType, 
    String userId, 
    DateTime lastSync,
    Function(int count, List<String> errors) callback,
  ) async {
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Query unified 'entries' collection filtering by type and user
      final query = _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: entryType.name) // Filter by entry type
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync));

      final snapshot = await query.get();
      final box = await _getEntriesBox();

      for (final doc in snapshot.docs) {
        try {
          // Use Entry.fromFirestore() method for consistent deserialization
          final entry = Entry.fromFirestore(doc);
          
          // Double-check the type matches (safety check)
          if (entry.type == entryType) {
            // Handle conflict resolution
            final existingEntry = box.get(entry.id);
            if (existingEntry != null) {
              // Resolve conflict by choosing the most recently updated entry
              final shouldUpdate = entry.updatedAt != null && 
                  existingEntry.updatedAt != null &&
                  entry.updatedAt!.isAfter(existingEntry.updatedAt!);
              
              if (shouldUpdate) {
                await box.put(entry.id, entry);
                downloadedCount++;
              }
            } else {
              // New entry, add it
              await box.put(entry.id, entry);
              downloadedCount++;
            }
          }
        } catch (e) {
          errors.add('Failed to download entry ${doc.id}: $e');
        }
      }
    } catch (e) {
      errors.add('Failed to query Firestore: $e');
    }

    callback(downloadedCount, errors);
  }

  /// Convenience method to sync only travel entries (maintains backward compatibility)
  Future<SyncResult> syncTravelEntries(String userId) async {
    return await syncEntriesByType(EntryType.travel, userId);
  }

  /// Get entries of specified type modified since a given date
  Future<List<Entry>> getEntriesModifiedSince(EntryType entryType, DateTime lastSync) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Filter entries by type and modification date from unified box
          return box.values
              .where((entry) => 
                  entry.type == entryType &&
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

  /// Get all entries of specified type that need to be synced
  Future<List<Entry>> getEntriesByType(EntryType entryType) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Filter only entries of specified type from unified box
          return box.values
              .where((entry) => entry.type == entryType)
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

  /// Push local entries of specified type to Firestore
  Future<int> pushEntriesByType(EntryType entryType, String userId) async {
    try {
      final entries = await getEntriesByType(entryType);
      int pushedCount = 0;

      for (final entry in entries) {
        try {
          // Push to unified 'entries' collection using Entry.toFirestore()
          await _firestore
              .collection(_entriesCollection)
              .doc('${userId}_${entry.id}')
              .set(entry.toFirestore());
          pushedCount++;
        } catch (e) {
          // Log error but continue with other entries
          print('Failed to push ${entryType.name} entry ${entry.id}: $e');
        }
      }

      return pushedCount;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      throw appError;
    }
  }

  /// Pull entries of specified type from Firestore
  Future<int> pullEntriesByType(EntryType entryType, String userId) async {
    try {
      // Query unified 'entries' collection filtering by type
      final query = _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: entryType.name);

      final snapshot = await query.get();
      final box = await _getEntriesBox();
      int pulledCount = 0;

      for (final doc in snapshot.docs) {
        try {
          // Use Entry.fromFirestore() for consistent deserialization
          final entry = Entry.fromFirestore(doc);
          
          // Double-check it's the correct entry type before storing
          if (entry.type == entryType) {
            await box.put(entry.id, entry);
            pulledCount++;
          }
        } catch (e) {
          // Log error but continue with other entries
          print('Failed to pull ${entryType.name} entry ${doc.id}: $e');
        }
      }

      return pulledCount;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      throw appError;
    }
  }

  /// Get last sync timestamp for entries of a specific type
  Future<DateTime?> getLastSyncTimeByType(EntryType entryType, String userId) async {
    try {
      final settingsBox = await _getSettingsBox();
      final key = '${_syncStatusKey}_${entryType.name}_$userId';
      final timestamp = settingsBox.get(key) as int?;
      
      return timestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Update last sync timestamp for entries of a specific type
  Future<void> updateLastSyncTimeByType(EntryType entryType, String userId) async {
    try {
      final settingsBox = await _getSettingsBox();
      final key = '${_syncStatusKey}_${entryType.name}_$userId';
      await settingsBox.put(key, DateTime.now().millisecondsSinceEpoch);
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Convenience method to get travel entries sync time (maintains backward compatibility)
  Future<DateTime?> getLastSyncTime(String userId) async {
    return await getLastSyncTimeByType(EntryType.travel, userId);
  }

  /// Convenience method to update travel entries sync time (maintains backward compatibility)
  Future<void> updateLastSyncTime(String userId) async {
    await updateLastSyncTimeByType(EntryType.travel, userId);
  }

  /// Check if sync is needed for entries of a specific type
  Future<bool> isSyncNeededByType(EntryType entryType, String userId) async {
    try {
      final lastSync = await getLastSyncTimeByType(entryType, userId);
      if (lastSync == null) return true;

      final modifiedEntries = await getEntriesModifiedSince(entryType, lastSync);
      return modifiedEntries.isNotEmpty;
    } catch (error) {
      // If we can't determine sync status, assume sync is needed
      return true;
    }
  }

  /// Convenience method to check if travel entry sync is needed (maintains backward compatibility)
  Future<bool> isSyncNeeded(String userId) async {
    return await isSyncNeededByType(EntryType.travel, userId);
  }

  /// Delete entry from Firestore unified 'entries' collection
  Future<void> deleteEntryFromFirestore(String userId, String entryId) async {
    try {
      await _firestore
          .collection(_entriesCollection)
          .doc('${userId}_$entryId')
          .delete();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      throw appError;
    }
  }

  /// Batch delete multiple entries from Firestore
  Future<void> batchDeleteEntriesFromFirestore(String userId, List<String> entryIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final entryId in entryIds) {
        final docRef = _firestore
            .collection(_entriesCollection)
            .doc('${userId}_$entryId');
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      throw appError;
    }
  }

  /// Full sync operation for entries of a specific type
  Future<SyncResult> performFullSyncByType(EntryType entryType, String userId) async {
    try {
      // Upload local entries of specified type to Firestore
      final uploadCount = await pushEntriesByType(entryType, userId);
      
      // Download remote entries of specified type from Firestore
      final downloadCount = await pullEntriesByType(entryType, userId);
      
      // Update sync timestamp for this entry type
      await updateLastSyncTimeByType(entryType, userId);

      return SyncResult(
        success: true,
        uploadedCount: uploadCount,
        downloadedCount: downloadCount,
        duration: Duration.zero, // Not tracking duration in this simple version
        errors: [],
        entryType: entryType,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      return SyncResult(
        success: false,
        uploadedCount: 0,
        downloadedCount: 0,
        duration: Duration.zero,
        errors: [appError.message],
        entryType: entryType,
      );
    }
  }

  /// Convenience method for full travel entries sync (maintains backward compatibility)
  Future<SyncResult> performFullSync(String userId) async {
    return await performFullSyncByType(EntryType.travel, userId);
  }

  /// Sync all entry types for a user
  Future<List<SyncResult>> performFullSyncAllTypes(String userId) async {
    final results = <SyncResult>[];
    
    try {
      // Currently only travel entries are implemented
      // In the future, this will sync work entries too
      final travelResult = await performFullSyncByType(EntryType.travel, userId);
      results.add(travelResult);
      
      // TODO: Add work entries sync when work tracking is implemented
      // final workResult = await performFullSyncByType(EntryType.work, userId);
      // results.add(workResult);
      
      return results;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleNetworkError(error, stackTrace);
      results.add(SyncResult(
        success: false,
        uploadedCount: 0,
        downloadedCount: 0,
        duration: Duration.zero,
        errors: [appError.message],
        entryType: EntryType.travel,
      ));
      return results;
    }
  }

  /// Get sync statistics for entries of a specific type
  Future<Map<String, dynamic>> getSyncStatisticsByType(EntryType entryType, String userId) async {
    try {
      final entries = await getEntriesByType(entryType);
      final lastSync = await getLastSyncTimeByType(entryType, userId);
      final needsSync = await isSyncNeededByType(entryType, userId);

      return {
        'entryType': entryType.name,
        'totalEntries': entries.length,
        'lastSyncAt': lastSync?.toIso8601String(),
        'needsSync': needsSync,
        'syncEnabled': true,
      };
    } catch (error) {
      return {
        'entryType': entryType.name,
        'totalEntries': 0,
        'lastSyncAt': null,
        'needsSync': false,
        'syncEnabled': false,
        'error': error.toString(),
      };
    }
  }

  /// Clear all sync data for a specific entry type (for testing or reset purposes)
  Future<void> clearSyncDataByType(EntryType entryType, String userId) async {
    try {
      final settingsBox = await _getSettingsBox();
      final key = '${_syncStatusKey}_${entryType.name}_$userId';
      await settingsBox.delete(key);
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Clear all sync data (for testing or reset purposes)
  Future<void> clearAllSyncData(String userId) async {
    try {
      // Clear sync data for all entry types
      await clearSyncDataByType(EntryType.travel, userId);
      // TODO: Add other entry types when implemented
      // await clearSyncDataByType(EntryType.work, userId);
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }
}

/// Result object for sync operations with entry type information
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final Duration duration;
  final List<String> errors;
  final EntryType entryType;

  const SyncResult({
    required this.success,
    required this.uploadedCount,
    required this.downloadedCount,
    required this.duration,
    required this.errors,
    required this.entryType,
  });

  /// Get total number of entries processed
  int get totalProcessed => uploadedCount + downloadedCount;

  /// Get success rate as percentage
  double get successRate {
    if (totalProcessed == 0) return 100.0;
    final successCount = totalProcessed - errors.length;
    return (successCount / totalProcessed) * 100;
  }

  /// Human-readable summary
  String get summary {
    final typeStr = entryType.name;
    if (success) {
      return 'Sync completed for $typeStr: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inMilliseconds}ms';
    } else {
      return 'Sync completed for $typeStr with ${errors.length} errors: $uploadedCount uploaded, $downloadedCount downloaded';
    }
  }

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'uploadedCount': uploadedCount,
      'downloadedCount': downloadedCount,
      'duration': duration.inMilliseconds,
      'errors': errors,
      'entryType': entryType.name,
      'totalProcessed': totalProcessed,
      'successRate': successRate,
    };
  }

  @override
  String toString() {
    return 'SyncResult(${entryType.name}: success: $success, uploaded: $uploadedCount, downloaded: $downloadedCount, errors: ${errors.length})';
  }
}