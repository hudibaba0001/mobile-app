/// Holiday calendar for Sweden
/// 
/// Provides fixed-date holidays, Easter-based movable holidays,
/// and special Saturday holidays (Midsummer, All Saints' Day)
class SwedenHolidayCalendar {
  /// Cache for holidays per year (performance optimization)
  final Map<int, Set<DateTime>> _holidayCache = {};
  
  /// Cache for holiday names per year (performance optimization)
  final Map<int, Map<DateTime, String>> _nameCache = {};

  /// Normalize date to year/month/day only (no time component)
  static DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);

  /// Calculate Easter Sunday for a given year using Gregorian computus
  /// 
  /// Algorithm: Anonymous Gregorian algorithm
  /// Returns Easter Sunday as a DateTime
  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Get all holidays for a given year (cached for performance)
  /// 
  /// Returns a set of normalized dates (year/month/day only)
  Set<DateTime> holidaysForYear(int year) {
    return _holidayCache.putIfAbsent(year, () {
      final holidays = <DateTime>{};

    // Fixed-date holidays
    holidays.add(d(DateTime(year, 1, 1))); // New Year's Day
    holidays.add(d(DateTime(year, 1, 6))); // Epiphany
    holidays.add(d(DateTime(year, 5, 1))); // May Day
    holidays.add(d(DateTime(year, 6, 6))); // National Day
    holidays.add(d(DateTime(year, 12, 25))); // Christmas Day
    holidays.add(d(DateTime(year, 12, 26))); // Boxing Day

    // Easter-based movable holidays
    final easterSunday = _easterSunday(year);
    holidays.add(d(easterSunday.subtract(const Duration(days: 2)))); // Good Friday
    holidays.add(d(easterSunday)); // Easter Sunday
    holidays.add(d(easterSunday.add(const Duration(days: 1)))); // Easter Monday
    holidays.add(d(easterSunday.add(const Duration(days: 39)))); // Ascension Day (39 days after Easter)
    
    // Pentecost Sunday (50 days after Easter)
    holidays.add(d(easterSunday.add(const Duration(days: 49)))); // Pentecost Sunday

    // Midsummer Day: Saturday between Jun 20-26
    final midsummer = _midsummerDay(year);
    if (midsummer != null) {
      holidays.add(d(midsummer));
    }

    // All Saints' Day: Saturday between Oct 31-Nov 6
    final allSaints = _allSaintsDay(year);
    if (allSaints != null) {
      holidays.add(d(allSaints));
    }

    return holidays;
    });
  }

  /// Check if a date is a holiday
  bool isHoliday(DateTime date) {
    final normalized = d(date);
    final yearHolidays = holidaysForYear(normalized.year);
    return yearHolidays.contains(normalized);
  }

  /// Get the name of a holiday for a given date (cached for performance)
  /// 
  /// Returns null if the date is not a holiday
  String? holidayName(DateTime date) {
    final normalized = d(date);
    if (!isHoliday(normalized)) return null;

    final year = normalized.year;
    
    // Check cache first
    final yearCache = _nameCache.putIfAbsent(year, () => <DateTime, String>{});
    if (yearCache.containsKey(normalized)) {
      return yearCache[normalized];
    }

    final month = normalized.month;
    final day = normalized.day;
    String? name;

    // Fixed-date holidays
    if (month == 1 && day == 1) return 'New Year\'s Day';
    if (month == 1 && day == 6) return 'Epiphany';
    if (month == 5 && day == 1) return 'May Day';
    if (month == 6 && day == 6) return 'National Day';
    if (month == 12 && day == 25) return 'Christmas Day';
    if (month == 12 && day == 26) return 'Boxing Day';

    // Easter-based holidays
    final easterSunday = _easterSunday(year);
    final goodFriday = d(easterSunday.subtract(const Duration(days: 2)));
    final easterMonday = d(easterSunday.add(const Duration(days: 1)));
    final ascension = d(easterSunday.add(const Duration(days: 39)));
    final pentecost = d(easterSunday.add(const Duration(days: 49)));

    if (normalized == goodFriday) return 'Good Friday';
    if (normalized == d(easterSunday)) return 'Easter Sunday';
    if (normalized == easterMonday) return 'Easter Monday';
    if (normalized == ascension) return 'Ascension Day';
    if (normalized == pentecost) return 'Pentecost Sunday';

    // Special Saturdays
    final midsummer = _midsummerDay(year);
    if (midsummer != null && normalized == d(midsummer)) {
      return 'Midsummer Day';
    }

    final allSaints = _allSaintsDay(year);
    if (allSaints != null && normalized == d(allSaints)) {
      name = 'All Saints\' Day';
    } else {
      name = 'Holiday';
    }

    // Cache the result
    yearCache[normalized] = name;
    return name;
  }

  /// Calculate Midsummer Day: Saturday between Jun 20-26
  static DateTime? _midsummerDay(int year) {
    for (int day = 20; day <= 26; day++) {
      final date = DateTime(year, 6, day);
      if (date.weekday == 6) { // Saturday
        return date;
      }
    }
    return null; // Should never happen, but handle edge case
  }

  /// Calculate All Saints' Day: Saturday between Oct 31-Nov 6
  static DateTime? _allSaintsDay(int year) {
    // Check Oct 31
    final oct31 = DateTime(year, 10, 31);
    if (oct31.weekday == 6) {
      return oct31;
    }
    
    // Check Nov 1-6
    for (int day = 1; day <= 6; day++) {
      final date = DateTime(year, 11, day);
      if (date.weekday == 6) { // Saturday
        return date;
      }
    }
    return null; // Should never happen, but handle edge case
  }
}

