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

      // Load travel entries
      final travelEntries =
          _repositoryProvider.travelRepository.getAllForUser(userId);

      // Load work entries
      final workEntries =
          _repositoryProvider.workRepository.getAllForUser(userId);

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
      _filteredEntries = _entries;
      _error = null;

      if (kDebugMode) {
        print(
            '✅ EntryProvider: Loaded ${_entries.length} entries (${travelEntries.length} travel, ${workEntries.length} work)');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ EntryProvider: Error loading entries: $e');
      }
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
        await _repositoryProvider.travelRepository.add(travelEntry);
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
        await _repositoryProvider.workRepository.add(workEntry);
      }

      // Add to local list and refresh
      _entries.add(entry);
      _applyFilters();
      notifyListeners();

      if (kDebugMode) {
        print(
            '✅ EntryProvider: Added ${entry.type} entry with ID: ${entry.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EntryProvider: Error adding entry: $e');
      }
      rethrow;
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
        await _repositoryProvider.travelRepository.update(travelEntry);
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
        await _repositoryProvider.workRepository.update(workEntry);
      }

      // Update local list
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        _applyFilters();
        notifyListeners();
      }

      if (kDebugMode) {
        print(
            '✅ EntryProvider: Updated ${entry.type} entry with ID: ${entry.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EntryProvider: Error updating entry: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      // Find the entry to determine its type
      final entry = _entries.firstWhere((e) => e.id == id);

      if (entry.type == EntryType.travel) {
        await _repositoryProvider.travelRepository.delete(id);
      } else if (entry.type == EntryType.work) {
        await _repositoryProvider.workRepository.delete(id);
      }

      // Remove from local list
      _entries.removeWhere((e) => e.id == id);
      _applyFilters();
      notifyListeners();

      if (kDebugMode) {
        print('✅ EntryProvider: Deleted ${entry.type} entry with ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EntryProvider: Error deleting entry: $e');
      }
      rethrow;
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
