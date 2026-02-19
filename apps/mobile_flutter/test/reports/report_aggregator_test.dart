import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/reports/report_aggregator.dart';
import 'package:myapp/reports/report_query_service.dart';

Entry _workEntry({
  required String id,
  required DateTime date,
  int breakMinutes = 0,
}) {
  return Entry.makeWorkAtomicFromShift(
    id: id,
    userId: 'user-1',
    date: date,
    shift: Shift(
      start: DateTime(date.year, date.month, date.day, 8, 0),
      end: DateTime(date.year, date.month, date.day, 16, 0),
      unpaidBreakMinutes: breakMinutes,
      location: 'HQ',
    ),
  );
}

Entry _travelEntry({
  required String id,
  required DateTime date,
  required String from,
  required String to,
  required int minutes,
}) {
  return Entry.makeTravelAtomicFromLeg(
    id: id,
    userId: 'user-1',
    date: date,
    from: from,
    to: to,
    minutes: minutes,
  );
}

AbsenceEntry _leave(DateTime date, {required int minutes, AbsenceType? type}) {
  return AbsenceEntry(
    id: '${date.year}-${date.month}-${date.day}',
    date: date,
    minutes: minutes,
    type: type ?? AbsenceType.vacationPaid,
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

ReportQueryService _queryService({
  required List<Entry> entries,
  required Map<int, List<AbsenceEntry>> leavesByYear,
  required UserProfile profile,
  required List<BalanceAdjustment> adjustments,
}) {
  return ReportQueryService(
    currentUserIdGetter: () => 'user-1',
    entriesInRangeFetcher: (_, __, ___) async => entries,
    absencesForYearFetcher: (_, year) async => leavesByYear[year] ?? const [],
    profileFetcher: () async => profile,
    adjustmentsFetcher: (_) async => adjustments,
  );
}

void main() {
  group('ReportAggregator', () {
    test(
        'keeps tracked totals entries-only and computes balance offsets separately',
        () async {
      final queryService = _queryService(
        entries: [
          _workEntry(id: 'w1', date: DateTime(2026, 1, 5)),
          _travelEntry(
            id: 't1',
            date: DateTime(2026, 1, 6),
            from: 'A',
            to: 'B',
            minutes: 60,
          ),
        ],
        leavesByYear: const {},
        profile: UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2025, 1, 1),
          openingFlexMinutes: 600,
        ),
        adjustments: [
          _adjustment(id: 'before', date: DateTime(2025, 12, 20), minutes: 30),
          _adjustment(id: 'inside', date: DateTime(2026, 1, 10), minutes: -15),
          _adjustment(id: 'after', date: DateTime(2026, 2, 1), minutes: 20),
        ],
      );

      final aggregator = ReportAggregator(queryService: queryService);
      final summary = await aggregator.buildSummary(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      expect(summary.workMinutes, 480);
      expect(summary.travelMinutes, 60);
      expect(summary.totalTrackedMinutes, 540);
      expect(summary.trackedMinutes, 540);

      expect(summary.balanceAdjustmentMinutesInRange, -15);
      expect(summary.openingBalanceMinutes, 600);
      expect(summary.startingBalanceMinutes, 630);
      expect(summary.closingBalanceMinutes, 615);

      // Guardrail: tracked totals must never include opening/adjustments.
      expect(
        summary.trackedMinutes,
        isNot(summary.closingBalanceMinutes),
      );
    });

    test('aggregates top routes and leave summary from one report summary',
        () async {
      final queryService = _queryService(
        entries: [
          _travelEntry(
            id: 't1',
            date: DateTime(2026, 1, 2),
            from: 'Stockholm',
            to: 'Uppsala',
            minutes: 30,
          ),
          _travelEntry(
            id: 't2',
            date: DateTime(2026, 1, 3),
            from: 'Stockholm',
            to: 'Uppsala',
            minutes: 45,
          ),
          _travelEntry(
            id: 't3',
            date: DateTime(2026, 1, 4),
            from: 'Uppsala',
            to: 'Vasteras',
            minutes: 20,
          ),
        ],
        leavesByYear: {
          2026: [
            _leave(DateTime(2026, 1, 8), minutes: 0), // full day
            _leave(DateTime(2026, 1, 9), minutes: 240), // half day
          ],
        },
        profile: UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2025, 1, 1),
          openingFlexMinutes: 0,
        ),
        adjustments: const [],
      );

      final aggregator = ReportAggregator(queryService: queryService);
      final summary = await aggregator.buildSummary(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      expect(summary.travelInsights.tripCount, 3);
      expect(summary.travelInsights.topRoutes, isNotEmpty);
      expect(summary.travelInsights.topRoutes.first.from, 'Stockholm');
      expect(summary.travelInsights.topRoutes.first.to, 'Uppsala');
      expect(summary.travelInsights.topRoutes.first.tripCount, 2);
      expect(summary.travelInsights.topRoutes.first.totalMinutes, 75);

      expect(summary.leavesSummary.totalEntries, 2);
      expect(summary.leavesSummary.totalMinutes, 720);
      expect(summary.leavesSummary.totalDays, 1.5);
    });

    test(
        'when opening balance effective date is inside range it is applied once',
        () async {
      final queryService = _queryService(
        entries: const [],
        leavesByYear: const {},
        profile: UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2026, 1, 10),
          openingFlexMinutes: 120,
        ),
        adjustments: const [],
      );

      final aggregator = ReportAggregator(queryService: queryService);
      final summary = await aggregator.buildSummary(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      expect(summary.startingBalanceMinutes, 0);
      expect(summary.closingBalanceMinutes, 120);
      expect(summary.openingBalanceMinutes, 120);
      expect(summary.balanceAdjustmentMinutesInRange, 0);
    });

    test(
        'adjustment on start date is included in starting balance only',
        () async {
      final queryService = _queryService(
        entries: const [],
        leavesByYear: const {},
        profile: UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2025, 1, 1),
          openingFlexMinutes: 100,
        ),
        adjustments: [
          _adjustment(id: 'on_start', date: DateTime(2026, 1, 1), minutes: 30),
          _adjustment(id: 'inside', date: DateTime(2026, 1, 2), minutes: -10),
        ],
      );

      final aggregator = ReportAggregator(queryService: queryService);
      final summary = await aggregator.buildSummary(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      expect(summary.startingBalanceMinutes, 130);
      expect(summary.balanceAdjustmentMinutesInRange, -10);
      expect(summary.closingBalanceMinutes, 120);
      expect(
        summary.balanceOffsets.adjustmentsInRange
            .map((e) => e.effectiveDate)
            .toList(),
        [DateTime(2026, 1, 2)],
      );
    });

    test('normalizes route grouping by trim and case', () async {
      final queryService = _queryService(
        entries: [
          _travelEntry(
            id: 't1',
            date: DateTime(2026, 1, 2),
            from: 'Stockholm ',
            to: 'Uppsala',
            minutes: 30,
          ),
          _travelEntry(
            id: 't2',
            date: DateTime(2026, 1, 3),
            from: 'stockholm',
            to: 'uppsala ',
            minutes: 40,
          ),
        ],
        leavesByYear: const {},
        profile: UserProfile(
          id: 'user-1',
          trackingStartDate: DateTime(2025, 1, 1),
          openingFlexMinutes: 0,
        ),
        adjustments: const [],
      );

      final aggregator = ReportAggregator(queryService: queryService);
      final summary = await aggregator.buildSummary(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      expect(summary.travelInsights.topRoutes, hasLength(1));
      expect(summary.travelInsights.topRoutes.first.tripCount, 2);
      expect(summary.travelInsights.topRoutes.first.totalMinutes, 70);
    });
  });
}
