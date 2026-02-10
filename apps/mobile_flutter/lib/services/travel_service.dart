import '../models/entry.dart';
import '../models/travel_summary.dart';
import '../repositories/location_repository.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../config/app_router.dart';
import 'package:provider/provider.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';
import '../providers/entry_provider.dart';

class TravelService {
  // TODO: Remove once legacy location lookup is fully retired
  // ignore: unused_field
  final LocationRepository _locationRepository;

  /// Get origin text from an entry, preferring travelLegs over legacy fields
  static String? _getOrigin(Entry entry) {
    if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
      return entry.travelLegs!.first.fromText;
    }
    return entry.from;
  }

  /// Get destination text from an entry, preferring travelLegs over legacy fields
  static String? _getDestination(Entry entry) {
    if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
      return entry.travelLegs!.last.toText;
    }
    return entry.to;
  }
  EntryProvider? _entryProvider;

  TravelService({
    required LocationRepository locationRepository,
    EntryProvider? entryProvider,
  })  : _locationRepository = locationRepository,
        _entryProvider = entryProvider;

  /// Set EntryProvider (for dependency injection)
  void setEntryProvider(EntryProvider entryProvider) {
    _entryProvider = entryProvider;
  }

  /// Get EntryProvider from context if not set
  EntryProvider? _getEntryProvider() {
    if (_entryProvider != null) return _entryProvider;
    try {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        return Provider.of<EntryProvider>(ctx, listen: false);
      }
    } catch (_) {}
    return null;
  }

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
    // Use EntryProvider instead of legacy repository
    final entryProvider = _getEntryProvider();
    if (entryProvider == null) {
      throw Exception('EntryProvider not available');
    }

    // Ensure entries are loaded
    if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
      await entryProvider.loadEntries();
    }

    // Filter travel entries in date range
    final userId = _currentUserId();
    final travelEntries = entryProvider.entries
        .where((e) =>
            e.type == EntryType.travel &&
            e.userId == userId &&
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    if (travelEntries.isEmpty) {
      return TravelSummary(
        totalEntries: 0,
        totalMinutes: 0,
        startDate: startDate,
        endDate: endDate,
        locationFrequency: {},
      );
    }

    final totalMinutes =
        travelEntries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
    final locationFrequency = <String, int>{};

    // Count location frequency
    for (final entry in travelEntries) {
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      if (origin != null && destination != null) {
        final route = '$origin \u2192 $destination';
        locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;

        // Also count individual locations
        locationFrequency[origin] =
            (locationFrequency[origin] ?? 0) + 1;
        locationFrequency[destination] = (locationFrequency[destination] ?? 0) + 1;
      }
    }

    return TravelSummary(
      totalEntries: travelEntries.length,
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
    // Use EntryProvider instead of legacy repository
    final entryProvider = _getEntryProvider();
    if (entryProvider == null) {
      throw Exception('EntryProvider not available');
    }

    // Ensure entries are loaded
    if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
      await entryProvider.loadEntries();
    }

    final userId = _currentUserId();
    final travelEntries = entryProvider.entries
        .where((e) => e.type == EntryType.travel && e.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

    final routeFrequency = <String, int>{};

    // Count route frequency (look at last 50 entries)
    for (final entry in travelEntries.take(50)) {
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      if (origin != null && destination != null) {
        final route = '$origin \u2192 $destination';
        routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
      }
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
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      if (entry.type == EntryType.travel &&
          origin != null &&
          destination != null) {
        final row = [
          _escapeCsvField(
              entry.date.toIso8601String().split('T')[0]), // Date only
          _escapeCsvField(origin),
          _escapeCsvField(destination),
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
    // Use EntryProvider instead of legacy repository
    final entryProvider = _getEntryProvider();
    if (entryProvider == null) {
      throw Exception('EntryProvider not available');
    }

    // Ensure entries are loaded
    if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
      await entryProvider.loadEntries();
    }

    final userId = _currentUserId();
    final travelEntries = entryProvider.entries
        .where((e) => e.type == EntryType.travel && e.userId == userId)
        .toList();

    if (travelEntries.isEmpty) {
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
        travelEntries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
    final minutes = travelEntries
        .where((e) => e.travelMinutes != null)
        .map((e) => e.travelMinutes!)
        .toList()
      ..sort();

    // Calculate date range
    final dates = travelEntries.map((e) => e.date).toList()..sort();
    final daysDifference =
        dates.isNotEmpty ? dates.last.difference(dates.first).inDays + 1 : 0;

    // Find most frequent route
    final routeFrequency = <String, int>{};
    for (final entry in travelEntries) {
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      if (origin != null && destination != null) {
        final route = '$origin \u2192 $destination';
        routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
      }
    }

    final mostFrequentRoute = routeFrequency.isNotEmpty
        ? routeFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    return {
      'totalEntries': travelEntries.length,
      'totalMinutes': totalMinutes,
      'totalHours': (totalMinutes / 60).round(),
      'averageMinutesPerTrip':
          travelEntries.isNotEmpty ? totalMinutes / travelEntries.length : 0.0,
      'longestTrip': minutes.isNotEmpty ? minutes.last : 0,
      'shortestTrip': minutes.isNotEmpty ? minutes.first : 0,
      'mostFrequentRoute': mostFrequentRoute,
      'totalDays': daysDifference,
      'averageTripsPerDay':
          daysDifference > 0 ? travelEntries.length / daysDifference : 0.0,
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
    // Use EntryProvider instead of legacy repository
    final entryProvider = _getEntryProvider();
    if (entryProvider == null) {
      throw Exception('EntryProvider not available');
    }

    // Ensure entries are loaded
    if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
      await entryProvider.loadEntries();
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final userId = _currentUserId();
    final recentEntries = entryProvider.entries
        .where((e) =>
            e.type == EntryType.travel &&
            e.userId == userId &&
            e.date.isAfter(cutoffDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(DateTime.now().add(const Duration(days: 1))))
        .toList();

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
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      if (origin != null) {
        departures[origin] = (departures[origin] ?? 0) + 1;
      }
      if (destination != null) {
        arrivals[destination] = (arrivals[destination] ?? 0) + 1;
      }

      if (origin != null && destination != null) {
        final route = '$origin \u2192 $destination';
        routes[route] = (routes[route] ?? 0) + 1;
      }

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

    final averageTripTime = recentEntries.fold<int>(
            0, (sum, entry) => sum + (entry.travelMinutes ?? 0)) /
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
    // Use EntryProvider instead of legacy repository
    final entryProvider = _getEntryProvider();
    if (entryProvider == null) {
      throw Exception('EntryProvider not available');
    }

    // Ensure entries are loaded
    if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
      await entryProvider.loadEntries();
    }

    final userId = _currentUserId();
    final travelEntries = entryProvider.entries
        .where((e) => e.type == EntryType.travel && e.userId == userId)
        .toList();

    // Simple search implementation
    final lowercaseQuery = query.toLowerCase();
    final results = <Entry>[];

    for (final entry in travelEntries) {
      // Search in departure, arrival, and notes
      final origin = _getOrigin(entry);
      final destination = _getDestination(entry);
      final fromMatch =
          origin?.toLowerCase().contains(lowercaseQuery) ?? false;
      final toMatch = destination?.toLowerCase().contains(lowercaseQuery) ?? false;
      final notesMatch =
          entry.notes?.toLowerCase().contains(lowercaseQuery) ?? false;

      if (fromMatch || toMatch || notesMatch) {
        results.add(entry);
      }
    }

    return results;
  }

  String _currentUserId() {
    // This service isn't a widget; prefer using a global/provider lookup pattern.
    // For now, require that callers have set up a Provider scope and retrieve via
    // Navigation or a service locator. Here we fall back to throwing if missing.
    try {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        final auth = Provider.of<AuthService>(ctx, listen: false);
        final uid = auth.currentUserId;
        if (uid != null) return uid;
      }
    } catch (_) {}
    throw Exception('No authenticated user');
  }
}
