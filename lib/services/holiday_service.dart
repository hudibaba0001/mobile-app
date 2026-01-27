// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../calendar/sweden_holidays.dart';
import '../models/user_red_day.dart';
import '../repositories/user_red_day_repository.dart';

/// Combined red day info (auto holiday + personal)
class RedDayInfo {
  final DateTime date;
  final bool isAutoHoliday;
  final String? autoHolidayName;
  final UserRedDay? personalRedDay;
  
  const RedDayInfo({
    required this.date,
    this.isAutoHoliday = false,
    this.autoHolidayName,
    this.personalRedDay,
  });
  
  /// Whether this date is a red day (any source)
  bool get isRedDay => isAutoHoliday || personalRedDay != null;
  
  /// Whether this is a full red day
  bool get isFullDay {
    // Auto holiday is always full day
    if (isAutoHoliday) return true;
    // Personal red day can be full or half
    if (personalRedDay != null) {
      return personalRedDay!.kind == RedDayKind.full;
    }
    return false;
  }
  
  /// Get the half (AM/PM) if this is a half day
  HalfDay? get halfDay {
    if (personalRedDay != null && personalRedDay!.kind == RedDayKind.half) {
      return personalRedDay!.half;
    }
    return null;
  }
  
  /// Get display badges for this day
  List<String> get badges {
    final result = <String>[];
    if (isAutoHoliday) {
      result.add('Auto');
    }
    if (personalRedDay != null) {
      result.add('Personal');
    }
    return result;
  }
  
  /// Get tooltip text
  String get tooltip {
    final parts = <String>[];
    if (isAutoHoliday && autoHolidayName != null) {
      parts.add('Public holiday: $autoHolidayName');
    }
    if (personalRedDay != null) {
      final kindText = personalRedDay!.kindDisplayText;
      final reasonText = personalRedDay!.reason != null 
          ? ' - ${personalRedDay!.reason}' 
          : '';
      parts.add('Personal: $kindText$reasonText');
    }
    return parts.join('\n');
  }
}

/// Service to manage red days (auto holidays + personal)
/// 
/// Provides:
/// - Auto holiday lookup (Swedish public holidays)
/// - Personal red day management
/// - Merged view for precedence logic
class HolidayService extends ChangeNotifier {
  final SwedenHolidayCalendar _swedenHolidays = SwedenHolidayCalendar();
  UserRedDayRepository? _repository;
  
  /// Cache of personal red days by year
  final Map<int, List<UserRedDay>> _personalRedDaysCache = {};
  
  /// Current user ID (set when authenticated)
  String? _userId;
  
  /// Whether to auto-mark public holidays as red days
  bool _autoMarkHolidays = true;
  bool get autoMarkHolidays => _autoMarkHolidays;
  
  /// Current country code for holidays
  final String _countryCode = 'SE';
  String get countryCode => _countryCode;
  
  /// Initialize with repository and user ID
  void initialize({
    required UserRedDayRepository repository,
    required String? userId,
  }) {
    _repository = repository;
    _userId = userId;
    _personalRedDaysCache.clear();
  }
  
  /// Set auto-mark holidays preference
  void setAutoMarkHolidays(bool value) {
    if (_autoMarkHolidays != value) {
      _autoMarkHolidays = value;
      notifyListeners();
    }
  }
  
  /// Load personal red days for a year
  Future<void> loadPersonalRedDays(int year) async {
    if (_repository == null || _userId == null) return;
    
    try {
      final redDays = await _repository!.getForYear(
        userId: _userId!,
        year: year,
      );
      _personalRedDaysCache[year] = redDays;
      notifyListeners();
    } catch (e) {
      debugPrint('HolidayService: Error loading personal red days: $e');
    }
  }
  
  /// Get personal red days for a year (from cache)
  List<UserRedDay> getPersonalRedDays(int year) {
    return _personalRedDaysCache[year] ?? [];
  }
  
  /// Get personal red day for a specific date
  UserRedDay? getPersonalRedDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yearDays = _personalRedDaysCache[normalized.year] ?? [];
    return yearDays.cast<UserRedDay?>().firstWhere(
      (rd) => rd != null && 
          rd.date.year == normalized.year &&
          rd.date.month == normalized.month &&
          rd.date.day == normalized.day,
      orElse: () => null,
    );
  }
  
  /// Add or update a personal red day
  Future<UserRedDay> upsertPersonalRedDay(UserRedDay redDay) async {
    if (_repository == null) {
      throw Exception('Repository not initialized');
    }
    
    final saved = await _repository!.upsert(redDay);
    
    // Update cache
    final year = saved.date.year;
    final existing = _personalRedDaysCache[year] ?? [];
    final index = existing.indexWhere((rd) => 
      rd.date.year == saved.date.year &&
      rd.date.month == saved.date.month &&
      rd.date.day == saved.date.day
    );
    
    if (index >= 0) {
      existing[index] = saved;
    } else {
      existing.add(saved);
    }
    _personalRedDaysCache[year] = existing;
    
    notifyListeners();
    return saved;
  }
  
  /// Delete a personal red day
  Future<void> deletePersonalRedDay(DateTime date) async {
    if (_repository == null || _userId == null) return;
    
    await _repository!.deleteForDate(userId: _userId!, date: date);
    
    // Update cache
    final year = date.year;
    final existing = _personalRedDaysCache[year] ?? [];
    existing.removeWhere((rd) => 
      rd.date.year == date.year &&
      rd.date.month == date.month &&
      rd.date.day == date.day
    );
    _personalRedDaysCache[year] = existing;
    
    notifyListeners();
  }
  
  // ============ Auto Holiday Methods (unchanged) ============
  
  /// Check if a date is a public holiday
  bool isHoliday(DateTime date) {
    if (!_autoMarkHolidays) return false;
    return _swedenHolidays.isHoliday(date);
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
  
  // ============ Combined Methods ============
  
  /// Get combined red day info for a date
  RedDayInfo getRedDayInfo(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    
    final isAutoHoliday = _autoMarkHolidays && _swedenHolidays.isHoliday(normalized);
    final autoHolidayName = isAutoHoliday ? _swedenHolidays.holidayName(normalized) : null;
    final personalRedDay = getPersonalRedDay(normalized);
    
    return RedDayInfo(
      date: normalized,
      isAutoHoliday: isAutoHoliday,
      autoHolidayName: autoHolidayName,
      personalRedDay: personalRedDay,
    );
  }
  
  /// Check if a date is any kind of red day
  bool isRedDay(DateTime date) {
    return getRedDayInfo(date).isRedDay;
  }
  
  /// Get legacy HolidayInfo for backwards compatibility
  /// Returns info for auto holiday only (not personal)
  HolidayInfo? getHolidayInfo(DateTime date) {
    if (!_autoMarkHolidays) return null;
    
    final name = _swedenHolidays.holidayName(date);
    if (name == null) return null;
    
    return HolidayInfo(
      date: date,
      name: name,
      countryCode: _countryCode,
    );
  }
  
  /// Get all holidays with names for a year (for settings dialog)
  List<HolidayInfo> getHolidaysWithNamesForYear(int year) {
    if (!_autoMarkHolidays) return [];
    
    final holidays = _swedenHolidays.holidaysForYear(year);
    return holidays.map((date) {
      final name = _swedenHolidays.holidayName(date) ?? 'Holiday';
      return HolidayInfo(
        date: date,
        name: name,
        countryCode: _countryCode,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  /// Get tooltip text for a holiday (legacy)
  String getHolidayTooltip(DateTime date) {
    final info = getHolidayInfo(date);
    if (info == null) return '';
    return 'This day is marked red automatically because it\'s a public holiday in Sweden.';
  }
  
  /// Available country options (for future expansion)
  static const List<Map<String, String>> availableCountries = [
    {'code': 'SE', 'name': 'Sweden'},
  ];
}

/// Legacy HolidayInfo for backwards compatibility
class HolidayInfo {
  final DateTime date;
  final String name;
  final String countryCode;

  const HolidayInfo({
    required this.date,
    required this.name,
    required this.countryCode,
  });

  @override
  String toString() => 'HolidayInfo($name on $date)';
}
