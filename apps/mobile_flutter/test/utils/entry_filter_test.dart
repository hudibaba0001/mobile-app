import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/utils/entry_filter.dart';
import 'package:myapp/utils/entry_filter_spec.dart';

Entry _entry({
  required String id,
  required EntryType type,
  required DateTime date,
  String? notes,
  String? from,
  String? to,
}) {
  return Entry(
    id: id,
    userId: 'user-1',
    type: type,
    date: date,
    notes: notes,
    from: from,
    to: to,
    travelMinutes: type == EntryType.travel ? 30 : null,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('EntryFilter', () {
    test('includes entries exactly on inclusive start and end boundaries', () {
      final entries = [
        _entry(id: 'a', type: EntryType.work, date: DateTime(2026, 1, 10)),
        _entry(id: 'b', type: EntryType.work, date: DateTime(2026, 1, 11)),
        _entry(id: 'c', type: EntryType.travel, date: DateTime(2026, 1, 12)),
        _entry(id: 'd', type: EntryType.travel, date: DateTime(2026, 1, 13)),
      ];

      final spec = EntryFilterSpec(
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 1, 12, 23, 59, 59, 999),
      );

      final filtered = EntryFilter.filterEntries(entries, spec);
      expect(filtered.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('excludes entries before start and after end (no overlap)', () {
      final entries = [
        _entry(id: 'a', type: EntryType.work, date: DateTime(2026, 1, 9)),
        _entry(id: 'b', type: EntryType.work, date: DateTime(2026, 1, 10)),
        _entry(id: 'c', type: EntryType.travel, date: DateTime(2026, 1, 13)),
      ];

      final spec = EntryFilterSpec(
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 1, 12, 23, 59, 59, 999),
      );

      final filtered = EntryFilter.filterEntries(entries, spec);
      expect(filtered.map((e) => e.id).toList(), ['b']);
    });

    test('applies work-only and travel-only type filtering', () {
      final entries = [
        _entry(id: 'work', type: EntryType.work, date: DateTime(2026, 1, 10)),
        _entry(
          id: 'travel',
          type: EntryType.travel,
          date: DateTime(2026, 1, 10),
        ),
      ];

      final workOnly = EntryFilter.filterEntries(
        entries,
        const EntryFilterSpec(selectedType: EntryType.work),
      );
      final travelOnly = EntryFilter.filterEntries(
        entries,
        const EntryFilterSpec(selectedType: EntryType.travel),
      );

      expect(workOnly.map((e) => e.id).toList(), ['work']);
      expect(travelOnly.map((e) => e.id).toList(), ['travel']);
    });

    test('matches search in notes and travel route fields', () {
      final entries = [
        _entry(
          id: 'work',
          type: EntryType.work,
          date: DateTime(2026, 1, 10),
          notes: 'Client meeting',
        ),
        _entry(
          id: 'travel',
          type: EntryType.travel,
          date: DateTime(2026, 1, 10),
          from: 'Stockholm',
          to: 'Uppsala',
        ),
      ];

      final notesMatch = EntryFilter.filterEntries(
        entries,
        const EntryFilterSpec(searchQuery: 'meeting'),
      );
      final routeMatch = EntryFilter.filterEntries(
        entries,
        const EntryFilterSpec(searchQuery: 'stock'),
      );
      final noMatch = EntryFilter.filterEntries(
        entries,
        const EntryFilterSpec(searchQuery: 'not-found'),
      );

      expect(notesMatch.map((e) => e.id).toList(), ['work']);
      expect(routeMatch.map((e) => e.id).toList(), ['travel']);
      expect(noMatch, isEmpty);
    });
  });
}
