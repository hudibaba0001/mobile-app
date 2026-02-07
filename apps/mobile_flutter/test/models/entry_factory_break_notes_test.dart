import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

/// Unit tests to verify Entry.makeWorkAtomicFromShift preserves break, notes, and location
///
/// This test ensures that when creating an atomic Entry from a Shift:
/// - unpaidBreakMinutes is preserved
/// - notes are preserved
/// - location is preserved
/// - All other shift fields remain intact
void main() {
  group('Entry.makeWorkAtomicFromShift break and notes persistence', () {
    test(
        'makeWorkAtomicFromShift preserves unpaidBreakMinutes, notes, and location',
        () {
      // Create Shift with break=30, notes='DBG', and location='Office'
      // This matches the SQL verification scenario: 08:00-12:00, break=30, notes="DBG"
      final shift = Shift(
        start: DateTime(2025, 1, 15, 8, 0),
        end: DateTime(2025, 1, 15, 12, 0),
        unpaidBreakMinutes: 30,
        notes: 'DBG',
        location: 'Office',
      );

      // Create Entry via factory
      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: shift,
      );

      // Assert entry has exactly one shift (atomic entry)
      expect(entry.shifts, isNotNull);
      expect(entry.shifts!.length, 1,
          reason: 'Atomic entry must have exactly one shift');

      final savedShift = entry.shifts!.first;

      // Assert break and notes are preserved (critical for SQL verification)
      expect(savedShift.unpaidBreakMinutes, 30,
          reason:
              'unpaidBreakMinutes must be preserved by makeWorkAtomicFromShift. '
              'SQL verification expects unpaid_break_minutes=30');
      expect(savedShift.notes, 'DBG',
          reason: 'notes must be preserved by makeWorkAtomicFromShift. '
              'SQL verification expects notes="DBG"');

      // Assert location is also preserved
      expect(savedShift.location, 'Office',
          reason: 'location must be preserved by makeWorkAtomicFromShift');

      // Assert other fields are also preserved
      expect(savedShift.start, DateTime(2025, 1, 15, 8, 0),
          reason: 'start time must be preserved');
      expect(savedShift.end, DateTime(2025, 1, 15, 12, 0),
          reason: 'end time must be preserved');
    });

    test('makeWorkAtomicFromShift preserves null notes', () {
      final shift = Shift(
        start: DateTime(2025, 1, 15, 8, 0),
        end: DateTime(2025, 1, 15, 12, 0),
        unpaidBreakMinutes: 0,
        notes: null, // Explicitly null
      );

      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: shift,
      );

      expect(entry.shifts!.first.notes, isNull);
      expect(entry.shifts!.first.unpaidBreakMinutes, 0);
    });

    test('makeWorkAtomicFromShift preserves empty string notes as null', () {
      final shift = Shift(
        start: DateTime(2025, 1, 15, 8, 0),
        end: DateTime(2025, 1, 15, 12, 0),
        unpaidBreakMinutes: 15,
        notes: '', // Empty string
      );

      final entry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: shift,
      );

      // Empty string notes should be preserved as-is (not converted to null by factory)
      // The form logic handles empty->null conversion
      expect(entry.shifts!.first.notes, '');
      expect(entry.shifts!.first.unpaidBreakMinutes, 15);
    });
  });
}
