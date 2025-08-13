import '../models/entry.dart';
import '../models/travel_entry.dart';
import '../models/travel_summary.dart';
import '../repositories/travel_repository.dart';
import '../repositories/location_repository.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../config/app_router.dart';
import 'package:provider/provider.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class TravelService {
  final TravelRepository _travelRepository;
  final LocationRepository _locationRepository;

  TravelService({
    required TravelRepository travelRepository,
    required LocationRepository locationRepository,
  })  : _travelRepository = travelRepository,
        _locationRepository = locationRepository;

  /// Generate travel summary for a date range
  Future<TravelSummary> generateSummary(
      DateTime startDate, DateTime endDate) async {
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

  Future<TravelSummary> _generateSummaryInternal(
      DateTime startDate, DateTime endDate) async {
    // Acquire user from a global provider if available
    final userId = _currentUserId();
    final entries =
        _travelRepository.getForUserInRange(userId, startDate, endDate);

    if (entries.isEmpty) {
      return TravelSummary(
        totalEntries: 0,
        totalMinutes: 0,
        startDate: startDate,
        endDate: endDate,
        locationFrequency: {},
      );
    }

    final totalMinutes =
        entries.fold(0, (sum, entry) => sum + entry.travelMinutes);
    final locationFrequency = <String, int>{};

    // Count location frequency
    for (final entry in entries) {
      final route = '${entry.fromLocation} → ${entry.toLocation}';
      locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;

      // Also count individual locations
      locationFrequency[entry.fromLocation] =
          (locationFrequency[entry.fromLocation] ?? 0) + 1;
      locationFrequency[entry.toLocation] =
          (locationFrequency[entry.toLocation] ?? 0) + 1;
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
    final userId = _currentUserId();
    final recentEntries = _travelRepository.getAllForUser(userId);
    final routeFrequency = <String, int>{};

    // Count route frequency
    for (final entry in recentEntries.take(50)) {
      // Look at last 50 entries
      final route = '${entry.fromLocation} → ${entry.toLocation}';
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    }

    // Sort by frequency and return top routes
    final sortedRoutes = routeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRoutes.take(limit).map((e) => e.key).toList();
  }

  /// Export travel entries to CSV format
  Future<String> exportToCSV(List<Entry> entries) async {
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

  Future<String> _exportToCSVInternal(List<Entry> entries) async {
    final buffer = StringBuffer();

    // Add header
    buffer.writeln(AppConstants.csvHeader);

    // Add data rows
    for (final entry in entries) {
      if (entry.type == EntryType.travel &&
          entry.from != null &&
          entry.to != null) {
        final row = [
          _escapeCsvField(
              entry.date.toIso8601String().split('T')[0]), // Date only
          _escapeCsvField(entry.from!),
          _escapeCsvField(entry.to!),
          entry.minutes.toString(),
          _escapeCsvField(entry.notes ?? ''),
          _escapeCsvField(entry.createdAt.toIso8601String()),
        ];
        buffer.writeln(row.join(','));
      }
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
    final userId = _currentUserId();
    final allEntries = _travelRepository.getAllForUser(userId);

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

    final totalMinutes =
        allEntries.fold(0, (sum, entry) => sum + entry.travelMinutes);
    final minutes = allEntries.map((e) => e.travelMinutes).toList()..sort();

    // Calculate date range
    final dates = allEntries.map((e) => e.date).toList()..sort();
    final daysDifference = dates.last.difference(dates.first).inDays + 1;

    // Find most frequent route
    final routeFrequency = <String, int>{};
    for (final entry in allEntries) {
      final route = '${entry.fromLocation} → ${entry.toLocation}';
      routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
    }

    final mostFrequentRoute = routeFrequency.isNotEmpty
        ? routeFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

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
    final userId = _currentUserId();
    final recentEntries =
        _travelRepository.getForUserInRange(userId, cutoffDate, DateTime.now());

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
      departures[entry.fromLocation] =
          (departures[entry.fromLocation] ?? 0) + 1;
      arrivals[entry.toLocation] = (arrivals[entry.toLocation] ?? 0) + 1;

      final route = '${entry.fromLocation} → ${entry.toLocation}';
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

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final peakDayNames =
        peakDays.take(3).map((e) => dayNames[e.key - 1]).toList();

    final averageTripTime =
        recentEntries.fold(0, (sum, entry) => sum + entry.travelMinutes) /
            recentEntries.length;

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
  Future<void> saveTravelEntry(Entry entry) async {
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

  Future<void> _saveTravelEntryInternal(Entry entry) async {
    // Convert Entry to TravelEntry for storage
    final travelEntry = TravelEntry(
      id: entry.id,
      userId: entry.userId,
      date: entry.date,
      fromLocation: entry.from ?? '',
      toLocation: entry.to ?? '',
      travelMinutes: entry.minutes,
      remarks: entry.notes ?? '',
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );

    await _travelRepository.add(travelEntry);

    // Update location usage counts if locations are linked
    // Note: This would need location IDs, but we don't have them in the current model
    // TODO: Implement location linking when location system is ready
  }

  /// Update travel entry
  Future<void> updateTravelEntry(Entry entry) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _updateTravelEntryInternal(entry),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<void> _updateTravelEntryInternal(Entry entry) async {
    // Convert Entry to TravelEntry for storage
    final travelEntry = TravelEntry(
      id: entry.id,
      userId: entry.userId,
      date: entry.date,
      fromLocation: entry.from ?? '',
      toLocation: entry.to ?? '',
      travelMinutes: entry.minutes,
      remarks: entry.notes ?? '',
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );

    await _travelRepository.update(travelEntry);
  }

  /// Delete travel entry
  Future<void> deleteTravelEntry(String entryId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _travelRepository.delete(entryId),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Search travel entries
  Future<List<Entry>> searchEntries(String query) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _searchEntriesInternal(query),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<Entry>> _searchEntriesInternal(String query) async {
    final userId = _currentUserId();
    final allEntries = _travelRepository.getAllForUser(userId);

    // Simple search implementation
    final lowercaseQuery = query.toLowerCase();
    final results = <Entry>[];

    for (final travelEntry in allEntries) {
      // Convert TravelEntry to Entry for consistency
      final entry = Entry(
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
      );

      // Search in departure, arrival, and notes
      if (travelEntry.fromLocation.toLowerCase().contains(lowercaseQuery) ||
          travelEntry.toLocation.toLowerCase().contains(lowercaseQuery) ||
          travelEntry.remarks.toLowerCase().contains(lowercaseQuery)) {
        results.add(entry);
      }
    }

    return results;
  }

  String _currentUserId() {
    // This service isn’t a widget; prefer using a global/provider lookup pattern.
    // For now, require that callers have set up a Provider scope and retrieve via
    // Navigation or a service locator. Here we fall back to throwing if missing.
    try {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        final auth = Provider.of<AuthService>(ctx, listen: false);
        final uid = auth.currentUser?.uid;
        if (uid != null) return uid;
      }
    } catch (_) {}
    throw Exception('No authenticated user');
  }
}
