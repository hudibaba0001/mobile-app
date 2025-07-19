class AppConstants {
  // Hive box names
  static const String travelEntriesBox = 'travelEntriesBox';
  static const String locationsBox = 'locationsBox';
  static const String appSettingsBox = 'app_settings';
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'MMM dd, yyyy';
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Validation
  static const int maxLocationNameLength = 100;
  static const int maxAddressLength = 200;
  static const int maxInfoLength = 500;
  static const int maxMinutes = 1440; // 24 hours
  
  // Export
  static const String csvHeader = 'Date,Departure,Arrival,Minutes,Info,Created At';
}