import 'package:flutter/foundation.dart';
import '../calendar/sweden_holidays.dart';

/// Source of red day marking
enum RedDaySource {
  autoHoliday, // Auto-detected public holiday
  manual,      // Manually marked by user
  imported,    // Imported from external source
}

/// Holiday info for a specific date
class HolidayInfo {
  final DateTime date;
  final String name;
  final String countryCode;
  final RedDaySource source;

  const HolidayInfo({
    required this.date,
    required this.name,
    required this.countryCode,
    required this.source,
  });

  @override
  String toString() => 'HolidayInfo($name on $date)';
}

/// Service to manage holiday/red day information
/// 
/// Provides:
/// - Holiday lookup for any date
/// - Settings for auto-marking holidays
/// - Support for Swedish public holidays
class HolidayService extends ChangeNotifier {
  final SwedenHolidayCalendar _swedenHolidays = SwedenHolidayCalendar();
  
  /// Whether to auto-mark public holidays as red days
  bool _autoMarkHolidays = true;
  bool get autoMarkHolidays => _autoMarkHolidays;
  
  /// Current country code for holidays
  String _countryCode = 'SE';
  String get countryCode => _countryCode;
  
  /// Set auto-mark holidays preference
  void setAutoMarkHolidays(bool value) {
    if (_autoMarkHolidays != value) {
      _autoMarkHolidays = value;
      notifyListeners();
    }
  }
  
  /// Check if a date is a public holiday
  bool isHoliday(DateTime date) {
    if (!_autoMarkHolidays) return false;
    return _swedenHolidays.isHoliday(date);
  }
  
  /// Get holiday info for a date (returns null if not a holiday)
  HolidayInfo? getHolidayInfo(DateTime date) {
    if (!_autoMarkHolidays) return null;
    
    final name = _swedenHolidays.holidayName(date);
    if (name == null) return null;
    
    return HolidayInfo(
      date: date,
      name: name,
      countryCode: _countryCode,
      source: RedDaySource.autoHoliday,
    );
  }
  
  /// Get holiday name for a date (returns null if not a holiday)
  String? getHolidayName(DateTime date) {
    if (!_autoMarkHolidays) return null;
    return _swedenHolidays.holidayName(date);
  }
  
  /// Get all holidays for a year
  Set<DateTime> holidaysForYear(int year) {
    if (!_autoMarkHolidays) return {};
    return _swedenHolidays.holidaysForYear(year);
  }
  
  /// Get all holidays with names for a year
  List<HolidayInfo> getHolidaysWithNamesForYear(int year) {
    if (!_autoMarkHolidays) return [];
    
    final holidays = _swedenHolidays.holidaysForYear(year);
    return holidays.map((date) {
      final name = _swedenHolidays.holidayName(date) ?? 'Holiday';
      return HolidayInfo(
        date: date,
        name: name,
        countryCode: _countryCode,
        source: RedDaySource.autoHoliday,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  /// Get display text for a holiday
  String getHolidayDisplayText(DateTime date) {
    final name = getHolidayName(date);
    if (name == null) return '';
    return 'Auto-marked: $name';
  }
  
  /// Get tooltip text for a holiday
  String getHolidayTooltip(DateTime date) {
    final info = getHolidayInfo(date);
    if (info == null) return '';
    return 'This day is marked red automatically because it\'s a public holiday in Sweden.';
  }
  
  /// Available country options (for future expansion)
  static const List<Map<String, String>> availableCountries = [
    {'code': 'SE', 'name': 'Sweden'},
    // Future: Add more countries
  ];
}
