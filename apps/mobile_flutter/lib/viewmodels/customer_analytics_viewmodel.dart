import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../config/app_config.dart';
import '../features/reports/analytics_models.dart';
import '../services/analytics_api.dart';

class MonthlyBreakdown {
  final DateTime month;
  final double workHours;
  final double travelHours;
  final double totalHours;

  const MonthlyBreakdown({
    required this.month,
    required this.workHours,
    required this.travelHours,
    required this.totalHours,
  });
}

class _MonthlyAccumulator {
  double workHours = 0.0;
  double travelHours = 0.0;
}

class CustomerAnalyticsViewModel extends ChangeNotifier {
  CustomerAnalyticsViewModel({AnalyticsApi? analyticsApi})
      : _api = analyticsApi ?? AnalyticsApi();

  // Data storage
  List<Entry> _entries = [];

  // Date range filtering
  DateTime? _startDate;
  DateTime? _endDate;

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Server analytics state
  final AnalyticsApi _api;
  ServerAnalytics? _server;
  bool _usingServer = false;
  String? _lastServerError;
  bool _serverFetchInProgress = false;

  // User ID
  String _userId = 'default_user';
  bool _initialized = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get usingServer => _usingServer;
  String? get lastServerError => _lastServerError;

  // Bind entries from EntryProvider and keep analytics in sync.
  void bindEntries(
    List<Entry> entries, {
    String? userId,
    bool isLoading = false,
    String? errorMessage,
  }) {
    final nextUserId = userId ?? _userId;
    final userChanged = nextUserId != _userId;

    _userId = nextUserId;
    _entries = List<Entry>.from(entries);
    _isLoading = isLoading;
    _errorMessage = errorMessage;

    if (!_initialized || userChanged) {
      _initialized = true;
      _loadServerIfConfigured();
    }

    notifyListeners();
  }

  Future<void> _loadServerIfConfigured() async {
    if (AppConfig.apiBase.trim().isEmpty) {
      _usingServer = false;
      _lastServerError = null;
      return;
    }
    if (_serverFetchInProgress) return;
    _serverFetchInProgress = true;
    final ok = await _tryLoadServer();
    _usingServer = ok;
    _serverFetchInProgress = false;
    notifyListeners();
  }

  // Overview Tab Data
  Map<String, dynamic> get overviewData {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();

    final totalWorkMinutes = filteredWorkEntries.fold<int>(
        0, (sum, entry) => sum + _workMinutesForEntry(entry));
    final totalTravelMinutes = filteredTravelEntries.fold<int>(
        0, (sum, entry) => sum + _travelMinutesForEntry(entry));

    // Prefer server total hours when available; fall back to local.
    final serverTotalHours =
        _server?.dailyTrends.fold<double>(0.0, (sum, t) => sum + t.totalHours);
    final totalHours = _usingServer && serverTotalHours != null
        ? serverTotalHours
        : (totalWorkMinutes + totalTravelMinutes) / 60.0;

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

    // If server analytics available, map daily trends and weekly hours from it.
    if (_usingServer && _server != null) {
      // Weekly hours: sum per weekday from server daily trends if we have data points.
      List<double> weeklyHours;
      if (_server!.dailyTrends.isNotEmpty) {
        // Initialize Mon..Sun
        weeklyHours = List<double>.filled(7, 0.0);
        for (final t in _server!.dailyTrends) {
          final wd = t.date.weekday - 1; // 0..6
          if (wd >= 0 && wd < 7) {
            weeklyHours[wd] += t.totalHours;
          }
        }
      } else {
        weeklyHours =
            _calculateWeeklyHours(filteredWorkEntries, filteredTravelEntries);
      }

      final dailyTrends = _server!.dailyTrends
          .map((t) => {
                'date': t.date,
                'workHours': t.workHours,
                'travelHours': t.travelHours,
                'totalHours': t.totalHours,
              })
          .toList(growable: false);

      return {
        'weeklyHours': weeklyHours,
        // Monthly comparison still derived locally to avoid overreach.
        'monthlyComparison': _calculateMonthlyComparison(filteredWorkEntries),
        'dailyTrends': dailyTrends,
      };
    }

    // Fallback to local-only analytics
    return {
      'weeklyHours':
          _calculateWeeklyHours(filteredWorkEntries, filteredTravelEntries),
      'monthlyComparison': _calculateMonthlyComparison(filteredWorkEntries),
      'dailyTrends':
          _calculateDailyTrends(filteredWorkEntries, filteredTravelEntries),
    };
  }

  List<MonthlyBreakdown> get monthlyBreakdown {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();
    return _calculateMonthlyBreakdown(filteredWorkEntries, filteredTravelEntries);
  }

  // Locations Tab Data
  List<Map<String, dynamic>> get locationsData {
    final filteredWorkEntries = _getFilteredWorkEntries();
    final filteredTravelEntries = _getFilteredTravelEntries();

    return _calculateLocationData(filteredWorkEntries, filteredTravelEntries);
  }

  // Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    // Refresh server analytics for the new range without blocking UI
    if (AppConfig.apiBase.trim().isNotEmpty) {
      _loadServerIfConfigured();
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    if (AppConfig.apiBase.trim().isNotEmpty) {
      final ok = await _tryLoadServer();
      _usingServer = ok;
      notifyListeners();
      return;
    }
    _usingServer = false;
    _lastServerError = null;
    notifyListeners();
  }

  Future<bool> _tryLoadServer() async {
    try {
      final result = await _api.fetchDashboard(
        startDate: _startDate,
        endDate: _endDate,
        userId: _userId,
      );
      _server = result;
      _lastServerError = null;
      return true;
    } catch (e) {
      _server = null;
      if (e is AuthException) {
        _lastServerError = 'Access denied. Please contact support.';
      } else {
        _lastServerError = e.toString();
      }
      return false;
    }
  }

  // Helper methods
  List<Entry> _getFilteredEntries({EntryType? type}) {
    if (_startDate == null && _endDate == null) {
      if (type == null) return _entries;
      return _entries.where((entry) => entry.type == type).toList();
    }

    return _entries.where((entry) {
      if (type != null && entry.type != type) {
        return false;
      }
      if (_startDate != null && entry.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.date.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Entry> _getFilteredWorkEntries() =>
      _getFilteredEntries(type: EntryType.work);
  List<Entry> _getFilteredTravelEntries() =>
      _getFilteredEntries(type: EntryType.travel);

  int _workMinutesForEntry(Entry entry) {
    if (entry.type != EntryType.work) return 0;
    return entry.totalWorkDuration?.inMinutes ?? 0;
  }

  int _travelMinutesForEntry(Entry entry) {
    if (entry.type != EntryType.travel) return 0;
    return entry.travelDuration.inMinutes;
  }

  List<Map<String, dynamic>> _generateQuickInsights(
      List<Entry> workEntries, List<Entry> travelEntries) {
    final insights = <Map<String, dynamic>>[];

    if (workEntries.isNotEmpty) {
      // Find peak performance day
      final dailyHours = <String, double>{};
      for (final entry in workEntries) {
        final day = _getDayName(entry.date.weekday);
        dailyHours[day] =
            (dailyHours[day] ?? 0) + (_workMinutesForEntry(entry) / 60.0);
      }

      if (dailyHours.isNotEmpty) {
        final peakDay =
            dailyHours.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add({
          'key': 'peak_performance',
          'day': peakDay.key,
          'hours': peakDay.value.toStringAsFixed(1),
          'icon': 'ðŸ“ˆ',
          'trend': 'positive',
        });
      }
    }

    if (travelEntries.isNotEmpty) {
      // Location insights
      final locationCounts = <String, int>{};
      for (final entry in travelEntries) {
        if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
          for (final leg in entry.travelLegs!) {
            locationCounts[leg.fromText] =
                (locationCounts[leg.fromText] ?? 0) + 1;
            locationCounts[leg.toText] =
                (locationCounts[leg.toText] ?? 0) + 1;
          }
        } else {
          if (entry.from != null && entry.from!.isNotEmpty) {
            locationCounts[entry.from!] =
                (locationCounts[entry.from!] ?? 0) + 1;
          }
          if (entry.to != null && entry.to!.isNotEmpty) {
            locationCounts[entry.to!] =
                (locationCounts[entry.to!] ?? 0) + 1;
          }
        }
      }

      if (locationCounts.isNotEmpty) {
        final mostFrequentLocation =
            locationCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add({
          'key': 'location_insights',
          'location': mostFrequentLocation.key,
          'icon': 'ðŸ“',
          'trend': 'neutral',
        });
      }
    }

    // Time management insight
    final totalWorkHours =
        workEntries.fold<int>(0, (sum, entry) => sum + _workMinutesForEntry(entry)) /
            60.0;
    if (totalWorkHours > 0) {
      insights.add({
        'key': 'time_management',
        'hours': totalWorkHours.toStringAsFixed(1),
        'icon': 'â°',
        'trend': 'positive',
      });
    }

    return insights;
  }

  List<double> _calculateWeeklyHours(
      List<Entry> workEntries, List<Entry> travelEntries) {
    final weeklyHours = List<double>.filled(7, 0.0);

    for (final entry in workEntries) {
      final weekDay = entry.date.weekday - 1;
      if (weekDay >= 0 && weekDay < 7) {
        weeklyHours[weekDay] += _workMinutesForEntry(entry) / 60.0;
      }
    }

    for (final entry in travelEntries) {
      final weekDay = entry.date.weekday - 1;
      if (weekDay >= 0 && weekDay < 7) {
        weeklyHours[weekDay] += _travelMinutesForEntry(entry) / 60.0;
      }
    }

    return weeklyHours;
  }

  List<MonthlyBreakdown> _calculateMonthlyBreakdown(
      List<Entry> workEntries, List<Entry> travelEntries) {
    final now = DateTime.now();

    DateTime startMonth;
    DateTime endMonth;

    if (_startDate != null && _endDate != null) {
      startMonth = DateTime(_startDate!.year, _startDate!.month);
      endMonth = DateTime(_endDate!.year, _endDate!.month);
    } else if (_startDate != null) {
      startMonth = DateTime(_startDate!.year, _startDate!.month);
      endMonth = DateTime(now.year, now.month);
    } else if (_endDate != null) {
      endMonth = DateTime(_endDate!.year, _endDate!.month);
      startMonth = DateTime(endMonth.year, endMonth.month - 11);
    } else {
      endMonth = DateTime(now.year, now.month);
      startMonth = DateTime(now.year, now.month - 11);
    }

    final months = <DateTime>[];
    for (var month = DateTime(startMonth.year, startMonth.month);
        !month.isAfter(endMonth);
        month = DateTime(month.year, month.month + 1)) {
      months.add(month);
    }

    final buckets = <String, _MonthlyAccumulator>{};
    for (final month in months) {
      buckets[_monthKey(month)] = _MonthlyAccumulator();
    }

    for (final entry in workEntries) {
      final bucket = buckets[_monthKey(entry.date)];
      if (bucket != null) {
        bucket.workHours += _workMinutesForEntry(entry) / 60.0;
      }
    }

    for (final entry in travelEntries) {
      final bucket = buckets[_monthKey(entry.date)];
      if (bucket != null) {
        bucket.travelHours += _travelMinutesForEntry(entry) / 60.0;
      }
    }

    return months.map((month) {
      final bucket = buckets[_monthKey(month)]!;
      final total = bucket.workHours + bucket.travelHours;
      return MonthlyBreakdown(
        month: month,
        workHours: bucket.workHours,
        travelHours: bucket.travelHours,
        totalHours: total,
      );
    }).toList(growable: false);
  }

  Map<String, dynamic> _calculateMonthlyComparison(List<Entry> entries) {
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
            0, (sum, entry) => sum + _workMinutesForEntry(entry)) /
        60.0;
    final previousMonthHours = previousMonthEntries.fold<int>(
            0, (sum, entry) => sum + _workMinutesForEntry(entry)) /
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
      List<Entry> workEntries, List<Entry> travelEntries) {
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

      final workHours = dayEntries.fold<int>(
              0, (sum, entry) => sum + _workMinutesForEntry(entry)) /
          60.0;
      final travelHours = dayTravelEntries.fold<int>(
              0, (sum, entry) => sum + _travelMinutesForEntry(entry)) /
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
      List<Entry> workEntries, List<Entry> travelEntries) {
    final locationMap = <String, Map<String, dynamic>>{};
    final totalWorkMinutes =
        workEntries.fold<int>(0, (sum, entry) => sum + _workMinutesForEntry(entry));
    final totalTravelMinutes =
        travelEntries.fold<int>(0, (sum, entry) => sum + _travelMinutesForEntry(entry));

    // Process work entries (locations from shift location or default)
    for (final entry in workEntries) {
      final location = _resolveWorkLocation(entry);
      if (!locationMap.containsKey(location)) {
        locationMap[location] = {
          'name': location,
          'totalHours': 0.0,
          'workMinutes': 0,
          'travelMinutes': 0,
        };
      }
      final workMinutes = _workMinutesForEntry(entry);
      locationMap[location]!['workMinutes'] += workMinutes;
      locationMap[location]!['totalHours'] += workMinutes / 60.0;
    }

    // Process travel entries
    for (final entry in travelEntries) {
      if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
        for (final leg in entry.travelLegs!) {
          _addTravelLocation(locationMap, leg.fromText, leg.minutes);
          _addTravelLocation(locationMap, leg.toText, leg.minutes);
        }
      } else {
        final minutes = _travelMinutesForEntry(entry);
        _addTravelLocation(locationMap, entry.from ?? '', minutes);
        _addTravelLocation(locationMap, entry.to ?? '', minutes);
      }
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

  void _addTravelLocation(
      Map<String, Map<String, dynamic>> locationMap, String location, int minutes) {
    if (location.isEmpty) return;
    if (!locationMap.containsKey(location)) {
      locationMap[location] = {
        'name': location,
        'totalHours': 0.0,
        'workMinutes': 0,
        'travelMinutes': 0,
      };
    }
    locationMap[location]!['travelMinutes'] += minutes;
    locationMap[location]!['totalHours'] += minutes / 60.0;
  }

  String _resolveWorkLocation(Entry entry) {
    final location = entry.workLocation;
    if (location != null && location.isNotEmpty) return location;
    final notes = entry.notes;
    if (notes != null && notes.isNotEmpty) return notes;
    return 'Office';
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
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
}
