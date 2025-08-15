import 'package:flutter/foundation.dart';

class CustomerAnalyticsViewModel extends ChangeNotifier {
  // Overview Tab Data
  Map<String, dynamic> _overviewData = {
    'totalHours': 156.5,
    'totalEarnings': 2340.75,
    'averageHourlyRate': 15.0,
    'totalEntries': 89,
    'quickInsights': [
      {
        'title': 'Peak Performance',
        'description': 'Your highest earning day was Tuesday with \$180',
        'icon': '📈',
        'trend': 'positive',
      },
      {
        'title': 'Location Insights',
        'description': 'Office A is your most productive location',
        'icon': '📍',
        'trend': 'neutral',
      },
      {
        'title': 'Time Management',
        'description': 'You worked 8% more hours this week',
        'icon': '⏰',
        'trend': 'positive',
      },
    ],
  };

  // Trends Tab Data
  Map<String, dynamic> _trendsData = {
    'weeklyEarnings': [1200, 1350, 1100, 1400, 1600, 1800, 1700],
    'weeklyHours': [40, 42, 38, 45, 48, 50, 47],
    'monthlyComparison': {
      'currentMonth': 6800,
      'previousMonth': 6200,
      'percentageChange': 9.7,
    },
  };

  // Locations Tab Data
  List<Map<String, dynamic>> _locationsData = [
    {
      'name': 'Office A',
      'totalHours': 45.5,
      'totalEarnings': 682.50,
      'percentage': 29.1,
      'color': 0xFF4CAF50,
    },
    {
      'name': 'Client Site B',
      'totalHours': 38.0,
      'totalEarnings': 570.00,
      'percentage': 24.4,
      'color': 0xFF2196F3,
    },
    {
      'name': 'Home Office',
      'totalHours': 32.0,
      'totalEarnings': 480.00,
      'percentage': 20.5,
      'color': 0xFFFF9800,
    },
    {
      'name': 'Remote Location C',
      'totalHours': 28.0,
      'totalEarnings': 420.00,
      'percentage': 17.9,
      'color': 0xFF9C27B0,
    },
    {
      'name': 'Other',
      'totalHours': 13.0,
      'totalEarnings': 195.00,
      'percentage': 8.1,
      'color': 0xFF607D8B,
    },
  ];

  // Getters
  Map<String, dynamic> get overviewData => _overviewData;
  Map<String, dynamic> get trendsData => _trendsData;
  List<Map<String, dynamic>> get locationsData => _locationsData;

  // Methods to update data (for future live data integration)
  void updateOverviewData(Map<String, dynamic> newData) {
    _overviewData = newData;
    notifyListeners();
  }

  void updateTrendsData(Map<String, dynamic> newData) {
    _trendsData = newData;
    notifyListeners();
  }

  void updateLocationsData(List<Map<String, dynamic>> newData) {
    _locationsData = newData;
    notifyListeners();
  }

  // Method to refresh all data (for future API integration)
  Future<void> refreshData() async {
    // TODO: Implement API calls to fetch live data
    // For now, just notify listeners to trigger UI refresh
    notifyListeners();
  }
}
