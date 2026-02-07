import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('Entry total work duration', () {
    test('sum of workedMinutes across shifts', () {
      final entry = Entry(
        id: 'test-entry',
        userId: 'user1',
        type: EntryType.work,
        date: DateTime(2025, 1, 15),
        shifts: [
          Shift(
            start: DateTime(2025, 1, 15, 8, 0),
            end: DateTime(2025, 1, 15, 12, 0), // 4 hours = 240 minutes
            unpaidBreakMinutes: 15,
          ),
          Shift(
            start: DateTime(2025, 1, 15, 13, 0),
            end: DateTime(2025, 1, 15, 17, 0), // 4 hours = 240 minutes
            unpaidBreakMinutes: 30,
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Shift 1: 240 - 15 = 225 worked minutes
      // Shift 2: 240 - 30 = 210 worked minutes
      // Total: 225 + 210 = 435 worked minutes
      expect(entry.totalWorkDuration?.inMinutes ?? 0, 435);
    });

    test('single shift entry', () {
      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: Shift(
          start: DateTime(2025, 1, 15, 9, 0),
          end: DateTime(2025, 1, 15, 17, 0), // 8 hours = 480 minutes
          unpaidBreakMinutes: 30,
        ),
      );

      // 480 - 30 = 450 worked minutes
      expect(entry.totalWorkDuration?.inMinutes ?? 0, 450);
    });

    test('entry with no shifts returns zero duration', () {
      final entry = Entry(
        id: 'test-entry',
        userId: 'user1',
        type: EntryType.work,
        date: DateTime(2025, 1, 15),
        shifts: null,
        createdAt: DateTime.now(),
      );

      expect(entry.totalWorkDuration?.inMinutes ?? 0, 0);
    });

    test('entry with empty shifts list returns zero duration', () {
      final entry = Entry(
        id: 'test-entry',
        userId: 'user1',
        type: EntryType.work,
        date: DateTime(2025, 1, 15),
        shifts: [],
        createdAt: DateTime.now(),
      );

      expect(entry.totalWorkDuration?.inMinutes ?? 0, 0);
    });
  });
}
