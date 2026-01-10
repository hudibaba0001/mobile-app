import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/utils/target_hours_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TimeProvider Balance Calculations', () {
    late ContractProvider contractProvider;

    setUp(() async {
      contractProvider = ContractProvider();
      await contractProvider.init();
    });

    test('Empty months show negative variance (target exists)', () {
      // Set contract to 40h/week
      contractProvider.setFullTimeHours(40);
      contractProvider.setContractPercent(100);
      
      final weeklyTargetMinutes = contractProvider.weeklyTargetMinutes;
      
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

    test('Yearly variance equals sum of monthly variances (theoretical)', () async {
      await contractProvider.setFullTimeHours(40);
      await contractProvider.setContractPercent(100);
      
      final weeklyTargetMinutes = contractProvider.weeklyTargetMinutes;
      
      // Simulate: all months have 0 actual hours
      int sumOfMonthlyVariancesMinutes = 0;
      
      for (int month = 1; month <= 12; month++) {
        final actualMinutes = 0;
        final targetMinutes = TargetHoursCalculator.monthlyTargetMinutes(
          2025,
          month,
          weeklyTargetMinutes,
        );
        sumOfMonthlyVariancesMinutes += (actualMinutes - targetMinutes);
      }
      
      // Yearly variance should equal sum
      final yearActualMinutes = 0;
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
      
      // Assertion: yearlyVarianceMinutes == sum(monthlyVarianceMinutes) always
      expect(
        yearVarianceMinutes,
        equals(sumOfMonthlyVariancesMinutes),
        reason: 'CRITICAL: yearlyVarianceMinutes must always equal sum of monthlyVarianceMinutes',
      );
    });

    test('75% contract yields correct targets', () async {
      // Set contract to 75% of 40h = 30h/week
      await contractProvider.setFullTimeHours(40);
      await contractProvider.setContractPercent(75);
      
      final weeklyTargetMinutes = contractProvider.weeklyTargetMinutes;
      expect(weeklyTargetMinutes, 30 * 60); // 1800 minutes
      
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

    test('Monthly targets differ for short vs long months', () async {
      await contractProvider.setFullTimeHours(40);
      await contractProvider.setContractPercent(100);
      
      final weeklyTargetMinutes = contractProvider.weeklyTargetMinutes;
      
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
}

