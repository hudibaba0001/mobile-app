import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/target_hours_calculator.dart';

void main() {
  group('TargetHoursCalculator.countWeekdaysInMonth', () {
    test('Standard Month: Feb 2026 (28 days, starts Sunday)', () {
      final count = TargetHoursCalculator.countWeekdaysInMonth(2026, 2);
      expect(count, 20);
    });

    test('Leap Year: Feb 2024 (29 days, starts Thursday)', () {
      final count = TargetHoursCalculator.countWeekdaysInMonth(2024, 2);
      expect(count, 21);
    });

    test('Month starting and ending on Sunday: Feb 2004 (Leap)', () {
      final count = TargetHoursCalculator.countWeekdaysInMonth(2004, 2);
      expect(count, 20);
    });

    test('Long month starting Monday: Oct 2023 (31 days)', () {
      final count = TargetHoursCalculator.countWeekdaysInMonth(2023, 5); // May
      expect(count, 23);
    });
  });

  group('TargetHoursCalculator.scheduledMinutesWithRedDayInfo', () {
    test('Full red day returns 0', () {
      final val = TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
        date: DateTime(2024, 1, 1), // Monday
        weeklyTargetMinutes: 2400, // 40h -> 8h/day (480m)
        isFullRedDay: true,
        isHalfRedDay: false,
      );
      expect(val, 0);
    });

    test('Half red day returns 50%', () {
      final val = TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
        date: DateTime(2024, 1, 1), // Monday
        weeklyTargetMinutes: 2400, // 480m base
        isFullRedDay: false,
        isHalfRedDay: true,
      );
      // 480 * 0.5 = 240
      expect(val, 240);
    });

    test('Normal day returns base', () {
      final val = TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
        date: DateTime(2024, 1, 1), // Monday
        weeklyTargetMinutes: 2400, // 480m base
        isFullRedDay: false,
        isHalfRedDay: false,
      );
      expect(val, 480);
    });
    
    test('Non-work day (Sunday) returns 0 even if normal', () {
      final val = TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
        date: DateTime(2024, 1, 7), // Sunday
        weeklyTargetMinutes: 2400, 
        isFullRedDay: false,
        isHalfRedDay: false,
      );
      expect(val, 0);
    });
  });
}
