import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/monthly_summary.dart';
import 'package:myapp/utils/time_balance_calculator.dart';

void main() {
  group('TimeBalanceCalculator', () {
    test('calculateYearlyBalance - exact test case from requirements', () {
      // Test Case from requirements:
      // Jan: Worked 190. Target 160. Variance: +30. Year Balance: +30.
      // Feb: Worked 190. Target 160. Variance: +30. Year Balance: +60.
      // Mar: Worked 130. Target 160. Variance: -30. Year Balance: +30.

      final monthlySummaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 190.0), // January
        MonthlySummary(year: 2024, month: 2, actualWorkedHours: 190.0), // February
        MonthlySummary(year: 2024, month: 3, actualWorkedHours: 130.0), // March
      ];

      final result = TimeBalanceCalculator.calculateYearlyBalance(
        monthlySummaries,
        targetHours: 160.0,
      );

      // Expected: +30 (Jan: +30, Feb: +60, Mar: +30)
      expect(result, equals(30.0));
    });

    test('calculateYearlyBalance - verifies monthly variances', () {
      final monthlySummaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 190.0),
        MonthlySummary(year: 2024, month: 2, actualWorkedHours: 190.0),
        MonthlySummary(year: 2024, month: 3, actualWorkedHours: 130.0),
      ];

      final detailed = TimeBalanceCalculator.calculateDetailedBalance(
        monthlySummaries,
        targetHours: 160.0,
      );

      final monthlyVariances = detailed['monthlyVariances'] as List;
      final cumulativeBalances = detailed['cumulativeBalances'] as List<double>;

      // January: 190 - 160 = +30
      expect(monthlyVariances[0]['variance'], equals(30.0));
      expect(cumulativeBalances[0], equals(30.0));

      // February: 190 - 160 = +30, cumulative: +30 + 30 = +60
      expect(monthlyVariances[1]['variance'], equals(30.0));
      expect(cumulativeBalances[1], equals(60.0));

      // March: 130 - 160 = -30, cumulative: +60 - 30 = +30
      expect(monthlyVariances[2]['variance'], equals(-30.0));
      expect(cumulativeBalances[2], equals(30.0));
    });

    test('calculateYearlyBalance - handles unsorted months', () {
      // Test that months are sorted chronologically
      final monthlySummaries = [
        MonthlySummary(year: 2024, month: 3, actualWorkedHours: 130.0), // March first
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 190.0), // January second
        MonthlySummary(year: 2024, month: 2, actualWorkedHours: 190.0), // February third
      ];

      final result = TimeBalanceCalculator.calculateYearlyBalance(
        monthlySummaries,
        targetHours: 160.0,
      );

      // Should still calculate correctly: Jan +30, Feb +60, Mar +30
      expect(result, equals(30.0));
    });

    test('calculateYearlyBalance - empty list returns zero', () {
      final result = TimeBalanceCalculator.calculateYearlyBalance([]);
      expect(result, equals(0.0));
    });

    test('calculateYearlyBalance - custom target hours', () {
      final monthlySummaries = [
        MonthlySummary(year: 2024, month: 1, actualWorkedHours: 180.0),
      ];

      final result = TimeBalanceCalculator.calculateYearlyBalance(
        monthlySummaries,
        targetHours: 200.0, // Custom target
      );

      // 180 - 200 = -20
      expect(result, equals(-20.0));
    });

    test('calculateMonthlyVariance - calculates correctly', () {
      expect(
        TimeBalanceCalculator.calculateMonthlyVariance(190.0, targetHours: 160.0),
        equals(30.0),
      );
      expect(
        TimeBalanceCalculator.calculateMonthlyVariance(130.0, targetHours: 160.0),
        equals(-30.0),
      );
      expect(
        TimeBalanceCalculator.calculateMonthlyVariance(160.0, targetHours: 160.0),
        equals(0.0),
      );
    });
  });
}

