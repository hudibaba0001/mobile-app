import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';

void main() {
  group('TargetHoursCalculator', () {
    test('countWeekdaysInMonth - February 2025 (28 days, 20 weekdays)', () {
      // February 2025: 28 days, starts on Saturday
      // Weekdays: 3 (Mon-Wed) + 5*4 (full weeks) + 2 (Thu-Fri) = 20
      final count = TargetHoursCalculator.countWeekdaysInMonth(2025, 2);
      expect(count, 20);
    });

    test('countWeekdaysInMonth - July 2025 (31 days, 23 weekdays)', () {
      // July 2025: 31 days, starts on Tuesday
      // Should have 23 weekdays
      final count = TargetHoursCalculator.countWeekdaysInMonth(2025, 7);
      expect(count, 23);
    });

    test('countWeekdaysInMonth - different months have different counts', () {
      final feb = TargetHoursCalculator.countWeekdaysInMonth(2025, 2);
      final jul = TargetHoursCalculator.countWeekdaysInMonth(2025, 7);

      // July should have more weekdays than February (longer month)
      expect(jul, greaterThan(feb));
    });

    test('monthlyTargetMinutes - 40h/week contract (2400 min/week)', () {
      // 40 hours/week = 2400 minutes/week
      // Formula: (weeklyTargetMinutes * weekdayCount / 5).round()
      final weeklyTargetMinutes = 40 * 60; // 2400

      // February 2025 has 20 weekdays
      // (2400 * 20 / 5).round() = 9600 minutes = 160 hours
      final febTarget = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        2,
        weeklyTargetMinutes,
      );
      expect(febTarget, 9600);

      // July 2025 has 23 weekdays
      // (2400 * 23 / 5).round() = 11040 minutes = 184 hours
      final julTarget = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        7,
        weeklyTargetMinutes,
      );
      expect(julTarget, 11040);
    });

    test('monthlyTargetMinutes - 75% contract (30h/week = 1800 min/week)', () {
      // 75% of 40h = 30h/week = 1800 minutes/week
      // Formula: (weeklyTargetMinutes * weekdayCount / 5).round()
      final weeklyTargetMinutes = 30 * 60; // 1800

      // February 2025 has 20 weekdays
      // (1800 * 20 / 5).round() = 7200 minutes = 120 hours
      final febTarget = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        2,
        weeklyTargetMinutes,
      );
      expect(febTarget, 7200);
    });

    test('yearlyTargetMinutes - sum equals sum of monthly targets', () {
      final weeklyTargetMinutes = 40 * 60; // 2400
      final yearTarget = TargetHoursCalculator.yearlyTargetMinutes(
        2025,
        weeklyTargetMinutes,
      );

      // Sum all monthly targets
      int sumOfMonths = 0;
      for (int month = 1; month <= 12; month++) {
        sumOfMonths += TargetHoursCalculator.monthlyTargetMinutes(
          2025,
          month,
          weeklyTargetMinutes,
        );
      }

      expect(yearTarget, equals(sumOfMonths));
    });

    test('monthlyTargetHours - converts minutes to hours correctly', () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      final febMinutes = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        2,
        weeklyTargetMinutes,
      );
      final febHours = TargetHoursCalculator.monthlyTargetHours(
        2025,
        2,
        weeklyTargetMinutes,
      );

      expect(febHours, closeTo(febMinutes / 60.0, 0.01));
    });

    test('yearlyTargetHours - converts minutes to hours correctly', () {
      final weeklyTargetMinutes = 40 * 60; // 2400

      final yearMinutes = TargetHoursCalculator.yearlyTargetMinutes(
        2025,
        weeklyTargetMinutes,
      );
      final yearHours = TargetHoursCalculator.yearlyTargetHours(
        2025,
        weeklyTargetMinutes,
      );

      expect(yearHours, closeTo(yearMinutes / 60.0, 0.01));
    });

    test('varianceMinutes - calculates correctly', () {
      final actualMinutes = 2500;
      final targetMinutes = 2400;

      final variance = TargetHoursCalculator.varianceMinutes(
        actualMinutes,
        targetMinutes,
      );

      expect(variance, 100); // 100 minutes over target
    });

    test('varianceHours - converts minutes to hours correctly', () {
      final actualMinutes = 150; // 2.5 hours
      final targetMinutes = 120; // 2.0 hours

      final variance = TargetHoursCalculator.varianceHours(
        actualMinutes,
        targetMinutes,
      );

      expect(variance, closeTo(0.5, 0.01)); // 0.5 hours over
    });
  });
}
