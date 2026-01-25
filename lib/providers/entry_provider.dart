import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';
import '../repositories/repository_provider.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_entry_service.dart';

class EntryProvider extends ChangeNotifier {
  final RepositoryProvider _repositoryProvider;
  final SupabaseAuthService _authService;
  final SupabaseEntryService _supabaseService = SupabaseEntryService();

  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  EntryType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  // Hive box for local cache (Entry objects directly)
  static const String _entriesBoxName = 'entries_cache';
  Box<Entry>? _entriesBox;

  EntryProvider(this._repositoryProvider, this._authService);

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
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  EntryType? get selectedType => _selectedType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // PRIMARY: Load from Supabase (cloud storage)
      List<Entry> supabaseEntries = [];
      try {
        // Test connection first
        final connectionOk = await _supabaseService.testConnection();
        if (!connectionOk) {
          debugPrint('EntryProvider: ⚠️ Supabase connection test failed, will use local cache');
        }
        
        debugPrint('EntryProvider: Loading entries from Supabase...');
        supabaseEntries = await _supabaseService.getAllEntries(userId);
        debugPrint('EntryProvider: Loaded ${supabaseEntries.length} entries from Supabase');
        
        // If Supabase is empty, check local cache and sync if needed
        if (supabaseEntries.isEmpty) {
          debugPrint('EntryProvider: Supabase is empty, checking local cache...');
          final localEntries = await _loadFromLocalCache(userId);
          debugPrint('EntryProvider: Found ${localEntries.length} entries in local cache');
          
          if (localEntries.isNotEmpty) {
            debugPrint('EntryProvider: 🔄 Starting sync of ${localEntries.length} local entries to Supabase...');
            int syncedCount = 0;
            int failedCount = 0;
            
            // Sync local entries to Supabase
            for (final entry in localEntries) {
              try {
                debugPrint('EntryProvider: Attempting to sync entry ${entry.id} (${entry.type}) to Supabase...');
                await _supabaseService.addEntry(entry);
                syncedCount++;
                debugPrint('EntryProvider: ✅ Successfully synced entry ${entry.id} to Supabase');
              } catch (e) {
                failedCount++;
                debugPrint('EntryProvider: ❌ Failed to sync entry ${entry.id}: $e');
                debugPrint('EntryProvider: Entry data: ${entry.toJson()}');
                // Continue with other entries even if one fails
              }
            }
            
            debugPrint('EntryProvider: Sync complete - Success: $syncedCount, Failed: $failedCount');
            
            // Reload from Supabase after sync
            if (syncedCount > 0) {
              debugPrint('EntryProvider: Reloading entries from Supabase after sync...');
              supabaseEntries = await _supabaseService.getAllEntries(userId);
              debugPrint('EntryProvider: ✅ Reloaded ${supabaseEntries.length} entries from Supabase after sync');
            } else {
              debugPrint('EntryProvider: ⚠️ No entries were synced, using local cache');
              supabaseEntries = localEntries;
            }
          } else {
            debugPrint('EntryProvider: Local cache is also empty');
          }
        } else {
          // Supabase has entries, but check if local has more (shouldn't happen, but just in case)
          final localEntries = await _loadFromLocalCache(userId);
          if (localEntries.length > supabaseEntries.length) {
            debugPrint('EntryProvider: ⚠️ Local cache has more entries than Supabase, syncing...');
            final supabaseIds = supabaseEntries.map((e) => e.id).toSet();
            final entriesToSync = localEntries.where((e) => !supabaseIds.contains(e.id)).toList();
            
            for (final entry in entriesToSync) {
              try {
                await _supabaseService.addEntry(entry);
                debugPrint('EntryProvider: ✅ Synced missing entry ${entry.id} to Supabase');
              } catch (e) {
                debugPrint('EntryProvider: ❌ Failed to sync entry ${entry.id}: $e');
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
        debugPrint('EntryProvider: Falling back to local cache...');
        
        // FALLBACK: Load from local Hive cache if Supabase fails
        supabaseEntries = await _loadFromLocalCache(userId);
      }

      // Sort by date (most recent first)
      supabaseEntries.sort((a, b) => b.date.compareTo(a.date));

      _entries = supabaseEntries;
      _filteredEntries = List.from(_entries);
      _error = null;
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

      // PRIMARY: Save to Supabase first
      Entry savedEntry;
      
      try {
        debugPrint('EntryProvider: Saving entry to Supabase...');
        debugPrint('EntryProvider: Entry data: ${entry.toJson()}');
        savedEntry = await _supabaseService.addEntry(entry);
        debugPrint('EntryProvider: Entry saved to Supabase successfully with ID: ${savedEntry.id}');
        
        // CACHE: Save to local Hive cache
        await _saveToLocalCache(savedEntry, userId);
        debugPrint('EntryProvider: Entry also saved to local cache');
      } catch (e) {
        debugPrint('EntryProvider: ❌ ERROR saving to Supabase: $e');
        debugPrint('EntryProvider: Entry data that failed: ${entry.toJson()}');
        
        // If Supabase fails, still save locally for offline support
        await _saveToLocalCache(entry, userId);
        savedEntry = entry;
        debugPrint('EntryProvider: ⚠️ Saved to local cache only (offline mode)');
        debugPrint('EntryProvider: Entry will be synced to Supabase on next app load');
      }

      // Add to local list and refresh
      _entries.add(savedEntry);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Added ${savedEntry.type} entry with ID: ${savedEntry.id}');
    } catch (e) {
      debugPrint('EntryProvider: Error adding entry: $e');
      throw Exception('Unable to add entry. Please try again.');
    }
  }

  /// Add multiple entries in a batch (for atomic entries from unified form)
  /// Saves entries sequentially to maintain deterministic ordering
  /// Shows a single success message for the batch
  Future<void> addEntries(List<Entry> entries) async {
    if (entries.isEmpty) return;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('EntryProvider: Adding ${entries.length} entries in batch...');

      final List<Entry> savedEntries = [];
      int successCount = 0;
      int failureCount = 0;

      // Save entries sequentially (deterministic ordering)
      for (final entry in entries) {
        try {
          Entry savedEntry;
          
          try {
            debugPrint('EntryProvider: Saving entry ${entry.type} to Supabase...');
            savedEntry = await _supabaseService.addEntry(entry);
            debugPrint('EntryProvider: Entry saved to Supabase successfully with ID: ${savedEntry.id}');
            
            // CACHE: Save to local Hive cache
            await _saveToLocalCache(savedEntry, userId);
          } catch (e) {
            debugPrint('EntryProvider: ❌ ERROR saving entry to Supabase: $e');
            
            // If Supabase fails, still save locally for offline support
            await _saveToLocalCache(entry, userId);
            savedEntry = entry;
            debugPrint('EntryProvider: ⚠️ Saved to local cache only (offline mode)');
          }

          savedEntries.add(savedEntry);
          successCount++;
        } catch (e) {
          failureCount++;
          debugPrint('EntryProvider: Error adding entry in batch: $e');
          // Continue with other entries even if one fails
        }
      }

      // Add all saved entries to local list
      _entries.addAll(savedEntries);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Batch add complete - Success: $successCount, Failed: $failureCount');
      
      if (failureCount > 0) {
        throw Exception('Some entries failed to save ($failureCount of ${entries.length})');
      }
    } catch (e) {
      debugPrint('EntryProvider: Error adding entries in batch: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(Entry entry) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // PRIMARY: Update in Supabase first
      Entry updatedEntry;
      try {
        debugPrint('EntryProvider: Updating entry in Supabase...');
        updatedEntry = await _supabaseService.updateEntry(entry);
        debugPrint('EntryProvider: Entry updated in Supabase successfully');
        
        // CACHE: Update in local Hive cache
        await _updateInLocalCache(updatedEntry, userId);
      } catch (e) {
        debugPrint('EntryProvider: Error updating in Supabase: $e');
        // If Supabase fails, still update locally for offline support
        await _updateInLocalCache(entry, userId);
        updatedEntry = entry;
        // Don't throw - allow offline usage
        debugPrint('EntryProvider: Updated in local cache only (offline mode)');
      }

      // Update local list
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _entries[index] = updatedEntry;
        _applyFilters();
        notifyListeners();
      }

      debugPrint(
          'EntryProvider: Updated ${updatedEntry.type} entry with ID: ${updatedEntry.id}');
    } catch (e) {
      debugPrint('EntryProvider: Error updating entry: $e');
      throw Exception('Unable to update entry. Please try again.');
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

      // PRIMARY: Delete from Supabase first
      try {
        debugPrint('EntryProvider: Deleting entry from Supabase...');
        await _supabaseService.deleteEntry(id, userId);
        debugPrint('EntryProvider: Entry deleted from Supabase successfully');
        
        // CACHE: Delete from local Hive cache
        await _deleteFromLocalCache(entry, userId);
      } catch (e) {
        debugPrint('EntryProvider: Error deleting from Supabase: $e');
        // If Supabase fails, still delete locally for offline support
        await _deleteFromLocalCache(entry, userId);
        // Don't throw - allow offline usage
        debugPrint('EntryProvider: Deleted from local cache only (offline mode)');
      }

      // Remove from local list
      _entries.removeWhere((e) => e.id == id);
      _applyFilters();
      notifyListeners();

      debugPrint('EntryProvider: Deleted ${entry.type} entry with ID: $id');
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
    _filteredEntries = _entries.where((entry) {
      // Type filter
      if (_selectedType != null && entry.type != _selectedType) {
        return false;
      }

      // Date range filter
      if (_startDate != null && entry.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.date.isAfter(_endDate!)) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            entry.notes?.toLowerCase().contains(query) == true ||
                (entry.type == EntryType.travel &&
                    ((entry.from?.toLowerCase().contains(query) == true) ||
                        (entry.to?.toLowerCase().contains(query) == true)));

        if (!matchesSearch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _startDate = null;
    _endDate = null;
    _filteredEntries = _entries;
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
      final demoEntries = _entries.where((entry) => entry.id.startsWith('sample_')).toList();
      debugPrint('EntryProvider: Found ${demoEntries.length} demo entries to delete');

      for (final entry in demoEntries) {
        try {
          // Delete from Supabase first
          await _supabaseService.deleteEntry(entry.id, userId);
          debugPrint('EntryProvider: Deleted ${entry.id} from Supabase');
          
          // Then delete from local cache
          if (entry.type == EntryType.travel) {
            final travelRepo = _repositoryProvider.travelRepository;
            if (travelRepo != null) {
              await travelRepo.delete(entry.id);
            }
          } else if (entry.type == EntryType.work) {
            final workRepo = _repositoryProvider.workRepository;
            if (workRepo != null) {
              await workRepo.delete(entry.id);
            }
          }
        } catch (e) {
          debugPrint('Failed to delete demo entry ${entry.id}: $e');
          // Continue with other entries even if one fails
        }
      }

      // Remove from local list
      _entries.removeWhere((entry) => entry.id.startsWith('sample_'));
      _filteredEntries = List.from(_entries);
      _error = null;

      notifyListeners();
      debugPrint('EntryProvider: Cleared demo entries (${demoEntries.length} entries)');
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
      debugPrint('EntryProvider: Deleting ${allEntries.length} entries from Supabase and local cache');

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
      debugPrint('EntryProvider: Cleared all entries (${allEntries.length} entries)');
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
  /// Stores Entry objects directly in Hive (no conversion to TravelEntry/WorkEntry)
  Future<void> _syncToLocalCache(List<Entry> entries, String userId) async {
    try {
      await _initEntriesBox();
      if (_entriesBox == null) {
        debugPrint('EntryProvider: Entries box not available, skipping cache sync');
        return;
      }

      for (final entry in entries) {
        // Store Entry directly in Hive (preserves all fields: shifts, unpaid breaks, notes, travel legs, etc.)
        await _entriesBox!.put(entry.id, entry);
      }
      debugPrint('EntryProvider: Synced ${entries.length} entries to local cache');
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
        debugPrint('EntryProvider: Entries box not available, returning empty list');
        return [];
      }

      // Load all entries from Hive and filter by userId
      final allEntries = _entriesBox!.values
          .where((entry) => entry.userId == userId)
          .toList();

      debugPrint('EntryProvider: Loaded ${allEntries.length} entries from local cache');
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
        debugPrint('EntryProvider: Entries box not available, skipping cache save');
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
        debugPrint('EntryProvider: Entries box not available, skipping cache update');
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
        debugPrint('EntryProvider: Entries box not available, skipping cache delete');
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

      debugPrint('EntryProvider: Starting sync of local entries to Supabase...');

      // Load entries from local cache
      final localEntries = await _loadFromLocalCache(userId);
      debugPrint('EntryProvider: Found ${localEntries.length} local entries to sync');

      if (localEntries.isEmpty) {
        debugPrint('EntryProvider: No local entries to sync');
        return;
      }

      // Get existing entries from Supabase to avoid duplicates
      List<Entry> supabaseEntries = [];
      try {
        supabaseEntries = await _supabaseService.getAllEntries(userId);
        debugPrint('EntryProvider: Found ${supabaseEntries.length} existing entries in Supabase');
      } catch (e) {
        debugPrint('EntryProvider: Error fetching from Supabase (will sync all local entries): $e');
      }

      final supabaseIds = supabaseEntries.map((e) => e.id).toSet();
      int syncedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      // Sync each local entry that doesn't exist in Supabase
      for (final entry in localEntries) {
        if (supabaseIds.contains(entry.id)) {
          debugPrint('EntryProvider: Entry ${entry.id} already exists in Supabase, skipping');
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

      debugPrint('EntryProvider: Sync complete - Synced: $syncedCount, Skipped: $skippedCount, Errors: $errorCount');

      // Reload entries after sync
      await loadEntries();
    } catch (e) {
      debugPrint('EntryProvider: Error syncing local entries to Supabase: $e');
      rethrow;
    }
  }
}
