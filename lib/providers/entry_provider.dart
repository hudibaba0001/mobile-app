import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../repositories/repository_provider.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../services/auth_service.dart';

class EntryProvider extends ChangeNotifier {
  final RepositoryProvider _repositoryProvider;
  final AuthService _authService;

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
      final userId = _authService.currentUser?.uid;
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

      // Load travel entries
      List<TravelEntry> travelEntries = [];
      List<WorkEntry> workEntries = [];

      try {
        final travelRepo = _repositoryProvider.travelRepository;
        final workRepo = _repositoryProvider.workRepository;
        
        if (travelRepo != null) {
          travelEntries = travelRepo.getAllForUser(userId);
        }
        if (workRepo != null) {
          workEntries = workRepo.getAllForUser(userId);
        }
      } catch (e) {
        debugPrint('EntryProvider: Error accessing repositories: $e');
        // Return empty lists if repositories are not ready
        travelEntries = [];
        workEntries = [];
      }

      // Convert to unified Entry objects
      final allEntries = <Entry>[];

      // Convert travel entries
      for (final travelEntry in travelEntries) {
        allEntries.add(Entry(
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

      // Convert work entries
      for (final workEntry in workEntries) {
        // Convert workMinutes to a Shift object
        final List<Shift> shifts = workEntry.workMinutes > 0
            ? [
                Shift(
                  start: workEntry.date,
                  end: workEntry.date
                      .add(Duration(minutes: workEntry.workMinutes)),
                  description: workEntry.remarks.isNotEmpty
                      ? workEntry.remarks
                      : 'Work Session',
                  location: 'Work Location', // Default location
                ),
              ]
            : [];

        allEntries.add(Entry(
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

      // Sort by date (most recent first)
      allEntries.sort((a, b) => b.date.compareTo(a.date));

      _entries = allEntries;
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
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (entry.type == EntryType.travel) {
        // Save travel entry to repository
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
        final travelRepo = _repositoryProvider.travelRepository;
        if (travelRepo != null) {
          await travelRepo.add(travelEntry);
        } else {
          throw Exception('Travel repository not available');
        }
      } else if (entry.type == EntryType.work) {
        // Save work entry to repository
        final workEntry = WorkEntry(
          id: entry.id,
          userId: userId,
          workMinutes: entry.shifts?.fold<int>(
                  0, (sum, shift) => sum + shift.duration.inMinutes) ??
              0,
          date: entry.date,
          remarks: entry.notes ?? '',
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        );
        final workRepo = _repositoryProvider.workRepository;
        if (workRepo != null) {
          await workRepo.add(workEntry);
        } else {
          throw Exception('Work repository not available');
        }
      }

      // Add to local list and refresh
      _entries.add(entry);
      _applyFilters();
      notifyListeners();

      debugPrint(
          'EntryProvider: Added ${entry.type} entry with ID: ${entry.id}');
    } catch (e) {
      debugPrint('EntryProvider: Error adding entry: $e');
      throw Exception('Unable to add entry. Please try again.');
    }
  }

  Future<void> updateEntry(Entry entry) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (entry.type == EntryType.travel) {
        // Update travel entry in repository
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
        final travelRepo = _repositoryProvider.travelRepository;
        if (travelRepo != null) {
          await travelRepo.update(travelEntry);
        } else {
          throw Exception('Travel repository not available');
        }
      } else if (entry.type == EntryType.work) {
        // Update work entry in repository
        final workEntry = WorkEntry(
          id: entry.id,
          userId: userId,
          workMinutes: entry.shifts?.fold<int>(
                  0, (sum, shift) => sum + shift.duration.inMinutes) ??
              0,
          date: entry.date,
          remarks: entry.notes ?? '',
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        );
        final workRepo = _repositoryProvider.workRepository;
        if (workRepo != null) {
          await workRepo.update(workEntry);
        } else {
          throw Exception('Work repository not available');
        }
      }

      // Update local list
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        _applyFilters();
        notifyListeners();
      }

      debugPrint(
          'EntryProvider: Updated ${entry.type} entry with ID: ${entry.id}');
    } catch (e) {
      debugPrint('EntryProvider: Error updating entry: $e');
      throw Exception('Unable to update entry. Please try again.');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      Entry? entry;
      try {
        entry = _entries.firstWhere((e) => e.id == id);
      } catch (_) {
        entry = null;
      }

      // Determine type by probing repositories if not found in memory
      EntryType? entryType = entry?.type;
      if (entryType == null) {
        final travelRepo = _repositoryProvider.travelRepository;
        final workRepo = _repositoryProvider.workRepository;
        
        if (travelRepo != null) {
          final travel = travelRepo.getById(id);
          if (travel != null) {
            entryType = EntryType.travel;
          }
        }
        
        if (entryType == null && workRepo != null) {
          final work = workRepo.getById(id);
          if (work != null) {
            entryType = EntryType.work;
          }
        }
      }

      if (entryType == null) {
        throw Exception('Entry not found');
      }

      if (entryType == EntryType.travel) {
        final travelRepo = _repositoryProvider.travelRepository;
        if (travelRepo != null) {
          await travelRepo.delete(id);
        } else {
          throw Exception('Travel repository not available');
        }
      } else if (entryType == EntryType.work) {
        final workRepo = _repositoryProvider.workRepository;
        if (workRepo != null) {
          await workRepo.delete(id);
        } else {
          throw Exception('Work repository not available');
        }
      }

      // Remove from local list if present
      final before = _entries.length;
      _entries.removeWhere((e) => e.id == id);
      final removed = _entries.length < before;
      if (!removed) {
        // If we didn't have it locally, refresh the list to keep UI in sync
        await loadEntries();
      } else {
        _applyFilters();
        notifyListeners();
      }

      debugPrint('EntryProvider: Deleted $entryType entry with ID: $id');
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
}
