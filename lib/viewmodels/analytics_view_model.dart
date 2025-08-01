import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../repositories/repository_provider.dart';

/// Analytics data for a specific date range
class AnalyticsData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalTrips;
  final int totalWorkMinutes;
  final int totalTravelMinutes;
  final double averageTripDuration;
  final double averageWorkHours;
  final Map<String, int> locationFrequency;
  final Map<String, int> departureFrequency;
  final Map<String, int> arrivalFrequency;

  AnalyticsData({
    required this.startDate,
    required this.endDate,
    required this.totalTrips,
    required this.totalWorkMinutes,
    required this.totalTravelMinutes,
    required this.averageTripDuration,
    required this.averageWorkHours,
    required this.locationFrequency,
    required this.departureFrequency,
    required this.arrivalFrequency,
  });

  /// Total combined time (work + travel)
  int get totalCombinedMinutes => totalWorkMinutes + totalTravelMinutes;

  /// Total combined time formatted as hours and minutes
  String get formattedTotalTime {
    final hours = totalCombinedMinutes ~/ 60;
    final minutes = totalCombinedMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Total work time formatted as hours and minutes
  String get formattedWorkTime {
    final hours = totalWorkMinutes ~/ 60;
    final minutes = totalWorkMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Total travel time formatted as hours and minutes
  String get formattedTravelTime {
    final hours = totalTravelMinutes ~/ 60;
    final minutes = totalTravelMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Daily average combined time
  double get dailyAverageMinutes {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalCombinedMinutes / days : 0;
  }

  /// Most frequent route
  String get mostFrequentRoute {
    if (locationFrequency.isEmpty) return 'No routes';
    final sorted = locationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

/// ViewModel for analytics and reporting functionality
class AnalyticsViewModel extends ChangeNotifier {
  final RepositoryProvider _repositoryProvider;
  
  AnalyticsData? _analyticsData;
  bool _isLoading = false;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  AnalyticsViewModel(this._repositoryProvider);

  // Getters
  AnalyticsData? get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  /// Fetch overview data for the specified date range
  Future<void> fetchOverviewData({DateTime? startDate, DateTime? endDate}) async {
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;

    _setLoading(true);
    _clearError();

    try {
      // For now, we'll use mock data to establish the structure
      // TODO: Integrate with actual repositories when they're available
      _analyticsData = _generateMockData();
      
    } catch (e) {
      _setError('Failed to fetch analytics data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Generate mock data for testing
  AnalyticsData _generateMockData() {
    final locationFrequency = <String, int>{
      'postflyget → torslanda': 1,
      'torslanda → postflyget': 1,
    };
    
    final departureFrequency = <String, int>{
      'postflyget': 1,
      'torslanda': 1,
    };
    
    final arrivalFrequency = <String, int>{
      'torslanda': 1,
      'postflyget': 1,
    };

    return AnalyticsData(
      startDate: _startDate,
      endDate: _endDate,
      totalTrips: 1,
      totalWorkMinutes: 480, // 8 hours
      totalTravelMinutes: 80, // 1h 20m
      averageTripDuration: 80.0,
      averageWorkHours: 8.0,
      locationFrequency: locationFrequency,
      departureFrequency: departureFrequency,
      arrivalFrequency: arrivalFrequency,
    );
  }

  /// Refresh analytics data
  Future<void> refresh() async {
    await fetchOverviewData();
  }

  /// Set date range and refresh data
  Future<void> setDateRange(DateTime start, DateTime end) async {
    await fetchOverviewData(startDate: start, endDate: end);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 