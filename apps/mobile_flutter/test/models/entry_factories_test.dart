import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('Entry factory methods', () {
    test('makeWorkAtomicFromShift() produces shifts.length==1', () {
      final shift = Shift(
        start: DateTime(2025, 1, 15, 9, 0),
        end: DateTime(2025, 1, 15, 17, 0),
        unpaidBreakMinutes: 30,
        location: 'Office',
        notes: 'Regular work',
      );

      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: shift,
        dayNotes: 'Day notes',
      );

      // Should have exactly 1 shift
      expect(entry.shifts, isNotNull);
      expect(entry.shifts!.length, 1);
      expect(entry.shifts!.first, shift);

      // Entry properties
      expect(entry.type, EntryType.work);
      expect(entry.userId, 'user1');
      expect(entry.date, DateTime(2025, 1, 15));
      expect(entry.notes, 'Day notes');
      expect(entry.updatedAt, isNotNull);
    });

    test('makeTravelAtomicFromLeg() produces one travel leg entry', () {
      final entry = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        from: 'Home',
        to: 'Office',
        minutes: 30,
        dayNotes: 'Commute',
        fromPlaceId: 'place1',
        toPlaceId: 'place2',
        source: 'auto',
        distanceKm: 15.5,
        calculatedAt: DateTime(2025, 1, 15, 8, 0),
      );

      // Entry properties
      expect(entry.type, EntryType.travel);
      expect(entry.userId, 'user1');
      expect(entry.date, DateTime(2025, 1, 15));
      expect(entry.from, 'Home');
      expect(entry.to, 'Office');
      expect(entry.travelMinutes, 30);
      expect(entry.notes, 'Commute');

      // Should be atomic (single leg, not in travelLegs list)
      // Note: makeTravelAtomicFromLeg creates legacy format (from/to fields)
      // not travelLegs list, so we check the legacy fields
      expect(entry.from, isNotNull);
      expect(entry.to, isNotNull);
      expect(entry.travelMinutes, 30);
    });

    test('makeWorkAtomicFromShift() with custom id and createdAt', () {
      final customId = 'custom-id-123';
      final customCreatedAt = DateTime(2025, 1, 1);

      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: Shift(
          start: DateTime(2025, 1, 15, 9, 0),
          end: DateTime(2025, 1, 15, 17, 0),
        ),
        id: customId,
        createdAt: customCreatedAt,
      );

      expect(entry.id, customId);
      expect(entry.createdAt, customCreatedAt);
      expect(entry.shifts!.length, 1);
    });

    test('makeTravelAtomicFromLeg() with segment order', () {
      final entry = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        from: 'A',
        to: 'B',
        minutes: 20,
        segmentOrder: 1,
        totalSegments: 3,
      );

      expect(entry.segmentOrder, 1);
      expect(entry.totalSegments, 3);
    });
  });
}
