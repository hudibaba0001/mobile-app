import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:myapp/utils/time_balance_calculator.dart';
import 'package:myapp/calendar/sweden_holidays.dart';

// Copy of minimal RedDayInfo structure for testing
class MockRedDayInfo {
  final bool isRedDay;
  final bool isFullRedDay;
  final bool isHalfRedDay;
  MockRedDayInfo(
      {this.isRedDay = false,
      this.isFullRedDay = false,
      this.isHalfRedDay = false});
}

void main() {
  final holidays = SwedenHolidayCalendar();
  const weeklyTarget40h = 2400; // 40 hours * 60 minutes

  group('TargetHoursCalculator Tests', () {
    test('Standard month (Jan 2025) - No holidays, just weekdays', () {
      // Jan 2025:
      // 1-3 (Wed-Fri) = 3
      // 6-10 (Mon-Fri) = 5
      // 13-17 (Mon-Fri) = 5
      // 20-24 (Mon-Fri) = 5
      // 27-31 (Mon-Fri) = 5
      // Total weekdays = 23.
      // BUT Jan 1 (Wed) is a holiday. Jan 6 (Mon) is a holiday.
      // So real working days = 21.

      // Let's test countWeekdaysInMonth (pure weekdays, ignoring holidays) first
      expect(TargetHoursCalculator.countWeekdaysInMonth(2025, 1), 23);

      // Monthly target calculation (pure math, ignores holidays)
      // (2400 * 23 / 5).round() = 480 * 23 = 11040 minutes
      expect(
          TargetHoursCalculator.monthlyTargetMinutes(2025, 1, weeklyTarget40h),
          11040);
    });

    test('Leap year (Feb 2024)', () {
      // Feb 2024 has 29 days. Starts Thursday.
      // 1-2 (Thu-Fri) = 2
      // 5-9 = 5
      // 12-16 = 5
      // 19-23 = 5
      // 26-29 (Mon-Thu) = 4
      // Total = 21 weekdays.
      expect(TargetHoursCalculator.countWeekdaysInMonth(2024, 2), 21);

      // Target: (2400 * 21 / 5).round() = 480 * 21 = 10080
      expect(
          TargetHoursCalculator.monthlyTargetMinutes(2024, 2, weeklyTarget40h),
          10080);
    });

    test('scheduledMinutesForDate - Normal Weekday', () {
      final monday = DateTime(2025, 2, 3); // Feb 3 2025 is Monday
      // 2400 / 5 = 480
      expect(
          TargetHoursCalculator.scheduledMinutesForDate(
              date: monday,
              weeklyTargetMinutes: weeklyTarget40h,
              holidays: holidays),
          480);
    });

    test('scheduledMinutesForDate - Holiday (Jan 1 2025)', () {
      final jan1 = DateTime(2025, 1, 1); // Wed
      expect(
          TargetHoursCalculator.scheduledMinutesForDate(
              date: jan1,
              weeklyTargetMinutes: weeklyTarget40h,
              holidays: holidays),
          0);
    });

    test(
        'scheduledMinutesForDate - Midsummer Eve (Not a red day but often half day)',
        () {
      // NOTE: standard calculator only checks isHoliday. Midsummer eve is NOT a public holiday in SwedenHolidayCalendar
      // It is usually handled by HolidayService as a "de facto" holiday or half day.
      // Let's check a known red day: Midsummer Day (Saturday).
      // Saturday is already 0.
      // Let's check June 6 (National Day) - fixed date.
      final june6 = DateTime(2025, 6, 6); // Fri
      expect(
          TargetHoursCalculator.scheduledMinutesForDate(
              date: june6,
              weeklyTargetMinutes: weeklyTarget40h,
              holidays: holidays),
          0);
    });

    test('scheduledMinutesWithRedDayInfo - Half Day', () {
      final date =
          DateTime(2025, 4, 30); // Valborg? Just a random date for test
      expect(
          TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
              date: date,
              weeklyTargetMinutes: weeklyTarget40h,
              isFullRedDay: false,
              isHalfRedDay: true),
          240); // 480 * 0.5
    });

    test('Irregular weekly target (37.5 hours)', () {
      const target = 2250; // 37.5 * 60
      // Daily base: 2250 / 5 = 450 (7.5h)
      final monday = DateTime(2025, 2, 3);
      expect(
          TargetHoursCalculator.scheduledMinutesForDate(
              date: monday, weeklyTargetMinutes: target, holidays: holidays),
          450);
    });

    test('Non-integer daily split (38 hours)', () {
      const target = 2280; // 38 * 60
      // 2280 / 5 = 456
      final monday = DateTime(2025, 2, 3);
      expect(
          TargetHoursCalculator.scheduledMinutesForDate(
              date: monday, weeklyTargetMinutes: target, holidays: holidays),
          456);
    });
  });

  group('TimeBalanceCalculator Tests', () {
    test('calculateMonthlyVariance', () {
      // worked 160h, target 160h -> 0
      expect(
          TimeBalanceCalculator.calculateMonthlyVariance(160, targetHours: 160),
          0.0);
      // worked 170h, target 160h -> +10
      expect(
          TimeBalanceCalculator.calculateMonthlyVariance(170, targetHours: 160),
          10.0);
      // worked 150h, target 160h -> -10
      expect(
          TimeBalanceCalculator.calculateMonthlyVariance(150, targetHours: 160),
          -10.0);
    });
  });
}
