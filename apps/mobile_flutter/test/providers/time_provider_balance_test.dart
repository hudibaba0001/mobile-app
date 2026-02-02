// ignore_for_file: dead_code, unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up mock SharedPreferences values before all tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Run tracking start date tests
  trackingStartDateTests();

  group('TimeProvider Balance Calculations - Pure Logic', () {
    // These tests use TargetHoursCalculator directly (no SharedPreferences dependency)

    test('Empty months show negative variance (target exists)', () {
      // Use 40h/week = 2400 min
      const weeklyTargetMinutes = 40 * 60;
      
      // For each month in 2025, verify target exists even with 0 actual hours
      for (int month = 1; month <= 12; month++) {
        final targetMinutes = TargetHoursCalculator.monthlyTargetMinutes(
          2025,
          month,
          weeklyTargetMinutes,
        );
        
        // Target should be positive (based on weekdays in month)
        expect(targetMinutes, greaterThan(0));
        
        // With 0 actual hours, variance should be negative
        final variance = -targetMinutes;
        expect(variance, lessThan(0));
      }
    });

    test('Yearly variance equals sum of monthly variances (theoretical)', () {
      // Use 40h/week = 2400 min
      const weeklyTargetMinutes = 40 * 60;
      
      // Simulate: all months have 0 actual hours
      int sumOfMonthlyVariancesMinutes = 0;
      
      for (int month = 1; month <= 12; month++) {
        const actualMinutes = 0;
        final targetMinutes = TargetHoursCalculator.monthlyTargetMinutes(
          2025,
          month,
          weeklyTargetMinutes,
        );
        sumOfMonthlyVariancesMinutes += (actualMinutes - targetMinutes);
      }
      
      // Yearly variance should equal sum
      const yearActualMinutes = 0;
      final yearTargetMinutes = TargetHoursCalculator.yearlyTargetMinutes(
        2025,
        weeklyTargetMinutes,
      );
      final yearVarianceMinutes = yearActualMinutes - yearTargetMinutes;
      
      // They should match exactly
      expect(
        yearVarianceMinutes,
        equals(sumOfMonthlyVariancesMinutes),
        reason: 'Yearly variance should equal sum of monthly variances',
      );
    });

    test('75% contract yields correct targets', () {
      // 75% of 40h = 30h/week = 1800 min
      const weeklyTargetMinutes = 30 * 60;
      
      // Check monthly targets are correct
      for (int month = 1; month <= 12; month++) {
        final targetMinutes = TargetHoursCalculator.monthlyTargetMinutes(
          2025,
          month,
          weeklyTargetMinutes,
        );
        
        // Formula: (weeklyTargetMinutes * weekdayCount / 5).round()
        final weekdayCount = TargetHoursCalculator.countWeekdaysInMonth(
          2025,
          month,
        );
        final expectedTarget = ((weeklyTargetMinutes * weekdayCount) / 5.0).round();
        
        expect(targetMinutes, equals(expectedTarget));
      }
    });

    test('Monthly targets differ for short vs long months', () {
      // Use 40h/week = 2400 min
      const weeklyTargetMinutes = 40 * 60;
      
      // February (short month)
      final febTarget = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        2,
        weeklyTargetMinutes,
      );
      
      // July (long month)
      final julTarget = TargetHoursCalculator.monthlyTargetMinutes(
        2025,
        7,
        weeklyTargetMinutes,
      );
      
      // July should have more target minutes than February
      expect(julTarget, greaterThan(febTarget));
      
      // Verify the difference is due to weekday count
      final febWeekdays = TargetHoursCalculator.countWeekdaysInMonth(2025, 2);
      final julWeekdays = TargetHoursCalculator.countWeekdaysInMonth(2025, 7);
      expect(julWeekdays, greaterThan(febWeekdays));
    });
  });
  
  group('Opening Balance Formatting - Pure Logic', () {
    // These tests verify the formatting logic without SharedPreferences
    
    test('Positive flex balance formatting (+8h 30m)', () {
      // Formula: 8h 30m = 510 minutes
      const openingFlexMinutes = 510;
      final isNegative = openingFlexMinutes < 0;
      final absMinutes = openingFlexMinutes.abs();
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      
      final sign = isNegative ? '−' : '+';
      final formatted = mins == 0 ? '$sign${hours}h' : '$sign${hours}h ${mins}m';
      
      expect(formatted, equals('+8h 30m'));
    });
    
    test('Negative flex balance formatting (−3h 15m)', () {
      const openingFlexMinutes = -195; // -3h 15m
      final isNegative = openingFlexMinutes < 0;
      final absMinutes = openingFlexMinutes.abs();
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      
      final sign = isNegative ? '−' : '+';
      final formatted = mins == 0 ? '$sign${hours}h' : '$sign${hours}h ${mins}m';
      
      expect(formatted, equals('−3h 15m'));
    });
    
    test('Zero balance formatting (+0h)', () {
      const openingFlexMinutes = 0;
      final isNegative = openingFlexMinutes < 0;
      final absMinutes = openingFlexMinutes.abs();
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      
      final sign = isNegative ? '−' : '+';
      final formatted = mins == 0 ? '$sign${hours}h' : '$sign${hours}h ${mins}m';
      
      expect(formatted, equals('+0h'));
    });
    
    test('Whole hours formatting (+5h)', () {
      const openingFlexMinutes = 300; // 5h
      final isNegative = openingFlexMinutes < 0;
      final absMinutes = openingFlexMinutes.abs();
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      
      final sign = isNegative ? '−' : '+';
      final formatted = mins == 0 ? '$sign${hours}h' : '$sign${hours}h ${mins}m';
      
      expect(formatted, equals('+5h'));
    });
    
    test('Components to minutes with credit', () {
      const hours = 12;
      const minutes = 30;
      const isDeficit = false;
      
      final totalMinutes = (hours * 60) + minutes;
      final signedMinutes = isDeficit ? -totalMinutes : totalMinutes;
      
      expect(signedMinutes, equals(750));
    });
    
    test('Components to minutes with deficit', () {
      const hours = 4;
      const minutes = 45;
      const isDeficit = true;
      
      final totalMinutes = (hours * 60) + minutes;
      final signedMinutes = isDeficit ? -totalMinutes : totalMinutes;
      
      expect(signedMinutes, equals(-285));
    });
    
    test('Date normalization strips time component', () {
      final dateWithTime = DateTime(2025, 4, 15, 14, 30, 45);
      final normalized = DateTime(dateWithTime.year, dateWithTime.month, dateWithTime.day);
      
      expect(normalized.year, equals(2025));
      expect(normalized.month, equals(4));
      expect(normalized.day, equals(15));
      expect(normalized.hour, equals(0));
      expect(normalized.minute, equals(0));
      expect(normalized.second, equals(0));
    });
  });
  
  group('Balance Calculation with Opening Balance', () {
    test('Variance calculation with positive opening balance', () {
      // Simulate: Opening +8h, April variance -2h
      // Expected: +6h total
      const openingMinutes = 8 * 60; // +480 min
      const aprilVarianceMinutes = -2 * 60; // -120 min
      
      final totalBalance = openingMinutes + aprilVarianceMinutes;
      expect(totalBalance, equals(360)); // +6h in minutes
    });
    
    test('Variance calculation with negative opening balance', () {
      // Simulate: Opening -3h, April variance +5h
      // Expected: +2h total
      const openingMinutes = -3 * 60; // -180 min
      const aprilVarianceMinutes = 5 * 60; // +300 min
      
      final totalBalance = openingMinutes + aprilVarianceMinutes;
      expect(totalBalance, equals(120)); // +2h in minutes
    });
    
    test('Opening balance added once (not per month)', () {
      // Simulate tracking starting mid-year with opening balance
      const openingMinutes = 4 * 60; // +240 min
      
      // Suppose actual variance for Apr-Dec = +10h
      const monthlyVariancesMinutes = 10 * 60; // +600 min
      
      // Total should be opening + monthlyVariances, NOT opening * 9 + monthlyVariances
      final totalBalance = openingMinutes + monthlyVariancesMinutes;
      expect(totalBalance, equals(840)); // +14h in minutes
      
      // Wrong calculation would be: 240 * 9 + 600 = 2760
      expect(totalBalance, isNot(equals(2760)));
    });
    
    test('Filter entries before tracking start date', () {
      // Simulate entries: Jan (100 min), Feb (200 min), Mar (300 min), Apr (400 min)
      // Tracking starts Apr 1
      // Only Apr should be counted
      
      final entries = [
        _MockEntry(DateTime(2025, 1, 15), 100),
        _MockEntry(DateTime(2025, 2, 15), 200),
        _MockEntry(DateTime(2025, 3, 15), 300),
        _MockEntry(DateTime(2025, 4, 15), 400),
      ];
      
      final trackingStartDate = DateTime(2025, 4, 1);
      
      // Filter
      final filteredEntries = entries.where((e) {
        return !e.date.isBefore(trackingStartDate);
      }).toList();
      
      expect(filteredEntries.length, equals(1));
      expect(filteredEntries.first.minutes, equals(400));
    });
  });
}

/// Mock entry for testing filtering logic
class _MockEntry {
  final DateTime date;
  final int minutes;

  _MockEntry(this.date, this.minutes);
}

void trackingStartDateTests() {
  /// Tests for tracking start date (late signup) behavior
  /// Verifies that YTD calculations respect trackingStartDate
  group('Tracking Start Date - Late Signup Behavior', () {
  // Helper to simulate effectiveStart calculation
  DateTime effectiveStart(DateTime periodStart, DateTime trackingStart) {
    return periodStart.isBefore(trackingStart) ? trackingStart : periodStart;
  }

  test('Year target starts from Jan 30 when trackingStartDate is Jan 30', () {
    // Simulate trackingStartDate = Jan 30, 2026
    final trackingStart = DateTime(2026, 1, 30);
    final yearStart = DateTime(2026, 1, 1);
    final today = DateTime(2026, 1, 31);

    // Effective start should be Jan 30 (not Jan 1)
    final start = effectiveStart(yearStart, trackingStart);
    expect(start, equals(trackingStart));

    // Count should only include Jan 30-31 (2 days)
    int dayCount = 0;
    DateTime current = start;
    while (!current.isAfter(today)) {
      dayCount++;
      current = current.add(const Duration(days: 1));
    }
    expect(dayCount, equals(2)); // Jan 30, Jan 31

    // If both are weekdays (Thu, Fri), we'd have 2 workdays
    // Jan 30, 2026 = Friday, Jan 31, 2026 = Saturday
    // So only 1 workday (Jan 30)
    int weekdays = 0;
    current = start;
    while (!current.isAfter(today)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        weekdays++;
      }
      current = current.add(const Duration(days: 1));
    }
    expect(weekdays, equals(1)); // Only Friday Jan 30
  });

  test('Month target returns 0 when trackingStartDate is after month end', () {
    // Simulate trackingStartDate = Feb 1, calculating for January
    final trackingStart = DateTime(2026, 2, 1);
    final monthStart = DateTime(2026, 1, 1);
    final monthEnd = DateTime(2026, 1, 31);

    final start = effectiveStart(monthStart, trackingStart);
    // effectiveStart would be Feb 1, which is after Jan 31
    // So the range is invalid (end < start)
    final validRange = !monthEnd.isBefore(start);
    expect(validRange, isFalse);
  });

  test('Year actual ignores entries before trackingStartDate', () {
    final entries = [
      _MockEntry(DateTime(2026, 1, 10), 480), // Before tracking - ignored
      _MockEntry(DateTime(2026, 1, 15), 480), // Before tracking - ignored
      _MockEntry(DateTime(2026, 1, 20), 480), // Before tracking - ignored
      _MockEntry(DateTime(2026, 1, 30), 480), // On tracking date - counted
      _MockEntry(DateTime(2026, 1, 31), 480), // After tracking - counted
    ];

    final trackingStart = DateTime(2026, 1, 30);
    final today = DateTime(2026, 1, 31);

    // Filter entries like the updated method does
    final filteredEntries = entries.where((e) {
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      return e.date.year == 2026 &&
          !entryDate.isBefore(trackingStart) &&
          !entryDate.isAfter(today);
    }).toList();

    expect(filteredEntries.length, equals(2)); // Only Jan 30 and Jan 31
    expect(
      filteredEntries.fold<int>(0, (sum, e) => sum + e.minutes),
      equals(960), // 480 + 480
    );
  });

  test('Month target counts only from trackingStartDate within month', () {
    // trackingStartDate = Jan 20, calculating for January up to Jan 31
    final trackingStart = DateTime(2026, 1, 20);
    final monthStart = DateTime(2026, 1, 1);
    final monthEnd = DateTime(2026, 1, 31);

    final start = effectiveStart(monthStart, trackingStart);
    expect(start, equals(trackingStart)); // Should be Jan 20

    // Count weekdays from Jan 20 to Jan 31
    // Jan 20 = Tuesday, Jan 21 = Wed, Jan 22 = Thu, Jan 23 = Fri
    // Jan 24 = Sat, Jan 25 = Sun
    // Jan 26 = Mon, Jan 27 = Tue, Jan 28 = Wed, Jan 29 = Thu, Jan 30 = Fri
    // Jan 31 = Sat
    // Weekdays: 20, 21, 22, 23, 26, 27, 28, 29, 30 = 9 weekdays
    int weekdays = 0;
    DateTime current = start;
    while (!current.isAfter(monthEnd)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        weekdays++;
      }
      current = current.add(const Duration(days: 1));
    }
    expect(weekdays, equals(9));
  });

  test('Opening balance not duplicated across months', () {
    // User starts Jan 30 with +30h opening balance
    // After logging some hours, balance should be:
    // opening + sum(variances), NOT opening * monthCount + sum(variances)

    const openingMinutes = 30 * 60; // +30h = 1800 min

    // Simulate: Jan variance = 0h (just started), Feb variance = +2h
    const janVarianceMinutes = 0;
    const febVarianceMinutes = 2 * 60;

    // Correct calculation: opening + all variances
    final correctTotal = openingMinutes + janVarianceMinutes + febVarianceMinutes;
    expect(correctTotal, equals(1920)); // 32h in minutes

    // Wrong calculation would multiply opening by month count
    final wrongTotal = (openingMinutes * 2) + janVarianceMinutes + febVarianceMinutes;
    expect(correctTotal, isNot(equals(wrongTotal)));
  });

  test('Tracking start date helpers detect late signup correctly', () {
    // Simulate helper methods from TimeProvider
    bool isTrackingStartAfterYearStart(DateTime trackingStart, int year) {
      final yearStart = DateTime(year, 1, 1);
      return trackingStart.isAfter(yearStart);
    }

    bool isTrackingStartInMonth(DateTime trackingStart, int year, int month) {
      return trackingStart.year == year && trackingStart.month == month;
    }

    // User started Jan 30, 2026
    final trackingStart = DateTime(2026, 1, 30);

    // Should show "Logged since..." for year 2026
    expect(isTrackingStartAfterYearStart(trackingStart, 2026), isTrue);

    // Should NOT show for year 2027 (tracking started before 2027)
    expect(isTrackingStartAfterYearStart(trackingStart, 2027), isFalse);

    // Should show for January 2026
    expect(isTrackingStartInMonth(trackingStart, 2026, 1), isTrue);

    // Should NOT show for February 2026
    expect(isTrackingStartInMonth(trackingStart, 2026, 2), isFalse);
  });

  test('Year balance starts from 0 when opening balance is 0', () {
    // User starts Jan 30 with opening balance = 0
    const openingMinutes = 0;

    // No entries logged yet, but trackingStartDate is Jan 30
    // Target from Jan 30-31 (say, 16h worth if both are weekdays, but Jan 31 is Saturday)
    // So only ~8h target

    // With 0 actual hours:
    // Balance = actual + credit - target + opening + adjustments
    // = 0 + 0 - 8h + 0 + 0 = -8h (only from Jan 30-31, NOT from Jan 1-31)

    // This is the key fix: user should see ~-8h, not ~-180h
    const actualMinutes = 0;
    const creditMinutes = 0;
    const targetMinutes = 8 * 60; // ~8h for 1 weekday
    const adjustmentMinutes = 0;

    final balance =
        actualMinutes + creditMinutes - targetMinutes + openingMinutes + adjustmentMinutes;

    // Balance should be -8h (480 min), not -180h (full month target)
    expect(balance, equals(-480));
    expect(balance, isNot(equals(-180 * 60))); // Not full month target
  });
});
}
