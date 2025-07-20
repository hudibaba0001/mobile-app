import 'dart:convert';
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../repositories/travel_repository.dart';
import '../repositories/location_repository.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class TravelService {
  final TravelRepository _travelRepository;
  final LocationRepository _locationRepository;

  TravelService({
    required TravelRepository travelRepository,
    required LocationRepository locationRepository,
  }) : _travelRepository = travelRepository,
       _locationRepository = locationRepository;

  /// Generate travel summary for a date range
  Future<TravelSummary> generateSummary(DateTime startDate, DateTime endDate) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _generateSummaryInternal(startDate, endDate),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<TravelSummary> _generateSummaryInternal(DateTime startDate, DateTime endDate) async {
    final entries = await _travelRepository.getEntriesInDateRange(startDate, endDate);
    
    if (entries.isEmpty) {
      return TravelSummary(
        totalEntries: 0,
        totalMinutes: 0,
        startDate: startDate,
        endDate: endDate,
        locationFrequency: {},
      );
    }

    final totalMinutes = entries.fold(0, (sum, entry) => sum + entry.minutes);
    final locationFrequency = <String, int>{};

    // Count location frequency
    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;
      
      // Also count individual locations
      locationFrequency[entry.departure] = (locationFrequency[entry.departure] ?? 0) + 1;
      locationFrequency[entry.arrival] = (locationFrequency[entry.arrival] ?? 0) + 1;
    }

    return TravelSummary(
      totalEntries: entries.length,
      totalMinutes: totalMinutes,
      startDate: startDate,
      endDate: endDate,
      locationFrequency: locationFrequency,
    );
  }

  /// Get suggested routes based on usage patterns
  Future<List<String>> getSuggestedRoutes({int limit = 5}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getSuggestedRoutesInternal(limit),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<String>> _getSuggestedRoutesInternal(int limit) async {
    final recentEntries = await _travelRepository.getAllEntries();
    final routeFrequency = <String, int>{};

    // Count route frequency
    for (final entry in recentEntries.take(50)) { // Look at last 50 entries
      final route = '${entry.departure} → ${entry.arrival}';
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    }

    // Sort by frequency and return top routes
    final sortedRoutes = routeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRoutes.take(limit).map((e) => e.key).toList();
  }

  /// Export travel entries to CSV format
  Future<String> exportToCSV(List<TravelTimeEntry> entries) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _exportToCSVInternal(entries),
        shouldRetry: (error) => false, // Don't retry CSV generation
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleUnknownError(error, stackTrace);
      throw appError;
    }
  }

  Future<String> _exportToCSVInternal(List<TravelTimeEntry> entries) async {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln(AppConstants.csvHeader);
    
    // Add data rows
    for (final entry in entries) {
      final row = [
        _escapeCsvField(entry.date.toIso8601String().split('T')[0]), // Date only
        _escapeCsvField(entry.departure),
        _escapeCsvField(entry.arrival),
        entry.minutes.toString(),
        _escapeCsvField(entry.info ?? ''),
        _escapeCsvField(entry.createdAt.toIso8601String()),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Get travel statistics for analytics
  Future<Map<String, dynamic>> getTravelStatistics() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getTravelStatisticsInternal(),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<Map<String, dynamic>> _getTravelStatisticsInternal() async {
    final allEntries = await _travelRepository.getAllEntries();
    
    if (allEntries.isEmpty) {
      return {
        'totalEntries': 0,
        'totalMinutes': 0,
        'totalHours': 0,
        'averageMinutesPerTrip': 0.0,
        'longestTrip': 0,
        'shortestTrip': 0,
        'mostFrequentRoute': 'None',
        'totalDays': 0,
        'averageTripsPerDay': 0.0,
      };
    }

    final totalMinutes = allEntries.fold(0, (sum, entry) => sum + entry.minutes);
    final minutes = allEntries.map((e) => e.minutes).toList()..sort();
    
    // Calculate date range
    final dates = allEntries.map((e) => e.date).toList()..sort();
    final daysDifference = dates.last.difference(dates.first).inDays + 1;
    
    // Find most frequent route
    final routeFrequency = <String, int>{};
    for (final entry in allEntries) {
      final route = '${entry.departure} → ${entry.arrival}';
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    }
    
    final mostFrequentRoute = routeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'totalEntries': allEntries.length,
      'totalMinutes': totalMinutes,
      'totalHours': (totalMinutes / 60).round(),
      'averageMinutesPerTrip': totalMinutes / allEntries.length,
      'longestTrip': minutes.last,
      'shortestTrip': minutes.first,
      'mostFrequentRoute': mostFrequentRoute,
      'totalDays': daysDifference,
      'averageTripsPerDay': allEntries.length / daysDifference,
    };
  }

  /// Get recent travel patterns for suggestions
  Future<Map<String, dynamic>> getRecentPatterns({int days = 30}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getRecentPatternsInternal(days),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<Map<String, dynamic>> _getRecentPatternsInternal(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentEntries = await _travelRepository.getEntriesInDateRange(cutoffDate, DateTime.now());
    
    if (recentEntries.isEmpty) {
      return {
        'commonDepartures': <String>[],
        'commonArrivals': <String>[],
        'commonRoutes': <String>[],
        'averageTripTime': 0.0,
        'peakTravelDays': <String>[],
      };
    }

    // Analyze patterns
    final departures = <String, int>{};
    final arrivals = <String, int>{};
    final routes = <String, int>{};
    final dayOfWeekCounts = <int, int>{};

    for (final entry in recentEntries) {
      departures[entry.departure] = (departures[entry.departure] ?? 0) + 1;
      arrivals[entry.arrival] = (arrivals[entry.arrival] ?? 0) + 1;
      
      final route = '${entry.departure} → ${entry.arrival}';
      routes[route] = (routes[route] ?? 0) + 1;
      
      final dayOfWeek = entry.date.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
    }

    // Get top items
    final topDepartures = _getTopItems(departures, 5);
    final topArrivals = _getTopItems(arrivals, 5);
    final topRoutes = _getTopItems(routes, 5);
    
    // Get peak travel days
    final peakDays = dayOfWeekCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final peakDayNames = peakDays.take(3).map((e) => dayNames[e.key - 1]).toList();

    final averageTripTime = recentEntries.fold(0, (sum, entry) => sum + entry.minutes) / recentEntries.length;

    return {
      'commonDepartures': topDepartures,
      'commonArrivals': topArrivals,
      'commonRoutes': topRoutes,
      'averageTripTime': averageTripTime,
      'peakTravelDays': peakDayNames,
    };
  }

  List<String> _getTopItems(Map<String, int> items, int limit) {
    final sortedItems = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedItems.take(limit).map((e) => e.key).toList();
  }

  /// Validate and save travel entry
  Future<void> saveTravelEntry(TravelTimeEntry entry) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _saveTravelEntryInternal(entry),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<void> _saveTravelEntryInternal(TravelTimeEntry entry) async {
    await _travelRepository.addEntry(entry);
    
    // Update location usage counts if locations are linked
    if (entry.departureLocationId != null) {
      await _locationRepository.incrementUsageCount(entry.departureLocationId!);
    }
    if (entry.arrivalLocationId != null) {
      await _locationRepository.incrementUsageCount(entry.arrivalLocationId!);
    }
  }

  /// Update travel entry
  Future<void> updateTravelEntry(TravelTimeEntry entry) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _travelRepository.updateEntry(entry),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Delete travel entry
  Future<void> deleteTravelEntry(String entryId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _travelRepository.deleteEntry(entryId),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Search travel entries
  Future<List<TravelTimeEntry>> searchEntries(String query) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _travelRepository.searchEntries(query),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }
}