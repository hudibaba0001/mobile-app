import 'package:flutter/foundation.dart';
// Updated imports to use unified Entry model instead of TravelTimeEntry
import '../models/entry.dart';
import '../models/travel_summary.dart';
import '../repositories/location_repository.dart';
import '../repositories/hive_location_repository.dart';
import '../services/entry_service.dart'; // Renamed from travel_service.dart
import '../utils/error_handler.dart';

class TravelProvider extends ChangeNotifier {
  // Updated to use EntryService instead of TravelService and TravelRepository
  final EntryService _service;

  // Updated to use Entry model instead of TravelTimeEntry
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  TravelSummary? _currentSummary;
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();
  AppError? _lastError;

  TravelProvider({
    EntryService? service,
  }) : _service = service ?? EntryService(
          locationRepository: HiveLocationRepository(),
        ) {
    _loadEntries();
  }

  // Getters - Updated to use Entry model
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

  // Statistics getters - Updated to use Entry model's travelMinutes field
  int get totalEntries => _entries.length;
  int get totalMinutes => _entries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
  double get averageMinutesPerTrip => totalEntries > 0 ? totalMinutes / totalEntries : 0;
  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Load all entries - Updated to use EntryService.getAllTravelEntries()
  Future<void> _loadEntries() async {
    _setLoading(true);
    try {
      // Use EntryService to get only travel entries from unified entries box
      _entries = await _service.getAllTravelEntries();
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

  // Add new entry - Updated to use Entry model and EntryService.addEntry()
  Future<bool> addEntry(Entry entry) async {
    _setLoading(true);
    try {
      // Use EntryService to add travel entry to unified entries box
      await _service.addEntry(entry);
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

  // Update existing entry - Updated to use Entry model and EntryService.updateEntry()
  Future<bool> updateEntry(Entry entry) async {
    _setLoading(true);
    try {
      // Use EntryService to update travel entry in unified entries box
      await _service.updateEntry(entry);
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

  // Delete entry - Updated to use EntryService.deleteEntry()
  Future<bool> deleteEntry(String entryId) async {
    _setLoading(true);
    try {
      // Use EntryService to delete travel entry from unified entries box
      await _service.deleteEntry(entryId);
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

  // Apply current filters - Updated to use Entry model fields
  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Date filter
      final isInDateRange = entry.date.isAfter(_filterStartDate.subtract(const Duration(days: 1))) &&
                           entry.date.isBefore(_filterEndDate.add(const Duration(days: 1)));
      
      if (!isInDateRange) return false;

      // Search filter - Updated to use Entry model fields (from, to, notes)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (entry.from?.toLowerCase().contains(query) ?? false) ||
               (entry.to?.toLowerCase().contains(query) ?? false) ||
               (entry.notes?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    _filteredEntries.sort((a, b) => b.date.compareTo(a.date));
  }

  // Generate summary for current filter - Uses EntryService.generateSummary()
  Future<void> generateSummary() async {
    _setLoading(true);
    try {
      // EntryService.generateSummary() already filters for travel entries only
      _currentSummary = await _service.generateSummary(_filterStartDate, _filterEndDate);
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  // Get recent entries (last N entries) - Updated to use Entry model
  List<Entry> getRecentEntries({int limit = 5}) {
    final sortedEntries = List<Entry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.take(limit).toList();
  }

  // Get entries for specific date - Updated to use Entry model
  List<Entry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) {
      return entry.date.year == date.year &&
             entry.date.month == date.month &&
             entry.date.day == date.day;
    }).toList();
  }

  // Get entry by ID - Updated to use Entry model
  Entry? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get travel statistics - Uses EntryService.getTravelStatistics()
  Future<Map<String, dynamic>> getTravelStatistics() async {
    try {
      // EntryService.getTravelStatistics() already filters for travel entries only
      return await _service.getTravelStatistics();
    } catch (error) {
      _handleError(error);
      return {};
    }
  }

  // Get suggested routes - Uses EntryService.getSuggestedRoutes()
  Future<List<String>> getSuggestedRoutes({int limit = 5}) async {
    try {
      // EntryService.getSuggestedRoutes() already filters for travel entries only
      return await _service.getSuggestedRoutes(limit: limit);
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  // Export entries to CSV - Uses EntryService.exportToCSV()
  Future<String?> exportToCSV() async {
    _setLoading(true);
    try {
      // EntryService.exportToCSV() already filters for travel entries only
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

  // Journey-related methods - Updated to use Entry model and EntryService
  
  /// Get all segments of a multi-segment journey - Updated to use Entry model
  List<Entry> getJourneySegments(String journeyId) {
    return _entries
        .where((entry) => entry.journeyId == journeyId)
        .toList()
      ..sort((a, b) => (a.segmentOrder ?? 0).compareTo(b.segmentOrder ?? 0));
  }

  /// Check if an entry is part of a multi-segment journey - Updated to use Entry model
  bool isMultiSegmentEntry(Entry entry) {
    // Use EntryService method for consistency
    return _service.isMultiSegmentEntry(entry);
  }

  /// Update an entire multi-segment journey - Updated to use EntryService.updateJourney()
  Future<bool> updateJourney(String journeyId, List<Entry> updatedSegments) async {
    _setLoading(true);
    try {
      // Use EntryService to update entire journey in unified entries box
      await _service.updateJourney(journeyId, updatedSegments);
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