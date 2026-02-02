import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('Shift workedMinutes calculation', () {
    test('workedMinutes = span - unpaidBreakMinutes', () {
      final start = DateTime(2025, 1, 15, 9, 0);
      final end = DateTime(2025, 1, 15, 17, 0);
      
      // 8 hours = 480 minutes span
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 30,
      );
      
      // 480 - 30 = 450 worked minutes
      expect(shift.workedMinutes, 450);
      expect(shift.duration.inMinutes, 480);
    });

    test('workedMinutes never negative when break exceeds span', () {
      final start = DateTime(2025, 1, 15, 9, 0);
      final end = DateTime(2025, 1, 15, 9, 30); // 30 minutes span
      
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 60, // Break exceeds span
      );
      
      // Should return 0, not negative
      expect(shift.workedMinutes, 0);
      expect(shift.workedMinutes, greaterThanOrEqualTo(0));
    });

    test('workedMinutes with zero break equals span', () {
      final start = DateTime(2025, 1, 15, 8, 0);
      final end = DateTime(2025, 1, 15, 16, 0); // 8 hours = 480 minutes
      
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 0,
      );
      
      expect(shift.workedMinutes, 480);
      expect(shift.duration.inMinutes, 480);
    });

    test('workedMinutes with multiple shifts in same entry', () {
      final shift1 = Shift(
        start: DateTime(2025, 1, 15, 8, 0),
        end: DateTime(2025, 1, 15, 12, 0), // 4 hours = 240 minutes
        unpaidBreakMinutes: 15,
      );
      
      final shift2 = Shift(
        start: DateTime(2025, 1, 15, 13, 0),
        end: DateTime(2025, 1, 15, 17, 0), // 4 hours = 240 minutes
        unpaidBreakMinutes: 30,
      );
      
      expect(shift1.workedMinutes, 225); // 240 - 15
      expect(shift2.workedMinutes, 210); // 240 - 30
    });

    test('workedDuration returns correct Duration', () {
      final shift = Shift(
        start: DateTime(2025, 1, 15, 9, 0),
        end: DateTime(2025, 1, 15, 17, 30), // 8.5 hours = 510 minutes
        unpaidBreakMinutes: 30,
      );
      
      expect(shift.workedDuration.inMinutes, 480);
      expect(shift.workedDuration.inHours, 8);
    });
  });
}
