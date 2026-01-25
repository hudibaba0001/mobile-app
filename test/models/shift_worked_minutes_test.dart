import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('Shift workedMinutes calculation', () {
    test('span 480, break 30 => worked 450', () {
      final start = DateTime(2025, 1, 15, 9, 0);
      final end = DateTime(2025, 1, 15, 17, 0); // 8 hours = 480 minutes
      
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 30,
      );
      
      expect(shift.duration.inMinutes, 480);
      expect(shift.workedMinutes, 450); // 480 - 30
    });

    test('break > span => worked 0', () {
      final start = DateTime(2025, 1, 15, 9, 0);
      final end = DateTime(2025, 1, 15, 9, 30); // 30 minutes span
      
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 60, // Break exceeds span
      );
      
      expect(shift.workedMinutes, 0); // Never negative
      expect(shift.workedMinutes, greaterThanOrEqualTo(0));
    });

    test('zero break => worked equals span', () {
      final start = DateTime(2025, 1, 15, 8, 0);
      final end = DateTime(2025, 1, 15, 16, 0); // 8 hours = 480 minutes
      
      final shift = Shift(
        start: start,
        end: end,
        unpaidBreakMinutes: 0,
      );
      
      expect(shift.workedMinutes, 480);
      expect(shift.workedMinutes, shift.duration.inMinutes);
    });
  });
}
