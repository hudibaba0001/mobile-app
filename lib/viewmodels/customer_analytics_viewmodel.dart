import 'package:flutter/foundation.dart';
import '../models/work_entry.dart';
import '../models/travel_entry.dart';
import '../repositories/work_repository.dart';
import '../repositories/travel_repository.dart';

class CustomerAnalyticsViewModel extends ChangeNotifier {
  // Data storage
  List<WorkEntry> _workEntries = [];
  List<TravelEntry> _travelEntries = [];

  // Date range filtering
  DateTime? _startDate;
  DateTime? _endDate;

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // User ID
  String _userId = 'default_user';

  // Repositories
  WorkRepository? _workRepository;
  TravelRepository? _travelRepository;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Overview Tab Data
  Map<String, dynamic> get overviewData {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();

    final totalWorkMinutes = filteredWorkEntries.fold<int>(
        0, (sum, entry) => sum + entry.workMinutes);
    final totalTravelMinutes = filteredTravelEntries.fold<int>(
        0, (sum, entry) => sum + entry.travelMinutes);

    final totalHours = (totalWorkMinutes + totalTravelMinutes) / 60.0;
    final totalEntries =
        filteredWorkEntries.length + filteredTravelEntries.length;

    return {
      'totalHours': totalHours,
      'totalEntries': totalEntries,
      'totalWorkMinutes': totalWorkMinutes,
      'totalTravelMinutes': totalTravelMinutes,
      'quickInsights':
          _generateQuickInsights(filteredWorkEntries, filteredTravelEntries),
    };
  }

  // Trends Tab Data
  Map<String, dynamic> get trendsData {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();

    return {
      'weeklyHours':
          _calculateWeeklyHours(filteredWorkEntries, filteredTravelEntries),
      'monthlyComparison': _calculateMonthlyComparison(filteredWorkEntries),
      'dailyTrends':
          _calculateDailyTrends(filteredWorkEntries, filteredTravelEntries),
    };
  }

  // Locations Tab Data
  List<Map<String, dynamic>> get locationsData {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();

    return _calculateLocationData(filteredWorkEntries, filteredTravelEntries);
  }

  // Initialize with repositories
  void initialize(
      WorkRepository? workRepository, TravelRepository? travelRepository,
      {String? userId}) {
    _workRepository = workRepository;
    _travelRepository = travelRepository;
    _userId = userId ?? 'default_user';
    _loadData();
  }

  // Load data from repositories
  Future<void> _loadData() async {
    if (_workRepository == null || _travelRepository == null) return;

    _setLoading(true);
    try {
      _workEntries = _workRepository!.getAllForUser(_userId);
      _travelEntries = _travelRepository!.getAllForUser(_userId);

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load data: $e');
    }
  }

  // Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }

  // Helper methods
  List<WorkEntry> _getFilteredWorkEntries() {
    if (_startDate == null && _endDate == null) {
      return _workEntries;
    }

    return _workEntries.where((entry) {
      if (_startDate != null && entry.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.date.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TravelEntry> _getFilteredTravelEntries() {
    if (_startDate == null && _endDate == null) {
      return _travelEntries;
    }

    return _travelEntries.where((entry) {
      if (_startDate != null && entry.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.date.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _generateQuickInsights(
      List<WorkEntry> workEntries, List<TravelEntry> travelEntries) {
    final insights = <Map<String, dynamic>>[];

    if (workEntries.isNotEmpty) {
      // Find peak performance day
      final dailyHours = <String, double>{};
      for (final entry in workEntries) {
        final day = _getDayName(entry.date.weekday);
        dailyHours[day] = (dailyHours[day] ?? 0) + (entry.workMinutes / 60.0);
      }

      if (dailyHours.isNotEmpty) {
        final peakDay =
            dailyHours.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add({
          'title': 'Peak Performance',
          'description':
              'Your most productive day was $peakDay with ${peakDay.value.toStringAsFixed(1)} hours',
          'icon': '📈',
          'trend': 'positive',
        });
      }
    }

    if (travelEntries.isNotEmpty) {
      // Location insights
      final locationCounts = <String, int>{};
      for (final entry in travelEntries) {
        locationCounts[entry.fromLocation] =
            (locationCounts[entry.fromLocation] ?? 0) + 1;
        locationCounts[entry.toLocation] =
            (locationCounts[entry.toLocation] ?? 0) + 1;
      }

      if (locationCounts.isNotEmpty) {
        final mostFrequentLocation =
            locationCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add({
          'title': 'Location Insights',
          'description': '$mostFrequentLocation is your most frequent location',
          'icon': '📍',
          'trend': 'neutral',
        });
      }
    }

    // Time management insight
    final totalWorkHours =
        workEntries.fold<int>(0, (sum, entry) => sum + entry.workMinutes) /
            60.0;
    if (totalWorkHours > 0) {
      insights.add({
        'title': 'Time Management',
        'description':
            'You worked ${totalWorkHours.toStringAsFixed(1)} hours in this period',
        'icon': '⏰',
        'trend': 'positive',
      });
    }

    return insights;
  }

  List<double> _calculateWeeklyHours(
      List<WorkEntry> workEntries, List<TravelEntry> travelEntries) {
    final weeklyHours = List<double>.filled(7, 0.0);

    for (final entry in workEntries) {
      final weekDay = entry.date.weekday - 1;
      weeklyHours[weekDay] += entry.workMinutes / 60.0;
    }

    for (final entry in travelEntries) {
      final weekDay = entry.date.weekday - 1;
      weeklyHours[weekDay] += entry.travelMinutes / 60.0;
    }

    return weeklyHours;
  }

  Map<String, dynamic> _calculateMonthlyComparison(List<WorkEntry> entries) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    final currentMonthEntries = entries
        .where((entry) =>
            entry.date.year == currentMonth.year &&
            entry.date.month == currentMonth.month)
        .toList();
    final previousMonthEntries = entries
        .where((entry) =>
            entry.date.year == previousMonth.year &&
            entry.date.month == previousMonth.month)
        .toList();

    final currentMonthHours = currentMonthEntries.fold<int>(
            0, (sum, entry) => sum + entry.workMinutes) /
        60.0;
    final previousMonthHours = previousMonthEntries.fold<int>(
            0, (sum, entry) => sum + entry.workMinutes) /
        60.0;

    final percentageChange = previousMonthHours > 0
        ? ((currentMonthHours - previousMonthHours) / previousMonthHours) * 100
        : 0.0;

    return {
      'currentMonth': currentMonthHours,
      'previousMonth': previousMonthHours,
      'percentageChange': percentageChange,
    };
  }

  List<Map<String, dynamic>> _calculateDailyTrends(
      List<WorkEntry> workEntries, List<TravelEntry> travelEntries) {
    final dailyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Get last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEntries = workEntries
          .where((entry) =>
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day)
          .toList();

      final dayTravelEntries = travelEntries
          .where((entry) =>
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day)
          .toList();

      final workHours =
          dayEntries.fold<int>(0, (sum, entry) => sum + entry.workMinutes) /
              60.0;
      final travelHours = dayTravelEntries.fold<int>(
              0, (sum, entry) => sum + entry.travelMinutes) /
          60.0;

      dailyData.add({
        'date': date,
        'workHours': workHours,
        'travelHours': travelHours,
        'totalHours': workHours + travelHours,
      });
    }

    return dailyData;
  }

  List<Map<String, dynamic>> _calculateLocationData(
      List<WorkEntry> workEntries, List<TravelEntry> travelEntries) {
    final locationMap = <String, Map<String, dynamic>>{};
    final totalWorkMinutes =
        workEntries.fold<int>(0, (sum, entry) => sum + entry.workMinutes);
    final totalTravelMinutes =
        travelEntries.fold<int>(0, (sum, entry) => sum + entry.travelMinutes);

    // Process work entries (locations from remarks or default)
    for (final entry in workEntries) {
      final location = entry.remarks.isNotEmpty ? entry.remarks : 'Office';
      if (!locationMap.containsKey(location)) {
        locationMap[location] = {
          'name': location,
          'totalHours': 0.0,
          'workMinutes': 0,
          'travelMinutes': 0,
        };
      }
      locationMap[location]!['workMinutes'] += entry.workMinutes;
      locationMap[location]!['totalHours'] += entry.workMinutes / 60.0;
    }

    // Process travel entries
    for (final entry in travelEntries) {
      // Add from location
      if (!locationMap.containsKey(entry.fromLocation)) {
        locationMap[entry.fromLocation] = {
          'name': entry.fromLocation,
          'totalHours': 0.0,
          'workMinutes': 0,
          'travelMinutes': 0,
        };
      }
      locationMap[entry.fromLocation]!['travelMinutes'] += entry.travelMinutes;
      locationMap[entry.fromLocation]!['totalHours'] +=
          entry.travelMinutes / 60.0;

      // Add to location
      if (!locationMap.containsKey(entry.toLocation)) {
        locationMap[entry.toLocation] = {
          'name': entry.toLocation,
          'totalHours': 0.0,
          'workMinutes': 0,
          'travelMinutes': 0,
        };
      }
      locationMap[entry.toLocation]!['travelMinutes'] += entry.travelMinutes;
      locationMap[entry.toLocation]!['totalHours'] +=
          entry.travelMinutes / 60.0;
    }

    // Convert to list and calculate percentages
    final totalHours = totalWorkMinutes / 60.0 + totalTravelMinutes / 60.0;
    final locationsList = locationMap.values.toList();

    for (final location in locationsList) {
      location['percentage'] =
          totalHours > 0 ? (location['totalHours'] / totalHours) * 100 : 0.0;
    }

    // Sort by total hours and add colors
    locationsList.sort((a, b) => b['totalHours'].compareTo(a['totalHours']));

    final colors = [
      0xFF4CAF50,
      0xFF2196F3,
      0xFFFF9800,
      0xFF9C27B0,
      0xFF607D8B,
      0xFFE91E63,
      0xFF3F51B5,
      0xFF009688,
      0xFFFF5722,
      0xFF795548,
    ];

    for (int i = 0; i < locationsList.length; i++) {
      locationsList[i]['color'] = colors[i % colors.length];
    }

    return locationsList;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }
}
