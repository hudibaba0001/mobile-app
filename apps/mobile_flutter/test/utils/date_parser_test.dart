import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/utils/date_parser.dart';

void main() {
  group('DateParser.tryParseDateOnly', () {
    test('parses valid dates correctly', () {
      final dt = DateParser.tryParseDateOnly('2024-05-10');
      expect(dt, isNotNull);
      expect(dt!.year, 2024);
      expect(dt.month, 5);
      expect(dt.day, 10);
    });

    test('returns null for empty or null input', () {
      expect(DateParser.tryParseDateOnly(null), isNull);
      expect(DateParser.tryParseDateOnly(''), isNull);
      expect(DateParser.tryParseDateOnly('   '), isNull);
    });

    test('returns null for malformed strings without enough parts', () {
      expect(DateParser.tryParseDateOnly('2024'), isNull);
      expect(DateParser.tryParseDateOnly('2024-05'), isNull);
    });

    test('returns null for non-numeric parts', () {
      expect(DateParser.tryParseDateOnly('202x-05-10'), isNull);
      expect(DateParser.tryParseDateOnly('year-month-day'), isNull);
    });
  });
}
