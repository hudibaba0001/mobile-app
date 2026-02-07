import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:myapp/calendar/sweden_holidays.dart';

void main() {
  group('To-Date Target Calculations', () {
    late SwedenHolidayCalendar holidays;

    setUp(() {
      holidays = SwedenHolidayCalendar();
    });

    test('scheduledMinutesInRange - calculates correctly for date range', () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      // Jan 1-3, 2025
      // Jan 1 = Wednesday (holiday - New Year's Day) → 0
      // Jan 2 = Thursday (weekday) → 480
      // Jan 3 = Friday (weekday) → 480
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 3);

      final scheduled = TargetHoursCalculator.scheduledMinutesInRange(
        start: start,
        endInclusive: end,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Should be 0 (Jan 1 holiday) + 480 (Jan 2) + 480 (Jan 3) = 960
      expect(scheduled, 960);
    });

    test(
        'On Jan 2, January target-to-date should be 8h (Jan 1 is holiday, Jan 2 is workday)',
        () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      // Simulate: today is Jan 2, 2025
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 2); // Jan 2

      final scheduled = TargetHoursCalculator.scheduledMinutesInRange(
        start: start,
        endInclusive: end,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Jan 1 = holiday (0), Jan 2 = weekday (480 min = 8h)
      expect(scheduled, 480); // 8 hours
      expect(scheduled / 60.0, 8.0);
    });

    test(
        'Year target-to-date equals month target-to-date on Jan 2 (early year)',
        () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      // Simulate: today is Jan 2, 2025
      final endDate = DateTime(2025, 1, 2);

      // Month target-to-date (Jan 1-2)
      final monthTarget = TargetHoursCalculator.scheduledMinutesInRange(
        start: DateTime(2025, 1, 1),
        endInclusive: endDate,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Year target-to-date (Jan 1-2)
      final yearTarget = TargetHoursCalculator.scheduledMinutesInRange(
        start: DateTime(2025, 1, 1),
        endInclusive: endDate,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Should be equal
      expect(yearTarget, equals(monthTarget),
          reason:
              'Year target-to-date should equal month target-to-date on Jan 2');
    });

    test('Variance uses to-date target, not full period', () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      // Simulate: today is Jan 2, 2025, user worked 4 hours (240 min)
      final endDate = DateTime(2025, 1, 2);
      final actualMinutes = 240; // 4 hours worked

      // To-date target (Jan 1-2)
      final targetToDate = TargetHoursCalculator.scheduledMinutesInRange(
        start: DateTime(2025, 1, 1),
        endInclusive: endDate,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Variance = actual - target-to-date
      final variance = actualMinutes - targetToDate;

      // Jan 1 = holiday (0), Jan 2 = 480 min target
      // Actual = 240, Target = 480
      // Variance = 240 - 480 = -240 (4 hours under)
      expect(targetToDate, 480);
      expect(variance, -240);
      expect(variance / 60.0, -4.0);
    });

    test('scheduledMinutesInRange handles end date before start', () {
      final weeklyTargetMinutes = 40 * 60;

      final start = DateTime(2025, 1, 5);
      final end = DateTime(2025, 1, 3); // Before start

      final scheduled = TargetHoursCalculator.scheduledMinutesInRange(
        start: start,
        endInclusive: end,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      expect(scheduled, 0);
    });

    test('scheduledMinutesInRange handles single day', () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      // Jan 2, 2025 (Thursday, weekday, not holiday)
      final date = DateTime(2025, 1, 2);

      final scheduled = TargetHoursCalculator.scheduledMinutesInRange(
        start: date,
        endInclusive: date,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );

      // Should be 480 minutes (8 hours)
      expect(scheduled, 480);
    });
  });
}
