import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../repositories/repository_provider.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
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

  EntryProvider(this._repositoryProvider, this._authService);

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

      // Check if repositories are initialized
      if (_repositoryProvider.currentUserId != userId) {
        debugPrint('EntryProvider: Repositories not initialized for user $userId, skipping load');
        _entries = [];
        _filteredEntries = [];
        _error = null;
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

      for (final entry in demoEntries) {
        try {
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

      // Get all current entries to delete them from repositories
      final allEntries = List<Entry>.from(_entries);

      // Delete entries from repositories
      for (final entry in allEntries) {
        try {
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
          debugPrint('Failed to delete entry ${entry.id}: $e');
          // Continue with other entries even if one fails
        }
      }

      // Clear local entries after successful repository deletion
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
  Future<void> _syncToLocalCache(List<Entry> entries, String userId) async {
    try {
      final travelRepo = _repositoryProvider.travelRepository;
      final workRepo = _repositoryProvider.workRepository;

      for (final entry in entries) {
        if (entry.type == EntryType.travel) {
          if (travelRepo != null) {
            final travelEntry = TravelEntry(
              id: entry.id,
              userId: entry.userId,
              fromLocation: entry.from ?? '',
              toLocation: entry.to ?? '',
              travelMinutes: entry.travelMinutes ?? 0,
              date: entry.date,
              remarks: entry.notes ?? '',
              createdAt: entry.createdAt,
              updatedAt: entry.updatedAt,
            );
            // Check if exists, update if yes, add if no
            final existing = travelRepo.getById(entry.id);
            if (existing != null) {
              await travelRepo.update(travelEntry);
            } else {
              await travelRepo.add(travelEntry);
            }
          }
        } else if (entry.type == EntryType.work) {
          if (workRepo != null) {
            final workMinutes = entry.shifts?.fold<int>(
                    0, (sum, shift) => sum + shift.duration.inMinutes) ??
                0;
            final workEntry = WorkEntry(
              id: entry.id,
              userId: entry.userId,
              workMinutes: workMinutes,
              date: entry.date,
              remarks: entry.notes ?? '',
              createdAt: entry.createdAt,
              updatedAt: entry.updatedAt,
            );
            // Check if exists, update if yes, add if no
            final existing = workRepo.getById(entry.id);
            if (existing != null) {
              await workRepo.update(workEntry);
            } else {
              await workRepo.add(workEntry);
            }
          }
        }
      }
      debugPrint('EntryProvider: Synced ${entries.length} entries to local cache');
    } catch (e) {
      debugPrint('EntryProvider: Error syncing to local cache: $e');
      // Don't throw - cache sync failure shouldn't break the app
    }
  }

  /// Load entries from local Hive cache (fallback when Supabase is unavailable)
  Future<List<Entry>> _loadFromLocalCache(String userId) async {
    try {
      final travelRepo = _repositoryProvider.travelRepository;
      final workRepo = _repositoryProvider.workRepository;

      final List<Entry> entries = [];

      // Load travel entries
      if (travelRepo != null) {
        final travelEntries = travelRepo.getAllForUser(userId);
        for (final travelEntry in travelEntries) {
          entries.add(Entry(
            id: travelEntry.id,
            userId: travelEntry.userId,
            type: EntryType.travel,
            from: travelEntry.fromLocation,
            to: travelEntry.toLocation,
            travelMinutes: travelEntry.travelMinutes,
            date: travelEntry.date,
            notes: travelEntry.remarks,
            createdAt: travelEntry.createdAt,
            updatedAt: travelEntry.updatedAt,
          ));
        }
      }

      // Load work entries
      if (workRepo != null) {
        final workEntries = workRepo.getAllForUser(userId);
        for (final workEntry in workEntries) {
          final List<Shift> shifts = workEntry.workMinutes > 0
              ? [
                  Shift(
                    start: workEntry.date,
                    end: workEntry.date.add(Duration(minutes: workEntry.workMinutes)),
                    description: workEntry.remarks.isNotEmpty
                        ? workEntry.remarks
                        : 'Work Session',
                    location: 'Work Location',
                  ),
                ]
              : [];

          entries.add(Entry(
            id: workEntry.id,
            userId: workEntry.userId,
            type: EntryType.work,
            shifts: shifts,
            date: workEntry.date,
            notes: workEntry.remarks,
            createdAt: workEntry.createdAt,
            updatedAt: workEntry.updatedAt,
          ));
        }
      }

      debugPrint('EntryProvider: Loaded ${entries.length} entries from local cache');
      return entries;
    } catch (e) {
      debugPrint('EntryProvider: Error loading from local cache: $e');
      return [];
    }
  }

  /// Save a single entry to local Hive cache
  Future<void> _saveToLocalCache(Entry entry, String userId) async {
    try {
      if (entry.type == EntryType.travel) {
        final travelRepo = _repositoryProvider.travelRepository;
        if (travelRepo != null) {
          final travelEntry = TravelEntry(
            id: entry.id,
            userId: userId,
            fromLocation: entry.from ?? '',
            toLocation: entry.to ?? '',
            travelMinutes: entry.travelMinutes ?? 0,
            date: entry.date,
            remarks: entry.notes ?? '',
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          );
          await travelRepo.add(travelEntry);
        }
      } else if (entry.type == EntryType.work) {
        final workRepo = _repositoryProvider.workRepository;
        if (workRepo != null) {
          final workMinutes = entry.shifts?.fold<int>(
                  0, (sum, shift) => sum + shift.duration.inMinutes) ??
              0;
          final workEntry = WorkEntry(
            id: entry.id,
            userId: userId,
            workMinutes: workMinutes,
            date: entry.date,
            remarks: entry.notes ?? '',
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          );
          await workRepo.add(workEntry);
        }
      }
    } catch (e) {
      debugPrint('EntryProvider: Error saving to local cache: $e');
      // Don't throw - cache save failure shouldn't break the app
    }
  }

  /// Update a single entry in local Hive cache
  Future<void> _updateInLocalCache(Entry entry, String userId) async {
    try {
      if (entry.type == EntryType.travel) {
        final travelRepo = _repositoryProvider.travelRepository;
        if (travelRepo != null) {
          final travelEntry = TravelEntry(
            id: entry.id,
            userId: userId,
            fromLocation: entry.from ?? '',
            toLocation: entry.to ?? '',
            travelMinutes: entry.travelMinutes ?? 0,
            date: entry.date,
            remarks: entry.notes ?? '',
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          );
          await travelRepo.update(travelEntry);
        }
      } else if (entry.type == EntryType.work) {
        final workRepo = _repositoryProvider.workRepository;
        if (workRepo != null) {
          final workMinutes = entry.shifts?.fold<int>(
                  0, (sum, shift) => sum + shift.duration.inMinutes) ??
              0;
          final workEntry = WorkEntry(
            id: entry.id,
            userId: userId,
            workMinutes: workMinutes,
            date: entry.date,
            remarks: entry.notes ?? '',
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          );
          await workRepo.update(workEntry);
        }
      }
    } catch (e) {
      debugPrint('EntryProvider: Error updating in local cache: $e');
      // Don't throw - cache update failure shouldn't break the app
    }
  }

  /// Delete a single entry from local Hive cache
  Future<void> _deleteFromLocalCache(Entry entry, String userId) async {
    try {
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
