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

  group('sign policy regression', () {
    test('formatMinutes never prepends + for positive values', () {
      final result = formatMinutes(315);
      expect(result, '5h 15m');
      expect(result.startsWith('+'), isFalse);
    });

    test('formatMinutes with signed:false never prepends sign', () {
      expect(formatMinutes(315, signed: false), '5h 15m');
      expect(formatMinutes(-120, signed: false), '2h 0m');
    });

    test('formatSignedMinutes always prepends + for positive', () {
      expect(formatSignedMinutes(315), startsWith('+'));
    });

    test('formatSignedMinutes always prepends - for negative', () {
      expect(formatSignedMinutes(-120), startsWith('-'));
    });

    test('formatSignedMinutes zero with showPlusForZero shows +', () {
      expect(formatSignedMinutes(0, showPlusForZero: true), '+0h 00m');
    });

    test('formatSignedMinutes zero without showPlusForZero has no sign', () {
      expect(formatSignedMinutes(0, showPlusForZero: false), '0h 00m');
    });

    test('formatMinutes unsigned treats negative as absolute value', () {
      expect(formatMinutes(-120, padMinutes: true), '2h 00m');
    });

    test('formatSignedMinutes allows negative under-one-hour output', () {
      expect(formatSignedMinutes(-30), '-0h 30m');
    });

    test('formatSignedMinutes nonzero negatives never become -0h 0m', () {
      const samples = <int>[-1, -30, -59, -60, -121];
      for (final minutes in samples) {
        expect(
          formatSignedMinutes(minutes),
          isNot('-0h 0m'),
          reason: 'nonzero value $minutes formatted as -0h 0m',
        );
      }
    });
  });
}
