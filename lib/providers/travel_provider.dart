import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../models/travel_summary.dart';
import '../repositories/repository_provider.dart';

class TravelProvider extends ChangeNotifier {
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  TravelSummary? _currentSummary;
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();
  String? _lastError;

  TravelProvider() {
    _loadEntries();
  }

  // Getters
  List<Entry> get entries => List.unmodifiable(_entries);
  List<Entry> get filteredEntries => List.unmodifiable(_filteredEntries);
  TravelSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime get filterStartDate => _filterStartDate;
  DateTime get filterEndDate => _filterEndDate;
  String? get lastError => _lastError;
  bool get hasEntries => _entries.isNotEmpty;
  bool get hasFilteredEntries => _filteredEntries.isNotEmpty;

  // Statistics getters - Updated to use Entry model's travelMinutes field
  int get totalEntries => _entries.length;
  int get totalMinutes => _entries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
  double get averageMinutesPerTrip => totalEntries > 0 ? totalMinutes / totalEntries : 0;
  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Load all entries - Updated to use RepositoryProvider
  Future<void> _loadEntries() async {
    _setLoading(true);
    try {
      // For now, we'll use a simple approach - in the future, we can integrate with RepositoryProvider
      // This is a placeholder implementation
      _entries = [];
      _applyFilters();
      _clearError();
    } catch (error) {
      _handleError(error.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Refresh entries
  Future<void> refreshEntries() async {
    await _loadEntries();
  }

  // Add new entry - Updated to use Entry model
  Future<bool> addEntry(Entry entry) async {
    _setLoading(true);
    try {
      // For now, we'll just add to the local list
      // In the future, we can integrate with RepositoryProvider
      _entries.add(entry);
      _applyFilters();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing entry - Updated to use Entry model
  Future<bool> updateEntry(Entry entry) async {
    _setLoading(true);
    try {
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        _applyFilters();
        _clearError();
        return true;
      }
      return false;
    } catch (error) {
      _handleError(error.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete entry
  Future<bool> deleteEntry(String entryId) async {
    _setLoading(true);
    try {
      _entries.removeWhere((entry) => entry.id == entryId);
      _applyFilters();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  // Date filtering
  void setDateRange(DateTime startDate, DateTime endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _applyFilters();
  }

  void clearDateFilter() {
    _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
    _filterEndDate = DateTime.now();
    _applyFilters();
  }

  // Apply filters to entries
  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Date filter
      final isInDateRange = entry.date.isAfter(_filterStartDate.subtract(const Duration(days: 1))) &&
                           entry.date.isBefore(_filterEndDate.add(const Duration(days: 1)));

      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          entry.from?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          entry.to?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          entry.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      return isInDateRange && matchesSearch;
    }).toList();

    // Sort by date (newest first)
    _filteredEntries.sort((a, b) => b.date.compareTo(a.date));
  }

  // Generate summary for the current filtered entries
  void generateSummary() {
    if (_filteredEntries.isEmpty) {
      _currentSummary = TravelSummary(
        totalEntries: 0,
        totalMinutes: 0,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        locationFrequency: {},
      );
      return;
    }

    final totalMinutes = _filteredEntries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
    final locationFrequency = <String, int>{};

    for (final entry in _filteredEntries) {
      if (entry.from != null && entry.to != null) {
        final route = '${entry.from} → ${entry.to}';
        locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;
      }
    }

    _currentSummary = TravelSummary(
      totalEntries: _filteredEntries.length,
      totalMinutes: totalMinutes,
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      locationFrequency: locationFrequency,
    );
  }

  // Get entries for a specific date range
  List<Entry> getEntriesInDateRange(DateTime startDate, DateTime endDate) {
    return _entries.where((entry) {
      return entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get travel entries only
  List<Entry> get travelEntries {
    return _entries.where((entry) => entry.type == EntryType.travel).toList();
  }

  // Get work entries only
  List<Entry> get workEntries {
    return _entries.where((entry) => entry.type == EntryType.work).toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }
}