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