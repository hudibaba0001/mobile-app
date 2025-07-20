import 'package:flutter/foundation.dart';
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../repositories/travel_repository.dart';
import '../repositories/hive_travel_repository.dart';
import '../services/travel_service.dart';
import '../utils/error_handler.dart';

class TravelProvider extends ChangeNotifier {
  final TravelRepository _repository;
  final TravelService _service;

  List<TravelTimeEntry> _entries = [];
  List<TravelTimeEntry> _filteredEntries = [];
  TravelSummary? _currentSummary;
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();
  AppError? _lastError;

  TravelProvider({
    TravelRepository? repository,
    TravelService? service,
  }) : _repository = repository ?? HiveTravelRepository(),
        _service = service ?? TravelService(
          travelRepository: repository ?? HiveTravelRepository(),
          locationRepository: null, // Will be injected properly
        ) {
    _loadEntries();
  }

  // Getters
  List<TravelTimeEntry> get entries => List.unmodifiable(_entries);
  List<TravelTimeEntry> get filteredEntries => List.unmodifiable(_filteredEntries);
  TravelSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime get filterStartDate => _filterStartDate;
  DateTime get filterEndDate => _filterEndDate;
  AppError? get lastError => _lastError;
  bool get hasEntries => _entries.isNotEmpty;
  bool get hasFilteredEntries => _filteredEntries.isNotEmpty;

  // Statistics getters
  int get totalEntries => _entries.length;
  int get totalMinutes => _entries.fold(0, (sum, entry) => sum + entry.minutes);
  double get averageMinutesPerTrip => totalEntries > 0 ? totalMinutes / totalEntries : 0;
  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Load all entries
  Future<void> _loadEntries() async {
    _setLoading(true);
    try {
      _entries = await _repository.getAllEntries();
      _applyFilters();
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh entries
  Future<void> refreshEntries() async {
    await _loadEntries();
  }

  // Add new entry
  Future<bool> addEntry(TravelTimeEntry entry) async {
    _setLoading(true);
    try {
      await _service.saveTravelEntry(entry);
      await _loadEntries();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing entry
  Future<bool> updateEntry(TravelTimeEntry entry) async {
    _setLoading(true);
    try {
      await _service.updateTravelEntry(entry);
      await _loadEntries();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete entry
  Future<bool> deleteEntry(String entryId) async {
    _setLoading(true);
    try {
      await _service.deleteTravelEntry(entryId);
      await _loadEntries();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search entries
  void searchEntries(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set date filter
  void setDateFilter(DateTime startDate, DateTime endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
    _filterEndDate = DateTime.now();
    _applyFilters();
    notifyListeners();
  }

  // Apply current filters
  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Date filter
      final isInDateRange = entry.date.isAfter(_filterStartDate.subtract(const Duration(days: 1))) &&
                           entry.date.isBefore(_filterEndDate.add(const Duration(days: 1)));
      
      if (!isInDateRange) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return entry.departure.toLowerCase().contains(query) ||
               entry.arrival.toLowerCase().contains(query) ||
               (entry.info?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    _filteredEntries.sort((a, b) => b.date.compareTo(a.date));
  }

  // Generate summary for current filter
  Future<void> generateSummary() async {
    _setLoading(true);
    try {
      _currentSummary = await _service.generateSummary(_filterStartDate, _filterEndDate);
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  // Get recent entries (last N entries)
  List<TravelTimeEntry> getRecentEntries({int limit = 5}) {
    final sortedEntries = List<TravelTimeEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.take(limit).toList();
  }

  // Get entries for specific date
  List<TravelTimeEntry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) {
      return entry.date.year == date.year &&
             entry.date.month == date.month &&
             entry.date.day == date.day;
    }).toList();
  }

  // Get entry by ID
  TravelTimeEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get travel statistics
  Future<Map<String, dynamic>> getTravelStatistics() async {
    try {
      return await _service.getTravelStatistics();
    } catch (error) {
      _handleError(error);
      return {};
    }
  }

  // Get recent patterns
  Future<Map<String, dynamic>> getRecentPatterns({int days = 30}) async {
    try {
      return await _service.getRecentPatterns(days: days);
    } catch (error) {
      _handleError(error);
      return {};
    }
  }

  // Export entries to CSV
  Future<String?> exportToCSV() async {
    _setLoading(true);
    try {
      final csvContent = await _service.exportToCSV(_filteredEntries);
      _clearError();
      return csvContent;
    } catch (error) {
      _handleError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _handleError(dynamic error) {
    if (error is AppError) {
      _lastError = error;
    } else {
      _lastError = ErrorHandler.handleUnknownError(error);
    }
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}