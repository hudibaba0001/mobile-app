// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../calendar/sweden_holidays.dart';
import '../models/user_red_day.dart';
import '../models/user_red_day_adapter.dart';
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
      final reasonText =
          personalRedDay!.reason != null ? ' - ${personalRedDay!.reason}' : '';
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

  /// Hive local cache
  Box<UserRedDay>? _hiveBox;

  /// Current user ID (set when authenticated)
  String? _userId;

  /// Whether to auto-mark public holidays as red days
  bool _autoMarkHolidays = true;
  bool get autoMarkHolidays => _autoMarkHolidays;

  /// Current country code for holidays
  final String _countryCode = 'SE';
  String get countryCode => _countryCode;

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    final left = _normalizeDate(a);
    final right = _normalizeDate(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _isSameTimestamp(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toUtc() == b.toUtc();
  }

  bool _isSameRedDayPayload(List<UserRedDay> a, List<UserRedDay> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];

      if (left.id != right.id) return false;
      if (left.userId != right.userId) return false;
      if (!_isSameDate(left.date, right.date)) return false;
      if (left.kind != right.kind) return false;
      if (left.half != right.half) return false;
      if ((left.reason ?? '') != (right.reason ?? '')) return false;
      if (left.source != right.source) return false;
      if (!_isSameTimestamp(left.createdAt, right.createdAt)) return false;
      if (!_isSameTimestamp(left.updatedAt, right.updatedAt)) return false;
    }

    return true;
  }

  List<UserRedDay> _dedupeRedDaysByDate(Iterable<UserRedDay> redDays) {
    final byDate = <String, UserRedDay>{};
    for (final redDay in redDays) {
      if (_userId != null && redDay.userId != _userId) continue;
      final normalizedDate = _normalizeDate(redDay.date);
      byDate[_dateKey(normalizedDate)] = redDay.copyWith(date: normalizedDate);
    }
    final deduped = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return deduped;
  }

  /// Initialize Hive box for local caching
  Future<void> initHive(Box<UserRedDay> box) async {
    _hiveBox = box;
  }

  /// Load cached red days from Hive into memory
  void _loadFromHive() {
    if (_hiveBox == null || _userId == null) return;

    final allUserRedDays = _hiveBox!.values
        .where((redDay) =>
            redDay.userId == _userId &&
            redDay.id != UserRedDayAdapter.corruptedSentinelId)
        .toList();
    final deduped = _dedupeRedDaysByDate(allUserRedDays);
    for (final redDay in deduped) {
      final year = redDay.date.year;
      _personalRedDaysCache.putIfAbsent(year, () => <UserRedDay>[]);
      _personalRedDaysCache[year]!.add(redDay);
    }
  }

  /// Save red days for a year to Hive
  void _saveToHive(int year) {
    if (_hiveBox == null || _userId == null) return;

    try {
      final redDays = _dedupeRedDaysByDate(_personalRedDaysCache[year] ?? []);
      _personalRedDaysCache[year] = redDays;
      // Remove old entries for this year
      final keysToRemove = <dynamic>[];
      for (final key in _hiveBox!.keys) {
        final entry = _hiveBox!.get(key);
        if (entry != null &&
            entry.userId == _userId &&
            entry.date.year == year) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        _hiveBox!.delete(key);
      }
      // Add current entries
      for (final rd in redDays) {
        if (rd.id != null) {
          _hiveBox!.put(rd.id, rd);
        }
      }
    } catch (e) {
      debugPrint('HolidayService: Error saving to Hive: $e');
    }
  }

  /// Initialize with repository and user ID
  void initialize({
    required UserRedDayRepository repository,
    required String? userId,
  }) {
    _repository = repository;
    final didUserChange = _userId != userId;
    _userId = userId;
    if (didUserChange) {
      _personalRedDaysCache.clear();
      _loadFromHive();
    }
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
      final next = _dedupeRedDaysByDate(redDays);
      final current = _personalRedDaysCache[year] ?? const <UserRedDay>[];
      final changed = !_isSameRedDayPayload(current, next);

      _personalRedDaysCache[year] = next;
      _saveToHive(year);
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('HolidayService: Error loading personal red days: $e');
      // Fall back to Hive cache
      if (_personalRedDaysCache.containsKey(year)) {
        debugPrint('HolidayService: Using cached red days for year $year');
      }
    }
  }

  /// Get personal red days for a year (from cache)
  List<UserRedDay> getPersonalRedDays(int year) {
    return _personalRedDaysCache[year] ?? [];
  }

  /// Get personal red day for a specific date
  UserRedDay? getPersonalRedDay(DateTime date) {
    final normalized = _normalizeDate(date);
    final yearDays = _personalRedDaysCache[normalized.year] ?? [];
    return yearDays.cast<UserRedDay?>().firstWhere(
          (rd) => rd != null && _isSameDate(rd.date, normalized),
          orElse: () => null,
        );
  }

  /// Add or update a personal red day
  Future<UserRedDay> upsertPersonalRedDay(UserRedDay redDay) async {
    if (_repository == null) {
      throw Exception('Repository not initialized');
    }
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final saved = await _repository!.upsert(redDay);

    // Update cache
    final normalizedDate = _normalizeDate(saved.date);
    final year = normalizedDate.year;
    final existing = List<UserRedDay>.from(_personalRedDaysCache[year] ?? []);
    existing.removeWhere((rd) => _isSameDate(rd.date, normalizedDate));
    existing.add(saved.copyWith(date: normalizedDate));
    _personalRedDaysCache[year] = _dedupeRedDaysByDate(existing);
    _saveToHive(year);

    notifyListeners();
    return saved;
  }

  /// Delete a personal red day
  Future<void> deletePersonalRedDay(DateTime date) async {
    if (_repository == null) {
      throw Exception('Repository not initialized');
    }
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final normalizedDate = _normalizeDate(date);
    await _repository!.deleteForDate(userId: _userId!, date: normalizedDate);

    // Update cache
    final year = normalizedDate.year;
    final existing = List<UserRedDay>.from(_personalRedDaysCache[year] ?? []);
    existing.removeWhere((rd) => _isSameDate(rd.date, normalizedDate));
    _personalRedDaysCache[year] = _dedupeRedDaysByDate(existing);
    _saveToHive(year);

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

    final isAutoHoliday =
        _autoMarkHolidays && _swedenHolidays.isHoliday(normalized);
    final autoHolidayName =
        isAutoHoliday ? _swedenHolidays.holidayName(normalized) : null;
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
