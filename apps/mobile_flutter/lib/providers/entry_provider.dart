// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_entry_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/entry_filter.dart' as entry_filter_utils;
import '../utils/entry_filter_spec.dart';
import '../utils/retry_helper.dart';

/// Conflict resolution strategy when server and local have different versions
enum ConflictStrategy {
  serverWins, // Always use server version (default - safest for data integrity)
  localWins, // Always use local version
  newerWins, // Use whichever has a more recent updatedAt timestamp
}

class EntryProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  final SupabaseEntryService _supabaseService;
  final SyncQueueService _syncQueue;
  String? _activeUserId;

  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _syncError;
  String _searchQuery = '';
  EntryType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  // Track offline operations count
  int _pendingOfflineOperations = 0;

  // Hive box for local cache (Entry objects directly)
  static const String _entriesBoxName = 'entries_cache';
  Box<Entry>? _entriesBox;
  Future<void>? _activeLoadEntriesFuture;

  late final Future<void> _syncQueueReady;

  EntryProvider(
    this._authService, {
    SupabaseEntryService? supabaseService,
    SyncQueueService? syncQueue,
  })  : _supabaseService = supabaseService ?? SupabaseEntryService(),
        _syncQueue = syncQueue ?? SyncQueueService() {
    _activeUserId = _authService.currentUser?.id;
    _syncQueueReady = _syncQueue.init();
  }

  /// Ensure sync queue is initialized before use
  Future<void> _ensureSyncQueueReady() async {
    await _syncQueueReady;
  }

  /// Initialize the Hive box for local cache
  Future<void> _initEntriesBox() async {
    if (_entriesBox != null && _entriesBox!.isOpen) return;
    try {
      _entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
    } catch (e) {
      debugPrint('EntryProvider: Error opening entries box: $e');
      // Box might not be registered, but that's okay - we'll handle it gracefully
    }
  }

  List<Entry> get entries => _entries;
  List<Entry> get filteredEntries => _filteredEntries;
  bool get hasAnyEntries => _entries.isNotEmpty;
  DateTime? get earliestEntryDate {
    if (_entries.isEmpty) return null;
    DateTime? earliest;
    for (final entry in _entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (earliest == null || date.isBefore(earliest)) {
        earliest = date;
      }
    }
    return earliest;
  }

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncError => _syncError;
  String get searchQuery => _searchQuery;
  EntryType? get selectedType => _selectedType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get pendingOfflineOperations => _pendingOfflineOperations;
  bool get hasPendingSync {
    final userId = _authService.currentUser?.id;
    if (userId == null) return false;
    return _syncQueue.pendingCountForUser(userId) > 0;
  }

  int get pendingSyncCount {
    final userId = _authService.currentUser?.id;
    if (userId == null) return 0;
    return _syncQueue.pendingCountForUser(userId);
  }

  /// Handle auth user switches to avoid cross-account in-memory leakage.
  Future<void> handleAuthUserChanged({
    required String? previousUserId,
    required String? currentUserId,
  }) async {
    if (_activeUserId == currentUserId) return;
    _activeUserId = currentUserId;

    _entries = [];
    _filteredEntries = [];
    _searchQuery = '';
    _selectedType = null;
    _startDate = null;
    _endDate = null;
    _error = null;
    _syncError = null;
    _isLoading = false;
    _isSyncing = false;
    _pendingOfflineOperations = 0;
    notifyListeners();

    await _ensureSyncQueueReady();

    if (currentUserId == null) {
      // No active user: remove prior user's pending queue operations.
      if (previousUserId != null) {
        await _syncQueue.clearForUser(previousUserId);
      }
      return;
    }

    // Keep only current user's pending queue operations.
    await _syncQueue.clearAllExceptUser(currentUserId);
    _pendingOfflineOperations = _syncQueue.pendingCountForUser(currentUserId);
    await loadEntries();
  }

  Future<void> loadEntries() {
    final inFlight = _activeLoadEntriesFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadEntriesInternal();
    _activeLoadEntriesFuture = future.whenComplete(() {
      _activeLoadEntriesFuture = null;
    });
    return _activeLoadEntriesFuture!;
  }

  Future<void> _loadEntriesInternal() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        _entries = [];
        _filteredEntries = [];
        _pendingOfflineOperations = 0;
        return;
      }

      // Fast-path: show locally cached entries immediately while cloud sync runs.
      final localEntries = await _loadFromLocalCache(userId);
      if (localEntries.isNotEmpty) {
        localEntries.sort((a, b) => b.date.compareTo(a.date));
        _entries = localEntries;
        _filteredEntries = List.from(_entries);
        _error = null;
        _pendingOfflineOperations = _syncQueue.pendingCountForUser(userId);
        notifyListeners();
      }

      // PRIMARY: Load from Supabase (cloud storage)
      List<Entry> supabaseEntries = [];
      try {
        debugPrint('EntryProvider: Loading entries from Supabase...');
        supabaseEntries = await _supabaseService.getAllEntries(userId);
        debugPrint(
            'EntryProvider: Loaded ${supabaseEntries.length} entries from Supabase');

        // If Supabase is empty, check local cache and sync if needed
        if (supabaseEntries.isEmpty) {
          debugPrint(
              'EntryProvider: Supabase is empty, checking local cache...');
          debugPrint(
              'EntryProvider: Found ${localEntries.length} entries in local cache');

          if (localEntries.isNotEmpty) {
            debugPrint(
                'EntryProvider: Starting sync of ${localEntries.length} local entries to Supabase...');
            int syncedCount = 0;
            int failedCount = 0;

            // Sync local entries to Supabase
            for (final entry in localEntries) {
              try {
                debugPrint(
                    'EntryProvider: Attempting to sync entry ${entry.id} (${entry.type}) to Supabase...');
                await _supabaseService.addEntry(entry);
                syncedCount++;
                debugPrint(
                    'EntryProvider: Successfully synced entry ${entry.id} to Supabase');
              } catch (e) {
                failedCount++;
                debugPrint(
                    'EntryProvider: Failed to sync entry ${entry.id}: $e');
                // Continue with other entries even if one fails
              }
            }

            debugPrint(
                'EntryProvider: Sync complete - Success: $syncedCount, Failed: $failedCount');

            // Reload from Supabase after sync
            if (syncedCount > 0) {
              debugPrint(
                  'EntryProvider: Reloading entries from Supabase after sync...');
              supabaseEntries = await _supabaseService.getAllEntries(userId);
              debugPrint(
                  'EntryProvider: Reloaded ${supabaseEntries.length} entries from Supabase after sync');
            } else {
              debugPrint(
                  'EntryProvider: No entries were synced, using local cache');
              supabaseEntries = localEntries;
            }
          } else {
            debugPrint('EntryProvider: Local cache is also empty');
          }
        } else {
          // Supabase has entries, but check if local has more (should not happen)
          if (localEntries.length > supabaseEntries.length) {
            debugPrint(
                'EntryProvider: Local cache has more entries than Supabase, syncing...');
            final supabaseIds = supabaseEntries.map((e) => e.id).toSet();
            final entriesToSync =
                localEntries.where((e) => !supabaseIds.contains(e.id)).toList();

            for (final entry in entriesToSync) {
              try {
                await _supabaseService.addEntry(entry);
                debugPrint(
                    'EntryProvider: Synced missing entry ${entry.id} to Supabase');
              } catch (e) {
                debugPrint(
                    'EntryProvider: Failed to sync entry ${entry.id}: $e');
              }
            }

            // Reload from Supabase
            supabaseEntries = await _supabaseService.getAllEntries(userId);
          }
        }

        // Sync to local Hive cache
        await _syncToLocalCache(supabaseEntries, userId);
      } catch (e) {
        debugPrint('EntryProvider: Error loading from Supabase: $e');
        if (localEntries.isEmpty) {
          _entries = [];
          _filteredEntries = [];
          _error = 'Unable to load entries. Please try again.';
        } else {
          // Keep local data visible when cloud load fails.
          _error = null;
        }
        _pendingOfflineOperations = _syncQueue.pendingCountForUser(userId);
        return;
      }

      // Sort by date (most recent first)
      supabaseEntries.sort((a, b) => b.date.compareTo(a.date));

      _entries = supabaseEntries;
      _filteredEntries = List.from(_entries);
      _error = null;
      _pendingOfflineOperations = _syncQueue.pendingCountForUser(userId);
    } catch (e) {
      debugPrint('Error loading entries: $e');
      _error = 'Unable to load entries. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(Entry entry) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure entry has updatedAt for conflict resolution
      final entryWithTimestamp = entry.updatedAt == null
          ? entry.copyWith(updatedAt: DateTime.now())
          : entry;

      // PRIMARY: Save to Supabase first with retry
      Entry savedEntry;
      bool savedToServer = false;

      try {
        debugPrint('EntryProvider: Saving entry to Supabase...');
        savedEntry = await RetryHelper.executeWithRetry(
          () => _supabaseService.addEntry(entryWithTimestamp),
          maxRetries: 2,
          shouldRetry: RetryHelper.shouldRetryNetworkError,
        );
        savedToServer = true;
        debugPrint(
            'EntryProvider: Entry saved to Supabase successfully with ID: ${savedEntry.id}');

        // CACHE: Save to local Hive cache
        await _saveToLocalCache(savedEntry, userId);
        debugPrint('EntryProvider: Entry also saved to local cache');
      } catch (e) {
        debugPrint('EntryProvider: ❌ ERROR saving to Supabase: $e');

        // If Supabase fails, save locally and queue for sync
        await _saveToLocalCache(entryWithTimestamp, userId);
        savedEntry = entryWithTimestamp;
        _pendingOfflineOperations++;

        // Queue for later sync (ensure queue is ready first)
        await _ensureSyncQueueReady();
        await _syncQueue.queueCreate(entryWithTimestamp, userId);

        debugPrint(
            'EntryProvider: ⚠️ Saved to local cache only (offline mode)');
        debugPrint('EntryProvider: Entry queued for sync when online');
      }

      // Add to local list and refresh
      _entries.add(savedEntry);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Added ${savedEntry.type} entry with ID: ${savedEntry.id} (server: $savedToServer)');
    } catch (e) {
      debugPrint('EntryProvider: Error adding entry: $e');
      throw Exception('Unable to add entry. Please try again.');
    }
  }

  /// Add multiple entries in a batch (for atomic entries from unified form)
  /// Saves entries sequentially with all-or-fail semantics.
  /// If one insert fails after partial remote success, attempts rollback.
  Future<void> addEntries(List<Entry> entries) async {
    if (entries.isEmpty) return;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('EntryProvider: Adding ${entries.length} entries in batch...');

      final List<Entry> savedEntries = [];
      final List<String> createdRemoteIds = [];

      // Save entries sequentially (deterministic ordering).
      // Do not persist local cache incrementally.
      for (final entry in entries) {
        final entryWithTimestamp = entry.updatedAt == null
            ? entry.copyWith(updatedAt: DateTime.now())
            : entry;

        try {
          debugPrint(
              'EntryProvider: Saving entry ${entry.type} to Supabase...');
          final savedEntry =
              await _supabaseService.addEntry(entryWithTimestamp);
          debugPrint(
              'EntryProvider: Entry saved to Supabase successfully with ID: ${savedEntry.id}');
          savedEntries.add(savedEntry);
          if (savedEntry.id.isNotEmpty) {
            createdRemoteIds.add(savedEntry.id);
          }
        } catch (insertError) {
          debugPrint('EntryProvider: Batch insert failed: $insertError');
          debugPrint(
              'EntryProvider: Attempting rollback for ${createdRemoteIds.length} created entries...');

          int rollbackFailures = 0;
          for (final createdId in createdRemoteIds) {
            try {
              await _supabaseService.deleteEntry(createdId, userId);
            } catch (rollbackError) {
              rollbackFailures++;
              debugPrint(
                  'EntryProvider: Rollback delete failed for $createdId: $rollbackError');
            }
          }

          if (rollbackFailures > 0) {
            throw Exception(
                'Unable to save batch entries. Save failed and rollback was attempted, but some parts may still be saved remotely.');
          }
          throw Exception(
              'Unable to save batch entries. Save failed and rollback was attempted.');
        }
      }

      // Cache and in-memory updates happen only after all remote inserts succeed.
      for (final savedEntry in savedEntries) {
        await _saveToLocalCache(savedEntry, userId);
      }
      _entries.addAll(savedEntries);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Batch add complete - Success: ${savedEntries.length}');
    } catch (e) {
      debugPrint('EntryProvider: Error adding entries in batch: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(Entry entry,
      {ConflictStrategy conflictStrategy = ConflictStrategy.newerWins}) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update timestamp for conflict resolution
      final entryWithTimestamp = entry.copyWith(updatedAt: DateTime.now());

      // PRIMARY: Update in Supabase first with retry
      Entry updatedEntry;
      bool savedToServer = false;

      try {
        debugPrint('EntryProvider: Updating entry in Supabase...');

        // Check for conflicts if using newerWins strategy
        if (conflictStrategy == ConflictStrategy.newerWins) {
          final serverEntry = await RetryHelper.simpleRetry(
            () => _supabaseService.getEntryById(entry.id, userId),
          );

          if (serverEntry != null &&
              serverEntry.updatedAt != null &&
              entry.updatedAt != null) {
            if (serverEntry.updatedAt!.isAfter(entry.updatedAt!)) {
              debugPrint(
                  'EntryProvider: ⚠️ Server has newer version, using server version');
              updatedEntry = serverEntry;
              await _updateInLocalCache(updatedEntry, userId);
              _updateLocalList(updatedEntry);
              return;
            }
          }
        }

        updatedEntry = await RetryHelper.executeWithRetry(
          () => _supabaseService.updateEntry(entryWithTimestamp),
          maxRetries: 2,
          shouldRetry: RetryHelper.shouldRetryNetworkError,
        );
        savedToServer = true;
        debugPrint('EntryProvider: Entry updated in Supabase successfully');

        // CACHE: Update in local Hive cache
        await _updateInLocalCache(updatedEntry, userId);
      } catch (e) {
        debugPrint('EntryProvider: Error updating in Supabase: $e');

        // If Supabase fails, update locally and queue for sync
        await _updateInLocalCache(entryWithTimestamp, userId);
        updatedEntry = entryWithTimestamp;
        _pendingOfflineOperations++;

        // Queue for later sync (ensure queue is ready first)
        await _ensureSyncQueueReady();
        await _syncQueue.queueUpdate(entryWithTimestamp, userId);

        debugPrint('EntryProvider: Updated in local cache only (offline mode)');
        debugPrint('EntryProvider: Update queued for sync when online');
      }

      _updateLocalList(updatedEntry);

      debugPrint(
          'EntryProvider: Updated ${updatedEntry.type} entry with ID: ${updatedEntry.id} (server: $savedToServer)');
    } catch (e) {
      debugPrint('EntryProvider: Error updating entry: $e');
      throw Exception('Unable to update entry. Please try again.');
    }
  }

  void _updateLocalList(Entry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find entry to get type
      Entry? entry;
      try {
        entry = _entries.firstWhere((e) => e.id == id);
      } catch (_) {
        entry = null;
      }

      if (entry == null) {
        throw Exception('Entry not found');
      }

      // PRIMARY: Delete from Supabase first with retry
      bool deletedFromServer = false;
      try {
        debugPrint('EntryProvider: Deleting entry from Supabase...');
        await RetryHelper.executeWithRetry(
          () => _supabaseService.deleteEntry(id, userId),
          maxRetries: 2,
          shouldRetry: RetryHelper.shouldRetryNetworkError,
        );
        deletedFromServer = true;
        debugPrint('EntryProvider: Entry deleted from Supabase successfully');

        // CACHE: Delete from local Hive cache
        await _deleteFromLocalCache(entry, userId);
      } catch (e) {
        debugPrint('EntryProvider: Error deleting from Supabase: $e');

        // If Supabase fails, delete locally and queue for sync
        await _deleteFromLocalCache(entry, userId);
        _pendingOfflineOperations++;

        // Queue for later sync (ensure queue is ready first)
        await _ensureSyncQueueReady();
        await _syncQueue.queueDelete(id, userId);

        debugPrint(
            'EntryProvider: Deleted from local cache only (offline mode)');
        debugPrint('EntryProvider: Delete queued for sync when online');
      }

      // Remove from local list
      _entries.removeWhere((e) => e.id == id);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Deleted ${entry.type} entry with ID: $id (server: $deletedFromServer)');
    } catch (e) {
      debugPrint('EntryProvider: Error deleting entry: $e');
      throw Exception('Unable to delete entry. Please try again.');
    }
  }

  void filterEntries({
    String? searchQuery,
    EntryType? selectedType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _searchQuery = searchQuery ?? _searchQuery;
    _selectedType = selectedType ?? _selectedType;
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;

    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final spec = EntryFilterSpec(
      startDate: _startDate,
      endDate: _endDate,
      selectedType: _selectedType,
      searchQuery: _searchQuery,
    );
    _filteredEntries = entry_filter_utils.EntryFilter.filterEntries(
      _entries,
      spec,
    );
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _startDate = null;
    _endDate = null;
    _filteredEntries = List.from(_entries);
    notifyListeners();
  }

  List<Entry> getRecentEntries({int limit = 10}) {
    final sortedEntries = List<Entry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.take(limit).toList();
  }

  // Clear demo/sample entries only
  Future<void> clearDemoEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find and delete demo entries (those with IDs starting with 'sample_')
      final demoEntries =
          _entries.where((entry) => entry.id.startsWith('sample_')).toList();
      debugPrint(
          'EntryProvider: Found ${demoEntries.length} demo entries to delete');

      for (final entry in demoEntries) {
        try {
          await deleteEntry(entry.id);
        } catch (e) {
          debugPrint('Failed to delete demo entry ${entry.id}: $e');
          // Continue with other entries even if one fails
        }
      }

      // deleteEntry() already removes each entry from _entries,
      // so just refresh the filtered list.
      _filteredEntries = List.from(_entries);
      _error = null;

      notifyListeners();
      debugPrint(
          'EntryProvider: Cleared demo entries (${demoEntries.length} entries)');
    } catch (e) {
      _error = 'Failed to clear demo entries: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all entries
  Future<void> clearAllEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all current entries to delete them
      final allEntries = List<Entry>.from(_entries);
      debugPrint(
          'EntryProvider: Deleting ${allEntries.length} entries from Supabase and local cache');

      // Delete entries from Supabase and local cache
      for (final entry in allEntries) {
        try {
          // Delete from Supabase first
          await _supabaseService.deleteEntry(entry.id, userId);
          debugPrint('EntryProvider: Deleted ${entry.id} from Supabase');

          // Then delete from local cache (Entry directly)
          await _deleteFromLocalCache(entry, userId);
        } catch (e) {
          debugPrint('Failed to delete entry ${entry.id}: $e');
          // Continue with other entries even if one fails
        }
      }

      // Clear local entries after successful deletion
      _entries = [];
      _filteredEntries = [];
      _error = null;

      notifyListeners();
      debugPrint(
          'EntryProvider: Cleared all entries (${allEntries.length} entries)');
    } catch (e) {
      _error = 'Failed to clear entries: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for local cache sync

  /// Sync entries from Supabase to local Hive cache
  /// Stores Entry objects directly in Hive (no legacy model conversion)
  /// Also removes stale entries that no longer exist on the server
  Future<void> _syncToLocalCache(List<Entry> entries, String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint(
            'EntryProvider: Entries box not available, skipping cache sync');
        return;
      }
      await _ensureSyncQueueReady();

      // Build set of cloud entry IDs for stale-detection
      final cloudIds = entries.map((e) => e.id).toSet();

      for (final entry in entries) {
        // Store Entry directly in Hive (preserves all fields: shifts, unpaid breaks, notes, travel legs, etc.)
        await _entriesBox!.put(entry.id, entry);
      }

      final hasPendingQueueOps = _syncQueue.pendingCountForUser(userId) > 0;
      if (hasPendingQueueOps) {
        debugPrint(
            'EntryProvider: Pending sync operations detected, skipping stale cache deletions to avoid offline data loss');
        debugPrint(
            'EntryProvider: Synced ${entries.length} entries to local cache');
        return;
      }

      // Remove stale Hive entries that no longer exist on the server
      final allCachedKeys = _entriesBox!.keys.toList();
      for (final key in allCachedKeys) {
        if (!cloudIds.contains(key)) {
          final cachedEntry = _entriesBox!.get(key);
          if (cachedEntry != null && cachedEntry.userId == userId) {
            await _entriesBox!.delete(key);
            debugPrint('EntryProvider: Removed stale cache entry: $key');
          }
        }
      }

      debugPrint(
          'EntryProvider: Synced ${entries.length} entries to local cache');
    } catch (e) {
      debugPrint('EntryProvider: Error syncing to local cache: $e');
      // Don't throw - cache sync failure shouldn't break the app
    }
  }

  /// Load entries from local Hive cache (fallback when Supabase is unavailable)
  /// Loads Entry objects directly from Hive (preserves all fields)
  Future<List<Entry>> _loadFromLocalCache(String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint(
            'EntryProvider: Entries box not available, returning empty list');
        return [];
      }

      // Load all entries from Hive and filter by userId
      final allEntries =
          _entriesBox!.values.where((entry) => entry.userId == userId).toList();

      debugPrint(
          'EntryProvider: Loaded ${allEntries.length} entries from local cache');
      return allEntries;
    } catch (e) {
      debugPrint('EntryProvider: Error loading from local cache: $e');
      return [];
    }
  }

  /// Save a single entry to local Hive cache
  /// Stores Entry object directly (preserves all fields: shifts, unpaid breaks, notes, travel legs, etc.)
  Future<void> _saveToLocalCache(Entry entry, String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint(
            'EntryProvider: Entries box not available, skipping cache save');
        return;
      }

      // Store Entry directly in Hive
      await _entriesBox!.put(entry.id, entry);
      debugPrint('EntryProvider: Saved entry ${entry.id} to local cache');
    } catch (e) {
      debugPrint('EntryProvider: Error saving to local cache: $e');
      // Don't throw - cache save failure shouldn't break the app
    }
  }

  /// Update a single entry in local Hive cache
  /// Stores Entry object directly (preserves all fields)
  Future<void> _updateInLocalCache(Entry entry, String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint(
            'EntryProvider: Entries box not available, skipping cache update');
        return;
      }

      // Update Entry directly in Hive
      await _entriesBox!.put(entry.id, entry);
      debugPrint('EntryProvider: Updated entry ${entry.id} in local cache');
    } catch (e) {
      debugPrint('EntryProvider: Error updating in local cache: $e');
      // Don't throw - cache update failure shouldn't break the app
    }
  }

  /// Delete a single entry from local Hive cache
  /// Deletes Entry object directly from Hive
  Future<void> _deleteFromLocalCache(Entry entry, String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint(
            'EntryProvider: Entries box not available, skipping cache delete');
        return;
      }

      // Delete Entry directly from Hive
      await _entriesBox!.delete(entry.id);
      debugPrint('EntryProvider: Deleted entry ${entry.id} from local cache');
    } catch (e) {
      debugPrint('EntryProvider: Error deleting from local cache: $e');
      // Don't throw - cache delete failure shouldn't break the app
    }
  }

  /// Sync local entries to Supabase (useful for migrating local data to cloud)
  Future<void> syncLocalEntriesToSupabase() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint(
          'EntryProvider: Starting sync of local entries to Supabase...');

      // Load entries from local cache
      final localEntries = await _loadFromLocalCache(userId);
      debugPrint(
          'EntryProvider: Found ${localEntries.length} local entries to sync');

      if (localEntries.isEmpty) {
        debugPrint('EntryProvider: No local entries to sync');
        return;
      }

      // Get existing entries from Supabase to avoid duplicates
      List<Entry> supabaseEntries = [];
      try {
        supabaseEntries = await _supabaseService.getAllEntries(userId);
        debugPrint(
            'EntryProvider: Found ${supabaseEntries.length} existing entries in Supabase');
      } catch (e) {
        debugPrint(
            'EntryProvider: Error fetching from Supabase (will sync all local entries): $e');
      }

      final supabaseIds = supabaseEntries.map((e) => e.id).toSet();
      int syncedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      // Sync each local entry that doesn't exist in Supabase
      for (final entry in localEntries) {
        if (supabaseIds.contains(entry.id)) {
          debugPrint(
              'EntryProvider: Entry ${entry.id} already exists in Supabase, skipping');
          skippedCount++;
          continue;
        }

        try {
          await _supabaseService.addEntry(entry);
          syncedCount++;
          debugPrint('EntryProvider: Synced entry ${entry.id} to Supabase');
        } catch (e) {
          errorCount++;
          debugPrint('EntryProvider: Error syncing entry ${entry.id}: $e');
        }
      }

      debugPrint(
          'EntryProvider: Sync complete - Synced: $syncedCount, Skipped: $skippedCount, Errors: $errorCount');

      // Reload entries after sync
      await loadEntries();
    } catch (e) {
      debugPrint('EntryProvider: Error syncing local entries to Supabase: $e');
      rethrow;
    }
  }

  /// Process any queued offline operations
  /// Call this when connectivity is restored
  Future<SyncResult> processPendingSync() async {
    if (_isSyncing) {
      debugPrint('EntryProvider: Already syncing, skipping');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      debugPrint('EntryProvider: No user logged in, cannot sync');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      // Ensure sync queue is initialized before processing
      await _ensureSyncQueueReady();

      debugPrint(
          'EntryProvider: Processing ${_syncQueue.pendingCountForUser(userId)} pending sync operations...');

      final result = await _syncQueue.processQueue((operation) async {
        switch (operation.type) {
          case SyncOperationType.create:
            if (operation.entryData != null) {
              final entry = Entry.fromJson(operation.entryData!);
              await _supabaseService.addEntry(entry);
            }
            break;
          case SyncOperationType.update:
            if (operation.entryData != null) {
              final entry = Entry.fromJson(operation.entryData!);
              await _supabaseService.updateEntry(entry);
            }
            break;
          case SyncOperationType.delete:
            await _supabaseService.deleteEntry(
                operation.entryId, operation.userId);
            break;
          case SyncOperationType.absenceCreate:
          case SyncOperationType.absenceUpdate:
          case SyncOperationType.absenceDelete:
          case SyncOperationType.adjustmentCreate:
          case SyncOperationType.adjustmentUpdate:
          case SyncOperationType.adjustmentDelete:
          case SyncOperationType.contractUpdate:
            return;
        }
      }, userId: userId, operationTypes: SyncQueueService.entryOperationTypes);

      _pendingOfflineOperations = _syncQueue.pendingCountForUser(userId);
      if (result.succeeded > 0) {
        debugPrint(
            'EntryProvider: Sync complete - ${result.succeeded}/${result.processed} succeeded');
      }

      if (result.hasFailures) {
        _syncError =
            'Some items failed to sync (${result.failed} of ${result.processed})';
      }

      return result;
    } catch (e) {
      debugPrint('EntryProvider: Error processing sync queue: $e');
      _syncError = 'Sync failed: $e';
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear sync error message
  void clearSyncError() {
    _syncError = null;
    notifyListeners();
  }

  /// Check if there's a sync in progress
  bool get isSyncInProgress => _isSyncing;
}
