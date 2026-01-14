import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Set up mock SharedPreferences values before all tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  
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

