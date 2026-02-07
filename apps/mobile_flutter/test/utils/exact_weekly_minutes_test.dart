import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:myapp/calendar/sweden_holidays.dart';

void main() {
  group('Exact Weekly Minutes Distribution', () {
    late SwedenHolidayCalendar holidays;

    setUp(() {
      holidays = SwedenHolidayCalendar();
    });

    test('Weekly minutes sum exactly to weeklyTargetMinutes (no drift)', () {
      // Test with 2400 minutes/week (40 hours)
      final weeklyTargetMinutes = 2400;

      // A week with no holidays (e.g., Jan 13-17, 2025 = Mon-Fri)
      final weekStart = DateTime(2025, 1, 13); // Monday
      int totalMinutes = 0;

      for (int day = 0; day < 5; day++) {
        final date = weekStart.add(Duration(days: day));
        final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          holidays: holidays,
        );
        totalMinutes += scheduled;
      }

      // Should sum exactly to 2400 (no rounding drift)
      expect(totalMinutes, equals(weeklyTargetMinutes),
          reason: 'Weekly minutes should sum exactly to weeklyTargetMinutes');
    });

    test('Weekly minutes with remainder distributed correctly', () {
      // Test with 2401 minutes/week (not divisible by 5)
      final weeklyTargetMinutes = 2401;

      // A week with no holidays
      final weekStart = DateTime(2025, 1, 13); // Monday
      final scheduledMinutes = <int>[];

      for (int day = 0; day < 5; day++) {
        final date = weekStart.add(Duration(days: day));
        final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          holidays: holidays,
        );
        scheduledMinutes.add(scheduled);
      }

      // Base = 2401 ~/ 5 = 480
      // Remainder = 2401 % 5 = 1
      // First day (Monday, index 0) should get base + 1 = 481
      // Other days should get base = 480
      expect(scheduledMinutes[0], 481); // Monday gets remainder
      expect(scheduledMinutes[1], 480); // Tuesday
      expect(scheduledMinutes[2], 480); // Wednesday
      expect(scheduledMinutes[3], 480); // Thursday
      expect(scheduledMinutes[4], 480); // Friday

      final total = scheduledMinutes.fold(0, (sum, val) => sum + val);
      expect(total, equals(weeklyTargetMinutes),
          reason: 'Should sum exactly to weeklyTargetMinutes');
    });

    test('Weekly minutes with larger remainder distributed correctly', () {
      // Test with 2403 minutes/week (remainder = 3)
      final weeklyTargetMinutes = 2403;

      // A week with no holidays
      final weekStart = DateTime(2025, 1, 13); // Monday
      final scheduledMinutes = <int>[];

      for (int day = 0; day < 5; day++) {
        final date = weekStart.add(Duration(days: day));
        final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          holidays: holidays,
        );
        scheduledMinutes.add(scheduled);
      }

      // Base = 2403 ~/ 5 = 480
      // Remainder = 2403 % 5 = 3
      // First 3 days should get base + 1 = 481
      // Last 2 days should get base = 480
      expect(scheduledMinutes[0], 481); // Monday
      expect(scheduledMinutes[1], 481); // Tuesday
      expect(scheduledMinutes[2], 481); // Wednesday
      expect(scheduledMinutes[3], 480); // Thursday
      expect(scheduledMinutes[4], 480); // Friday

      final total = scheduledMinutes.fold(0, (sum, val) => sum + val);
      expect(total, equals(weeklyTargetMinutes),
          reason: 'Should sum exactly to weeklyTargetMinutes');
    });
  });
}
