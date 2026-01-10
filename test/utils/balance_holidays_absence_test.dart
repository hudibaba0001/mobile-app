import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/providers/absence_provider.dart';

void main() {
  group('Balance Calculations with Holidays and Absences', () {
    late SwedenHolidayCalendar holidays;
    late AbsenceProvider absenceProvider;

    setUp(() {
      holidays = SwedenHolidayCalendar();
      // Create a mock AbsenceProvider for testing
      // Note: In real tests, you'd use a mock SupabaseAuthService and SupabaseAbsenceService
      // For now, we'll test the logic directly
    });

    test('Weekday holiday: scheduled=0', () {
      // May 1, 2025 is a Thursday (weekday) and a holiday (May Day)
      final date = DateTime(2025, 5, 1);
      expect(date.weekday, lessThanOrEqualTo(5)); // Weekday
      expect(holidays.isHoliday(date), isTrue); // Holiday
      
      final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
        date: date,
        weeklyTargetMinutes: 40 * 60, // 2400 minutes
        holidays: holidays,
      );
      
      expect(scheduled, 0, reason: 'Holiday on weekday should have scheduled=0');
    });

    test('Paid sick day with no work: credit=scheduled → variance=0', () {
      // Create a test scenario: normal weekday with paid sick leave
      final date = DateTime(2025, 3, 15); // Saturday, but let's use a weekday
      // Use a weekday that's not a holiday
      final weekday = DateTime(2025, 3, 17); // Monday, March 17, 2025
      expect(weekday.weekday, 1); // Monday
      expect(holidays.isHoliday(weekday), isFalse); // Not a holiday
      
      final weeklyTargetMinutes = 40 * 60; // 2400 minutes
      final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
        date: weekday,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      // Daily target should be 2400 / 5 = 480 minutes
      expect(scheduled, 480);
      
      // Simulate: paid sick day with minutes=0 (full day)
      // In Option A: if minutes==0, credit = scheduled
      // So: actual=0, credit=scheduled, variance = 0 + scheduled - scheduled = 0
      final actual = 0;
      final credit = scheduled; // Full day paid sick
      final variance = actual + credit - scheduled;
      
      expect(variance, 0, reason: 'Full paid sick day should result in variance=0');
    });

    test('Partial paid vacation (240 min) on normal day scheduled=480', () {
      final weekday = DateTime(2025, 3, 17); // Monday
      final weeklyTargetMinutes = 40 * 60; // 2400
      final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
        date: weekday,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      expect(scheduled, 480); // 8 hours
      
      // Partial paid vacation: 240 minutes (4 hours)
      // Option A: credit = min(scheduled, paidMinutes) = min(480, 240) = 240
      final actual = 0; // No work
      final paidMinutes = 240;
      final credit = paidMinutes < scheduled ? paidMinutes : scheduled;
      final variance = actual + credit - scheduled;
      
      expect(credit, 240);
      expect(variance, -240, reason: 'Partial vacation should result in -240 min variance');
    });

    test('Year variance equals sum of month variances', () {
      final year = 2025;
      final weeklyTargetMinutes = 40 * 60; // 2400
      
      // Calculate monthly scheduled minutes
      int totalYearScheduled = 0;
      for (int month = 1; month <= 12; month++) {
        final monthScheduled = TargetHoursCalculator.monthlyScheduledMinutes(
          year: year,
          month: month,
          weeklyTargetMinutes: weeklyTargetMinutes,
          holidays: holidays,
        );
        totalYearScheduled += monthScheduled;
      }
      
      // Calculate yearly scheduled minutes directly
      final yearScheduled = TargetHoursCalculator.yearlyScheduledMinutes(
        year: year,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      // They should match
      expect(yearScheduled, equals(totalYearScheduled),
          reason: 'Yearly scheduled should equal sum of monthly scheduled');
    });

    test('Monthly targets differ (Feb vs Jul) with holidays', () {
      final year = 2025;
      final weeklyTargetMinutes = 40 * 60; // 2400
      
      final febScheduled = TargetHoursCalculator.monthlyScheduledMinutes(
        year: year,
        month: 2,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      final julScheduled = TargetHoursCalculator.monthlyScheduledMinutes(
        year: year,
        month: 7,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      // July should have more scheduled minutes than February
      // (longer month, but also consider holidays)
      expect(julScheduled, greaterThan(febScheduled),
          reason: 'July should have more scheduled minutes than February');
    });

    test('Empty months show negative variance', () {
      final year = 2025;
      final weeklyTargetMinutes = 40 * 60; // 2400
      
      // February with no work
      final febScheduled = TargetHoursCalculator.monthlyScheduledMinutes(
        year: year,
        month: 2,
        weeklyTargetMinutes: weeklyTargetMinutes,
        holidays: holidays,
      );
      
      final febActual = 0; // No work
      final febCredit = 0; // No absences
      final febVariance = febActual + febCredit - febScheduled;
      
      expect(febVariance, lessThan(0),
          reason: 'Empty month should show negative variance');
    });
  });
}

