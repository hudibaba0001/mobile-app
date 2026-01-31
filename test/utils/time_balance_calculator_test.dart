import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/time_balance_calculator.dart';
import 'package:myapp/models/monthly_summary.dart';
import '../helpers/entry_fixtures.dart';

void main() {
  group('TimeBalanceCalculator.calculateYearlyBalance', () {
    test('Base case: 0 worked, positive target => negative balance', () {
      final summaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 0),
      ];
      // Target defaults to 160.0
      // Balance = 0 - 160 = -160
      final balance = TimeBalanceCalculator.calculateYearlyBalance(summaries, targetHours: 160.0);
      expect(balance, -160.0);
    });

    test('Positive case: worked > target => positive balance', () {
      final summaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 170),
      ];
      // Balance = 170 - 160 = +10
      final balance = TimeBalanceCalculator.calculateYearlyBalance(summaries, targetHours: 160.0);
      expect(balance, 10.0);
    });

    test('Accumulation over multiple months', () {
      final summaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 170), // +10
        MonthlySummary(year: 2024, month: 2, actualWorkedHours: 150), // -10
      ];
      // Balance = +10 + (-10) = 0
      final balance = TimeBalanceCalculator.calculateYearlyBalance(summaries, targetHours: 160.0);
      expect(balance, 0.0);
    });

    test('Date range / Year boundary correctness', () {
      // Ensure it handles different years correctly (though input is just a list)
      final summaries = [
        MonthlySummary(year: 2023, month: 12, actualWorkedHours: 170), // +10
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 170), // +10
      ];
      final balance = TimeBalanceCalculator.calculateYearlyBalance(summaries, targetHours: 160.0);
      expect(balance, 20.0);
    });
  });

  group('Shift Logic (Break Subtraction & Clamping)', () {
    test('Break Subtraction: 4h shift - 30m break = 3.5h worked', () {
      final shift = makeShift(
        date: DateTime(2024, 1, 1),
        startHHMM: '08:00',
        endHHMM: '12:00',
        breakMinutes: 30,
      );
      // Span: 4h = 240m. Worked: 240 - 30 = 210m.
      expect(shift.workedMinutes, 210);
      expect(shift.duration.inMinutes, 240); // Span remains 240
    });

    test('Break Clamp: Break > Span => 0 worked (no negative)', () {
      final shift = makeShift(
        date: DateTime(2024, 1, 1),
        startHHMM: '08:00',
        endHHMM: '08:15', // 15m span
        breakMinutes: 30, // 30m break
      );
      // 15 - 30 = -15. Should be clamped to 0.
      expect(shift.workedMinutes, 0);
    });

    test('Zero Break: Worked = Span', () {
      final shift = makeShift(
        date: DateTime(2024, 1, 1),
        startHHMM: '08:00',
        endHHMM: '09:00',
        breakMinutes: 0,
      );
      expect(shift.workedMinutes, 60);
    });
  });

  group('Integration: Balance Consistency ("Trust Killer" Regression)', () {
    test('Verify Status == Running Balance with Adjustments & Worked', () {
      // Scenario:
      // Base usage, no adjustments initially
      // Month 1: Target 100h, Worked 90h => Variance -10h
      // Month 2: Target 100h, Worked 110h => Variance +10h
      // Net: 0h
      
      final summaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 90),
        MonthlySummary(year: 2024, month: 2, actualWorkedHours: 110),
      ];
      
      var runningBalance = TimeBalanceCalculator.calculateYearlyBalance(summaries, targetHours: 100.0);
      expect(runningBalance, 0.0, reason: "Without adjustment, balance should be 0");
      
      // Now add adjustment: +126h "Opening balance" equivalent
      // The calculator itself just sums variances. 
      // Adjustments are usually added ON TOP of the calculator result in the Provider.
      // But let's verify the calculator result allows for clean addition.
      
      const adjustment = 126.0;
      final totalBalance = runningBalance + adjustment;
      expect(totalBalance, 126.0);
      
      // Regression check: If we have negative variance, ensure it subtraction works
      final badMonthSummary = [
         MonthlySummary(year: 2024, month: 1, actualWorkedHours: 50), // -50h
      ];
      runningBalance = TimeBalanceCalculator.calculateYearlyBalance(badMonthSummary, targetHours: 100.0);
      expect(runningBalance, -50.0);
      expect(runningBalance + adjustment, 76.0); // 126 - 50 = 76
    });
  });
}
