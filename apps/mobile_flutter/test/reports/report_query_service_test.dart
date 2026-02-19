import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/reports/report_query_service.dart';

Entry _workEntry({
  required String id,
  required DateTime date,
  int workedMinutes = 480,
}) {
  final start = DateTime(date.year, date.month, date.day, 8, 0);
  final end = start.add(Duration(minutes: workedMinutes));
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.work,
    date: date,
    shifts: [
      Shift(
        start: start,
        end: end,
      ),
    ],
    createdAt: DateTime(2026, 1, 1),
  );
}

Entry _travelEntry({
  required String id,
  required DateTime date,
  int minutes = 60,
}) {
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.travel,
    date: date,
    from: 'A',
    to: 'B',
    travelMinutes: minutes,
    createdAt: DateTime(2026, 1, 1),
  );
}

AbsenceEntry _leave(DateTime date, {int minutes = 480}) {
  return AbsenceEntry(
    id: '${date.year}-${date.month}-${date.day}',
    date: date,
    minutes: minutes,
    type: AbsenceType.vacationPaid,
  );
}

BalanceAdjustment _adjustment({
  required String id,
  required DateTime date,
  required int minutes,
}) {
  return BalanceAdjustment(
    id: id,
    userId: 'user-1',
    effectiveDate: date,
    deltaMinutes: minutes,
  );
}

void main() {
  group('ReportQueryService.getReportData', () {
    test('handles range crossing year boundary and bounds entries/leaves',
        () async {
      final requestedEntryRanges = <({DateTime start, DateTime end})>[];
      final requestedYears = <int>[];

      final service = ReportQueryService(
        currentUserIdGetter: () => 'user-1',
        entriesInRangeFetcher: (userId, start, end) async {
          requestedEntryRanges.add((start: start, end: end));
          return [
            _workEntry(id: 'before', date: DateTime(2025, 12, 27)),
            _workEntry(id: 'inside_start', date: DateTime(2025, 12, 28)),
            _travelEntry(id: 'inside_mid', date: DateTime(2026, 1, 2)),
            _travelEntry(id: 'after', date: DateTime(2026, 1, 6)),
          ];
        },
        absencesForYearFetcher: (userId, year) async {
          requestedYears.add(year);
          if (year == 2025) {
            return [
              _leave(DateTime(2025, 12, 27)),
              _leave(DateTime(2025, 12, 30)),
            ];
          }
          if (year == 2026) {
            return [
              _leave(DateTime(2026, 1, 3)),
              _leave(DateTime(2026, 1, 7)),
            ];
          }
          return const [];
        },
        profileFetcher: () async => UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2025, 1, 1),
          openingFlexMinutes: 120,
        ),
        adjustmentsFetcher: (_) async => const [],
      );

      final data = await service.getReportData(
        ReportQuerySpec(
          start: DateTime(2025, 12, 28),
          end: DateTime(2026, 1, 5),
        ),
      );

      expect(requestedEntryRanges, hasLength(1));
      expect(
        requestedEntryRanges.single.start,
        DateTime(2025, 12, 28),
      );
      expect(
        requestedEntryRanges.single.end,
        DateTime(2026, 1, 5),
      );
      expect(requestedYears, [2025, 2026]);

      expect(
        data.entriesInRange.map((entry) => entry.id).toList(),
        ['inside_start', 'inside_mid'],
      );
      expect(
        data.leavesInRange.map((leave) => leave.date).toList(),
        [DateTime(2025, 12, 30), DateTime(2026, 1, 3)],
      );
    });

    test('returns adjustmentsUpToEnd and adjustmentsInRange separately',
        () async {
      final service = ReportQueryService(
        currentUserIdGetter: () => 'user-1',
        entriesInRangeFetcher: (_, __, ___) async => const [],
        absencesForYearFetcher: (_, __) async => const [],
        profileFetcher: () async => UserProfile(id: 'user-1'),
        adjustmentsFetcher: (_) async => [
          _adjustment(id: 'before', date: DateTime(2025, 12, 31), minutes: -30),
          _adjustment(id: 'on_start', date: DateTime(2026, 1, 1), minutes: 10),
          _adjustment(id: 'inside', date: DateTime(2026, 1, 12), minutes: 45),
          _adjustment(id: 'after', date: DateTime(2026, 2, 1), minutes: 15),
        ],
      );

      final data = await service.getReportData(
        ReportQuerySpec(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
      );

      expect(
        data.adjustmentsUpToEnd.map((adj) => adj.id).toList(),
        ['before', 'on_start', 'inside'],
      );
      expect(
        data.adjustmentsInRange.map((adj) => adj.id).toList(),
        ['inside'],
      );
    });

    test(
        'type filtering uses EntryFilter and adjustments do not affect entries',
        () async {
      final entries = [
        _workEntry(id: 'work', date: DateTime(2026, 1, 10), workedMinutes: 480),
        _travelEntry(id: 'travel', date: DateTime(2026, 1, 10), minutes: 60),
      ];

      final service = ReportQueryService(
        currentUserIdGetter: () => 'user-1',
        entriesInRangeFetcher: (_, __, ___) async => entries,
        absencesForYearFetcher: (_, __) async => const [],
        profileFetcher: () async => UserProfile(id: 'user-1'),
        adjustmentsFetcher: (_) async => [
          _adjustment(id: 'adj', date: DateTime(2026, 1, 10), minutes: 999),
        ],
      );

      final allData = await service.getReportData(
        ReportQuerySpec(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
      );
      final travelOnlyData = await service.getReportData(
        ReportQuerySpec(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
          selectedType: EntryType.travel,
        ),
      );

      expect(allData.entriesInRange.map((entry) => entry.id).toList(), [
        'work',
        'travel',
      ]);
      expect(
        travelOnlyData.entriesInRange.map((entry) => entry.id).toList(),
        ['travel'],
      );
      expect(
        allData.entriesInRange
            .fold<int>(0, (sum, entry) => sum + entry.totalDuration.inMinutes),
        540,
      );
      expect(allData.adjustmentsInRange.map((adj) => adj.id).toList(), ['adj']);
    });
  });
}
