import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../models/travel_summary.dart';
import '../services/entry_service.dart';
import '../repositories/hive_location_repository.dart';
import '../utils/error_handler.dart';

/// Provider for managing unified Entry objects (replaces TravelProvider)
/// Handles travel entries using the new unified Entry model instead of TravelTimeEntry
class EntryProvider extends ChangeNotifier {
  final EntryService _entryService;

  // State variables - now using Entry instead of TravelTimeEntry
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  TravelSummary? _currentSummary;
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();
  AppError? _lastError;

  EntryProvider({
    EntryService? entryService,
  }) : _entryService = entryService ?? EntryService(
          locationRepository: HiveLocationRepository(),
        ) {
    _loadEntries();
  }

  // Getters - Updated to return Entry objects instead of TravelTimeEntry
  List<Entry> get entries => List.unmodifiable(_entries);
  List<Entry> get filteredEntries => List.unmodifiable(_filteredEntries);
  TravelSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime get filterStartDate => _filterStartDate;
  DateTime get filterEndDate => _filterEndDate;
  AppError? get lastError => _lastError;
  bool get hasEntries => _entries.isNotEmpty;
  bool get hasFilteredEntries => _filteredEntries.isNotEmpty;

  // Statistics getters - Updated to work with Entry objects
  int get totalEntries => _entries.length;
  int get totalMinutes => _entries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
  double get averageMinutesPerTrip => totalEntries > 0 ? totalMinutes / totalEntries : 0;
  
  String get formattedTotalTime {
    if (totalMinutes == 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  // Load all travel entries from the unified entries box
  Future<void> _loadEntries() async {
    _setLoading(true);
    try {
      // Use EntryService to get only travel entries from unified 'entries' box
      _entries = await _entryService.getAllTravelEntries();
      _applyFilters();
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  /// Add new travel entry to the unified entries box
  Future<bool> addEntry(Entry entry) async {
    // Ensure this is a travel entry
    if (entry.type != EntryType.travel) {
      _handleError(ArgumentError('EntryProvider only handles travel entries'));
      return false;
    }

    _setLoading(true);
    try {
      // Use EntryService to add to unified 'entries' box
      await _entryService.addEntry(entry);
      await _loadEntries(); // Reload to get updated list
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing travel entry in the unified entries box
  Future<bool> updateEntry(Entry entry) async {
    // Ensure this is a travel entry
    if (entry.type != EntryType.travel) {
      _handleError(ArgumentError('EntryProvider only handles travel entries'));
      return false;
    }

    _setLoading(true);
    try {
      // Use EntryService to update in unified 'entries' box
      await _entryService.updateEntry(entry);
      await _loadEntries(); // Reload to get updated list
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete travel entry from the unified entries box
  Future<bool> deleteEntry(String entryId) async {
    _setLoading(true);
    try {
      // Use EntryService to delete from unified 'entries' box (with travel type validation)
      await _entryService.deleteEntry(entryId);
      await _loadEntries(); // Reload to get updated list
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get travel entries for today from the unified entries box
  Future<List<Entry>> getTodayEntries() async {
    try {
      final today = DateTime.now();
      // Use EntryService to get today's travel entries from unified 'entries' box
      return await _entryService.getEntriesForDate(today);
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  /// Get recent travel entries from the unified entries box
  Future<List<Entry>> getRecentEntries({int limit = 5}) async {
    try {
      // Use EntryService to get recent travel entries from unified 'entries' box
      return await _entryService.getRecentEntries(limit: limit);
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  /// Search travel entries in the unified entries box
  void searchEntries(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set date filter for travel entries
  void setDateFilter(DateTime startDate, DateTime endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
    _filterEndDate = DateTime.now();
    _applyFilters();
    notifyListeners();
  }

  /// Apply current filters to travel entries
  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Date filter
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final startDate = DateTime(_filterStartDate.year, _filterStartDate.month, _filterStartDate.day);
      final endDate = DateTime(_filterEndDate.year, _filterEndDate.month, _filterEndDate.day);
      
      final isInDateRange = (entryDate.isAtSameMomentAs(startDate) || entryDate.isAfter(startDate)) &&
                           (entryDate.isAtSameMomentAs(endDate) || entryDate.isBefore(endDate));

      if (!isInDateRange) return false;

      // Search filter - search in from, to, and notes fields
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = (entry.from?.toLowerCase().contains(query) ?? false) ||
                             (entry.to?.toLowerCase().contains(query) ?? false) ||
                             (entry.notes?.toLowerCase().contains(query) ?? false);
        if (!matchesSearch) return false;
      }

      return true;
    }).toList();
  }

  /// Generate travel summary for current date range
  Future<void> generateSummary() async {
    _setLoading(true);
    try {
      // Use EntryService to generate summary from unified 'entries' box (travel entries only)
      _currentSummary = await _entryService.generateSummary(_filterStartDate, _filterEndDate);
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh entries from the unified entries box
  Future<void> refreshEntries() async {
    await _loadEntries();
  }

  /// Export travel entries to CSV
  Future<String> exportToCSV() async {
    try {
      // Use EntryService to export travel entries from unified 'entries' box
      return await _entryService.exportToCSV(_filteredEntries);
    } catch (error) {
      _handleError(error);
      return '';
    }
  }

  // Journey-related methods for multi-segment travel entries

  /// Get all segments of a multi-segment journey from unified entries box
  List<Entry> getJourneySegments(String journeyId) {
    // Filter travel entries by journey ID from current entries
    return _entries
        .where((entry) => entry.journeyId == journeyId)
        .toList()
      ..sort((a, b) => (a.segmentOrder ?? 0).compareTo(b.segmentOrder ?? 0));
  }

  /// Check if an entry is part of a multi-segment journey
  bool isMultiSegmentEntry(Entry entry) {
    return _entryService.isMultiSegmentEntry(entry);
  }

  /// Update an entire multi-segment journey in unified entries box
  Future<bool> updateJourney(String journeyId, List<Entry> updatedSegments) async {
    _setLoading(true);
    try {
      // Use EntryService to update journey in unified 'entries' box
      await _entryService.updateJourney(journeyId, updatedSegments);
      await _loadEntries(); // Reload to get updated list
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an entire multi-segment journey from unified entries box
  Future<bool> deleteJourney(String journeyId) async {
    _setLoading(true);
    try {
      // Use EntryService to delete journey from unified 'entries' box
      await _entryService.deleteJourney(journeyId);
      await _loadEntries(); // Reload to get updated list
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get travel statistics from unified entries box
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Use EntryService to get statistics from unified 'entries' box (travel entries only)
      return await _entryService.getTravelStatistics();
    } catch (error) {
      _handleError(error);
      return {
        'totalEntries': 0,
        'totalMinutes': 0,
        'averageMinutes': 0.0,
        'mostFrequentRoute': null,
        'totalJourneys': 0,
      };
    }
  }

  /// Get suggested routes based on travel entry frequency
  Future<List<String>> getSuggestedRoutes({int limit = 5}) async {
    try {
      // Use EntryService to get suggested routes from unified 'entries' box
      return await _entryService.getSuggestedRoutes(limit: limit);
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  // Private helper methods

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

  /// Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}