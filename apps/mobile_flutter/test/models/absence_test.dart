import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/absence.dart';

void main() {
  group('AbsenceEntry.fromMap', () {
    test(
        'throws FormatException for invalid date string without defaulting to today',
        () {
      final map = {
        'id': 'a1',
        'date': 'invalid-date', // Bad date format
        'type': 'sickPaid',
        'minutes': 480,
      };

      expect(
        () => AbsenceEntry.fromMap(map),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Invalid date'))),
      );
    });

    test('throws FormatException for out of bounds dates', () {
      final map = {
        'id': 'a1',
        'date': '2024-02-30', // Invalid leap day
        'type': 'sickPaid',
        'minutes': 480,
      };

      expect(
        () => AbsenceEntry.fromMap(map),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Invalid date'))),
      );
    });

    test('parses successfully for valid date', () {
      final map = {
        'id': 'a1',
        'date': '2024-02-29', // Valid leap day
        'type': 'sickPaid',
        'minutes': 480,
      };

      final entry = AbsenceEntry.fromMap(map);
      expect(entry.date.year, 2024);
      expect(entry.date.month, 2);
      expect(entry.date.day, 29);
      expect(entry.type, AbsenceType.sickPaid);
    });
  });
}
