import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/time_provider.dart';

void main() {
  group('TimeProvider ISO week DST regression', () {
    test('returns stable ISO week numbers around DST boundary dates', () {
      expect(
        TimeProvider.isoWeekNumberForDate(DateTime(2026, 3, 28)),
        13,
      );
      expect(
        TimeProvider.isoWeekNumberForDate(DateTime(2026, 3, 30)),
        14,
      );
      expect(
        TimeProvider.isoWeekNumberForDate(DateTime(2026, 4, 6)),
        15,
      );
    });
  });
}
