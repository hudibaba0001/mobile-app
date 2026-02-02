import '../calendar/sweden_holidays.dart';

/// Utility for calculating calendar-based target hours in minutes
///
/// Calculates monthly and yearly targets based on actual weekdays (Mon-Fri)
/// in each month, ensuring accuracy without approximation drift.
///
/// Also supports holiday-aware scheduling (Sweden red days).
class TargetHoursCalculator {
  /// Normalize date to year/month/day only (no time component)
  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  /// Calculate the number of weekdays (Monday-Friday) in a given month
  ///
  /// [year] The year (e.g., 2025)
  /// [month] The month (1-12, where 1 = January)
  ///
  /// Returns the count of weekdays (Mon-Fri) in the month
  static int countWeekdaysInMonth(int year, int month) {
    // Get last day of the month
    final lastDay = DateTime(year, month + 1, 0); // Last day of month

    int weekdayCount = 0;

    // Iterate through each day of the month
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      final weekday = date.weekday; // 1 = Monday, 7 = Sunday

      // Count only weekdays (Monday = 1, Friday = 5)
      if (weekday >= 1 && weekday <= 5) {
        weekdayCount++;
      }
    }

    return weekdayCount;
  }

  /// Calculate monthly target minutes based on weekdays in the month
  ///
  /// [year] The year (e.g., 2025)
  /// [month] The month (1-12, where 1 = January)
  /// [weeklyTargetMinutes] Target minutes per week (e.g., 2400 for 40 hours/week)
  ///
  /// Formula: (weeklyTargetMinutes * weekdayCount / 5).round()
  /// This prevents "lost minutes" drift from floor division.
  ///
  /// Returns the target minutes for the month
  static int monthlyTargetMinutes(
    int year,
    int month,
    int weeklyTargetMinutes,
  ) {
    // Count weekdays in the month
    final weekdayCount = countWeekdaysInMonth(year, month);

    // Monthly target = (weeklyTargetMinutes * weekdayCount / 5).round()
    // This prevents drift from floor division
    return ((weeklyTargetMinutes * weekdayCount) / 5.0).round();
  }

  /// Calculate yearly target minutes as sum of all monthly targets
  ///
  /// [year] The year (e.g., 2025)
  /// [weeklyTargetMinutes] Target minutes per week (e.g., 2400 for 40 hours/week)
  ///
  /// Returns the sum of monthly targets for all 12 months
  static int yearlyTargetMinutes(int year, int weeklyTargetMinutes) {
    int totalMinutes = 0;

    // Sum targets for all 12 months
    for (int month = 1; month <= 12; month++) {
      totalMinutes += monthlyTargetMinutes(year, month, weeklyTargetMinutes);
    }

    return totalMinutes;
  }

  /// Get monthly target as hours (for display/backward compatibility)
  ///
  /// [year] The year
  /// [month] The month (1-12)
  /// [weeklyTargetMinutes] Target minutes per week
  ///
  /// Returns the target hours for the month
  static double monthlyTargetHours(
    int year,
    int month,
    int weeklyTargetMinutes,
  ) {
    return monthlyTargetMinutes(year, month, weeklyTargetMinutes) / 60.0;
  }

  /// Get yearly target as hours (for display/backward compatibility)
  ///
  /// [year] The year
  /// [weeklyTargetMinutes] Target minutes per week
  ///
  /// Returns the target hours for the year
  static double yearlyTargetHours(int year, int weeklyTargetMinutes) {
    return yearlyTargetMinutes(year, weeklyTargetMinutes) / 60.0;
  }

  /// Calculate variance in minutes
  ///
  /// [actualMinutes] Actual minutes worked
  /// [targetMinutes] Target minutes
  ///
  /// Returns variance (positive = over target, negative = under target)
  static int varianceMinutes(int actualMinutes, int targetMinutes) {
    return actualMinutes - targetMinutes;
  }

  /// Calculate variance in hours (for display/backward compatibility)
  ///
  /// [actualMinutes] Actual minutes
  /// [targetMinutes] Target minutes
  ///
  /// Returns variance in hours
  static double varianceHours(int actualMinutes, int targetMinutes) {
    return varianceMinutes(actualMinutes, targetMinutes) / 60.0;
  }

  /// Calculate scheduled minutes for a specific date
  ///
  /// Takes into account:
  /// - Work weekdays (default: Mon-Fri = 1-5)
  /// - Holidays (red days) → scheduled = 0
  ///
  /// [date] The date to check
  /// [weeklyTargetMinutes] Target minutes per week
  /// [holidays] Holiday calendar (SwedenHolidayCalendar)
  /// [workWeekdays] Ordered list of weekday numbers (1=Mon, 7=Sun). Default: [1,2,3,4,5]
  /// [redDayFactor] Optional: fraction of scheduled to use (0.0 = full day off, 0.5 = half day, null = check holidays)
  ///
  /// Returns scheduled minutes for that day (0 if weekend or holiday)
  static int scheduledMinutesForDate({
    required DateTime date,
    required int weeklyTargetMinutes,
    required SwedenHolidayCalendar holidays,
    List<int> workWeekdays = const [1, 2, 3, 4, 5],
    double? redDayFactor,
  }) {
    final normalized = _d(date);

    // Check if weekday is in work weekdays first
    final idx = workWeekdays.indexOf(normalized.weekday);
    if (idx < 0) {
      return 0; // Weekend or non-work day
    }

    // Deterministic distribution: base + remainder distribution
    // This ensures weekly minutes sum exactly to weeklyTargetMinutes (no drift)
    final days = workWeekdays.length;
    final base = weeklyTargetMinutes ~/ days;
    final rem = weeklyTargetMinutes % days;

    // Base scheduled minutes for this weekday
    final baseScheduled = base + ((idx >= 0 && idx < rem) ? 1 : 0);
    
    // If a specific red day factor is provided, use it
    if (redDayFactor != null) {
      // Factor: 0.0 = full day off, 0.5 = half day, 1.0 = normal day
      return (baseScheduled * redDayFactor).round();
    }

    // Check if holiday (red day) → scheduled = 0
    if (holidays.isHoliday(normalized)) {
      return 0;
    }

    return baseScheduled;
  }
  
  /// Calculate scheduled minutes for a date with red day info
  ///
  /// V1 Rule:
  /// - Full red day → scheduled = 0
  /// - Half red day → scheduled = 50% of normal
  /// - Normal day → full scheduled
  ///
  /// [date] The date
  /// [weeklyTargetMinutes] Target minutes per week
  /// [isFullRedDay] Whether it's a full red day
  /// [isHalfRedDay] Whether it's a half red day
  /// [workWeekdays] Work weekdays
  ///
  /// Returns scheduled minutes
  static int scheduledMinutesWithRedDayInfo({
    required DateTime date,
    required int weeklyTargetMinutes,
    required bool isFullRedDay,
    required bool isHalfRedDay,
    List<int> workWeekdays = const [1, 2, 3, 4, 5],
  }) {
    final normalized = _d(date);

    // Check if weekday is in work weekdays first
    final idx = workWeekdays.indexOf(normalized.weekday);
    if (idx < 0) {
      return 0; // Weekend or non-work day
    }

    // Deterministic distribution: base + remainder distribution
    final days = workWeekdays.length;
    final base = weeklyTargetMinutes ~/ days;
    final rem = weeklyTargetMinutes % days;
    final baseScheduled = base + ((idx >= 0 && idx < rem) ? 1 : 0);
    
    // Apply red day rules
    if (isFullRedDay) {
      return 0; // Full day off
    }
    if (isHalfRedDay) {
      return (baseScheduled * 0.5).round(); // Half day
    }

    return baseScheduled;
  }

  /// Calculate monthly scheduled minutes (holiday-aware)
  ///
  /// Loops through all days in the month and sums scheduledMinutesForDate
  ///
  /// [year] The year
  /// [month] The month (1-12)
  /// [weeklyTargetMinutes] Target minutes per week
  /// [holidays] Holiday calendar
  /// [workWeekdays] Set of weekday numbers. Default: {1,2,3,4,5}
  ///
  /// Returns total scheduled minutes for the month
  static int monthlyScheduledMinutes({
    required int year,
    required int month,
    required int weeklyTargetMinutes,
    required SwedenHolidayCalendar holidays,
    List<int> workWeekdays = const [1, 2, 3, 4, 5],
  }) {
    final lastDay = DateTime(year, month + 1, 0);
    int totalMinutes = 0;

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      totalMinutes += scheduledMinutesForDate(
        date: date,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
        workWeekdays: workWeekdays,
      );
    }

    return totalMinutes;
  }

  /// Calculate yearly scheduled minutes (holiday-aware)
  ///
  /// Sums monthlyScheduledMinutes for all 12 months
  ///
  /// [year] The year
  /// [weeklyTargetMinutes] Target minutes per week
  /// [holidays] Holiday calendar
  /// [workWeekdays] Set of weekday numbers. Default: {1,2,3,4,5}
  ///
  /// Returns total scheduled minutes for the year
  static int yearlyScheduledMinutes({
    required int year,
    required int weeklyTargetMinutes,
    required SwedenHolidayCalendar holidays,
    List<int> workWeekdays = const [1, 2, 3, 4, 5],
  }) {
    int totalMinutes = 0;

    for (int month = 1; month <= 12; month++) {
      totalMinutes += monthlyScheduledMinutes(
        year: year,
        month: month,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
        workWeekdays: workWeekdays,
      );
    }

    return totalMinutes;
  }

  /// Calculate scheduled minutes for a date range (inclusive)
  ///
  /// Loops through each day from start to endInclusive and sums scheduled minutes
  ///
  /// [start] Start date (inclusive)
  /// [endInclusive] End date (inclusive)
  /// [weeklyTargetMinutes] Target minutes per week
  /// [holidays] Holiday calendar
  /// [workWeekdays] Set of weekday numbers. Default: {1,2,3,4,5}
  ///
  /// Returns total scheduled minutes for the date range
  static int scheduledMinutesInRange({
    required DateTime start,
    required DateTime endInclusive,
    required int weeklyTargetMinutes,
    required SwedenHolidayCalendar holidays,
    List<int> workWeekdays = const [1, 2, 3, 4, 5],
  }) {
    final startNormalized = _d(start);
    final endNormalized = _d(endInclusive);

    if (endNormalized.isBefore(startNormalized)) {
      return 0;
    }

    int totalMinutes = 0;
    DateTime current = startNormalized;

    while (!current.isAfter(endNormalized)) {
      totalMinutes += scheduledMinutesForDate(
        date: current,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
        workWeekdays: workWeekdays,
      );
      current = current.add(const Duration(days: 1));
    }

    return totalMinutes;
  }
}
