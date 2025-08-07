import 'package:flutter/foundation.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../repositories/repository_provider.dart';

/// View model for customer-facing analytics
class CustomerAnalyticsViewModel extends ChangeNotifier {
  final RepositoryProvider _repository;
  final String userId;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Overview metrics
  int _totalTravelMinutes = 0;
  int _totalWorkMinutes = 0;
  int _totalEntries = 0;
  double _contractCompletion = 0.0;

  // Trends data
  final List<DailyTrend> _dailyTrends = [];

  // Location analytics
  final Map<String, LocationAnalytics> _locationAnalytics = {};

  CustomerAnalyticsViewModel({
    required RepositoryProvider repository,
    required this.userId,
  }) : _repository = repository {
    loadData();
  }

  // Getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalTravelMinutes => _totalTravelMinutes;
  int get totalWorkMinutes => _totalWorkMinutes;
  int get totalEntries => _totalEntries;
  double get contractCompletion => _contractCompletion;
  List<DailyTrend> get dailyTrends => List.unmodifiable(_dailyTrends);
  Map<String, LocationAnalytics> get locationAnalytics =>
      Map.unmodifiable(_locationAnalytics);

  /// Update the date range and reload data
  Future<void> updateDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    await loadData();
  }

  /// Load all analytics data for the current date range
  Future<void> loadData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load entries for the date range
      final travelEntries = _repository.travelRepository
          .getAllForUser(userId)
          .where((e) => _isInRange(e.date))
          .toList();

      final workEntries = _repository.workRepository
          .getAllForUser(userId)
          .where((e) => _isInRange(e.date))
          .toList();

      // Calculate overview metrics
      _totalTravelMinutes =
          travelEntries.fold(0, (sum, entry) => sum + entry.travelMinutes);
      _totalWorkMinutes =
          workEntries.fold(0, (sum, entry) => sum + entry.workMinutes);
      _totalEntries = travelEntries.length + workEntries.length;

      // Calculate contract completion
  final contractSettings = _repository.contractRepository.getSettings();
  if (contractSettings != null) {
    final targetMinutes = contractSettings.targetHours * 60;
    final totalMinutes = _totalWorkMinutes + _totalTravelMinutes;
    _contractCompletion = targetMinutes > 0 ? totalMinutes / targetMinutes : 0.0;
  } else {
    _contractCompletion = 0.0;
  }

      // Calculate daily trends
      _calculateDailyTrends(travelEntries, workEntries);

      // Calculate location analytics
      _calculateLocationAnalytics(travelEntries);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load analytics data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isInRange(DateTime date) {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    return date.isAfter(start) && date.isBefore(end);
  }

  void _calculateDailyTrends(
      List<TravelEntry> travelEntries, List<WorkEntry> workEntries) {
    _dailyTrends.clear();

    // Create a map of date to minutes
    final dailyMinutes = <DateTime, _DailyMinutes>{};

    // Process travel entries
    for (final entry in travelEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      dailyMinutes.putIfAbsent(date, () => _DailyMinutes());
      dailyMinutes[date]!.travelMinutes += entry.travelMinutes;
    }

    // Process work entries
    for (final entry in workEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      dailyMinutes.putIfAbsent(date, () => _DailyMinutes());
      dailyMinutes[date]!.workMinutes += entry.workMinutes;
    }

    // Convert to DailyTrend objects
    final trends = dailyMinutes.entries.map((e) => DailyTrend(
          date: e.key,
          travelMinutes: e.value.travelMinutes,
          workMinutes: e.value.workMinutes,
        ));

    // Sort by date and add to list
    _dailyTrends.addAll(trends);
    _dailyTrends.sort((a, b) => a.date.compareTo(b.date));
  }

  void _calculateLocationAnalytics(List<TravelEntry> entries) {
    _locationAnalytics.clear();

    // Group entries by location
    for (final entry in entries) {
      // Process 'from' location
      _locationAnalytics.putIfAbsent(entry.fromLocation,
          () => LocationAnalytics(name: entry.fromLocation));
      _locationAnalytics[entry.fromLocation]!.totalVisits++;
      _locationAnalytics[entry.fromLocation]!.totalMinutes +=
          entry.travelMinutes;

      // Process 'to' location
      _locationAnalytics.putIfAbsent(
          entry.toLocation, () => LocationAnalytics(name: entry.toLocation));
      _locationAnalytics[entry.toLocation]!.totalVisits++;
      _locationAnalytics[entry.toLocation]!.totalMinutes += entry.travelMinutes;
    }
  }
}

/// Helper class for calculating daily minutes
class _DailyMinutes {
  int travelMinutes = 0;
  int workMinutes = 0;
}

/// Represents analytics data for a single day
class DailyTrend {
  final DateTime date;
  final int travelMinutes;
  final int workMinutes;

  DailyTrend({
    required this.date,
    required this.travelMinutes,
    required this.workMinutes,
  });

  int get totalMinutes => travelMinutes + workMinutes;
}

/// Represents analytics data for a location
class LocationAnalytics {
  final String name;
  int totalVisits = 0;
  int totalMinutes = 0;

  LocationAnalytics({required this.name});
}
