import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/reporting/time_format.dart';

void main() {
  group('time_format', () {
    test('formatSignedMinutes formats positive minutes with plus sign', () {
      expect(formatSignedMinutes(315), '+5h 15m');
    });

    test('formatMinutes formats total minutes as Hh Mm', () {
      expect(formatMinutes(7035), '117h 15m');
    });

    test('formatSignedMinutes formats negative values and pads minutes', () {
      expect(formatSignedMinutes(-120), '-2h 00m');
    });
  });
}
