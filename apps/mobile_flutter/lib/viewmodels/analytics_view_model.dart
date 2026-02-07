import 'package:flutter/foundation.dart';
import '../services/admin_api_service.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;

  AnalyticsViewModel(this._apiService);

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedUserId => _selectedUserId;

  /// Fetches dashboard data from the API
  Future<void> fetchDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      _dashboardData = await _apiService.fetchDashboardData(
        startDate: _startDate,
        endDate: _endDate,
        userId: _selectedUserId,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the date range for filtering
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  /// Sets the selected user for filtering
  void setSelectedUser(String? userId) {
    _selectedUserId = userId;
    notifyListeners();
  }

  /// Refreshes the dashboard data
  Future<void> refresh() async {
    await fetchDashboardData();
  }

  /// Loads mock data for testing
  void loadMockData() {
    _setLoading(true);
    _clearError();

    // Simulate API delay
    Future.delayed(const Duration(seconds: 1), () {
      _dashboardData = DashboardData(
        totalHoursLoggedThisWeek: 45.5,
        activeUsers: 12,
        overtimeBalance: 8.5,
        averageDailyHours: 7.2,
        dailyTrends: [
          DailyTrend(
              date: 'Mon', totalHours: 8.0, workHours: 6.0, travelHours: 2.0),
          DailyTrend(
              date: 'Tue', totalHours: 7.5, workHours: 6.5, travelHours: 1.0),
          DailyTrend(
              date: 'Wed', totalHours: 9.0, workHours: 7.0, travelHours: 2.0),
          DailyTrend(
              date: 'Thu', totalHours: 6.5, workHours: 5.5, travelHours: 1.0),
          DailyTrend(
              date: 'Fri', totalHours: 8.5, workHours: 7.5, travelHours: 1.0),
          DailyTrend(
              date: 'Sat', totalHours: 4.0, workHours: 3.0, travelHours: 1.0),
          DailyTrend(
              date: 'Sun', totalHours: 2.0, workHours: 1.5, travelHours: 0.5),
        ],
        userDistribution: [
          UserDistribution(
              userId: '1',
              userName: 'John Doe',
              totalHours: 12.5,
              percentage: 27.5),
          UserDistribution(
              userId: '2',
              userName: 'Jane Smith',
              totalHours: 10.0,
              percentage: 22.0),
          UserDistribution(
              userId: '3',
              userName: 'Bob Johnson',
              totalHours: 8.5,
              percentage: 18.7),
          UserDistribution(
              userId: '4',
              userName: 'Alice Brown',
              totalHours: 7.0,
              percentage: 15.4),
          UserDistribution(
              userId: '5',
              userName: 'Charlie Wilson',
              totalHours: 7.5,
              percentage: 16.4),
        ],
        availableUsers: [
          AvailableUser(userId: '1', userName: 'John Doe'),
          AvailableUser(userId: '2', userName: 'Jane Smith'),
          AvailableUser(userId: '3', userName: 'Bob Johnson'),
        ],
      );
      _setLoading(false);
    });
  }

  /// Clears all filters
  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedUserId = null;
    notifyListeners();
  }

  // Private methods
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
