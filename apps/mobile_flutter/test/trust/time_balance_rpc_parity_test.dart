import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/time_balance_aggregate_service.dart';
import 'package:myapp/providers/absence_provider.dart';

class _LegacyTotals {
  final int workMinutes;
  final int travelMinutes;
  final int creditedLeaveMinutes;
  final Map<String, int> creditedLeaveByType;
  final int plannedMinutes;
  final int adjustmentMinutes;
  final int deltaMinutes;

  const _LegacyTotals({
    required this.workMinutes,
    required this.travelMinutes,
    required this.creditedLeaveMinutes,
    required this.creditedLeaveByType,
    required this.plannedMinutes,
    required this.adjustmentMinutes,
    required this.deltaMinutes,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
final SwedenHolidayCalendar _holidayCalendar = SwedenHolidayCalendar();

int _scheduledMinutesForDate({
  required DateTime date,
  required int weeklyTargetMinutes,
  required Set<DateTime> customRedDays,
}) {
  final day = _dateOnly(date);
  if (customRedDays.contains(day)) return 0;
  if (_holidayCalendar.isHoliday(day)) return 0;
  if (day.weekday < DateTime.monday || day.weekday > DateTime.friday) {
    return 0;
  }

  final base = weeklyTargetMinutes ~/ 5;
  final remainder = weeklyTargetMinutes % 5;
  final workdayIndex = day.weekday - DateTime.monday; // Mon=0
  return base + (workdayIndex < remainder ? 1 : 0);
}

Map<String, int> _creditedByTypeForDay({
  required List<AbsenceEntry> absences,
  required int scheduledMinutes,
}) {
  final paid = absences.where((a) => a.isPaid).toList()
    ..sort((a, b) {
      final byType = a.type.name.compareTo(b.type.name);
      if (byType != 0) return byType;
      return (a.id ?? '').compareTo(b.id ?? '');
    });

  if (paid.isEmpty || scheduledMinutes <= 0) {
    return const <String, int>{};
  }

  var remaining = scheduledMinutes;
  final byType = <String, int>{};

  for (final absence in paid) {
    if (remaining <= 0) break;
    final requested = absence.minutes == 0 ? scheduledMinutes : absence.minutes;
    final cappedRequested =
        requested < scheduledMinutes ? requested : scheduledMinutes;
    final credited = cappedRequested < remaining ? cappedRequested : remaining;
    if (credited <= 0) continue;
    final typeKey = absence.type.name;
    byType[typeKey] = (byType[typeKey] ?? 0) + credited;
    remaining -= credited;
  }

  return byType;
}

_LegacyTotals _legacyTotals({
  required DateTime start,
  required DateTime end,
  required DateTime trackingStartDate,
  required int weeklyTargetMinutes,
  required bool travelEnabled,
  required List<Entry> entries,
  required List<AbsenceEntry> absences,
  required List<BalanceAdjustment> adjustments,
  required Set<DateTime> customRedDays,
}) {
  final effectiveStart = _dateOnly(start).isBefore(_dateOnly(trackingStartDate))
      ? _dateOnly(trackingStartDate)
      : _dateOnly(start);
  final effectiveEnd = _dateOnly(end);

  var workMinutes = 0;
  var travelMinutes = 0;
  var creditedLeaveMinutes = 0;
  var plannedMinutes = 0;
  var adjustmentMinutes = 0;
  final creditedByType = <String, int>{};

  for (var current = effectiveStart;
      !current.isAfter(effectiveEnd);
      current = DateTime(current.year, current.month, current.day + 1)) {
    final scheduled = _scheduledMinutesForDate(
      date: current,
      weeklyTargetMinutes: weeklyTargetMinutes,
      customRedDays: customRedDays,
    );
    plannedMinutes += scheduled;

    final dayEntries = entries.where((e) => _dateOnly(e.date) == current);
    for (final entry in dayEntries) {
      if (entry.type == EntryType.work) {
        workMinutes += entry.workDuration.inMinutes;
      } else if (entry.type == EntryType.travel && travelEnabled) {
        travelMinutes += entry.travelDuration.inMinutes;
      }
    }

    final dayAbsences = absences.where((a) => _dateOnly(a.date) == current);
    final dayCredited = AbsenceProvider.paidAbsenceMinutesForAbsences(
      absencesForDate: dayAbsences,
      scheduledMinutes: scheduled,
    );
    creditedLeaveMinutes += dayCredited;

    final dayByType = _creditedByTypeForDay(
      absences: dayAbsences.toList(),
      scheduledMinutes: scheduled,
    );
    for (final entry in dayByType.entries) {
      creditedByType[entry.key] =
          (creditedByType[entry.key] ?? 0) + entry.value;
    }

    adjustmentMinutes += adjustments
        .where((a) => _dateOnly(a.effectiveDate) == current)
        .fold<int>(0, (sum, a) => sum + a.deltaMinutes);
  }

  final deltaMinutes = workMinutes +
      travelMinutes +
      creditedLeaveMinutes +
      adjustmentMinutes -
      plannedMinutes;

  return _LegacyTotals(
    workMinutes: workMinutes,
    travelMinutes: travelMinutes,
    creditedLeaveMinutes: creditedLeaveMinutes,
    creditedLeaveByType: creditedByType,
    plannedMinutes: plannedMinutes,
    adjustmentMinutes: adjustmentMinutes,
    deltaMinutes: deltaMinutes,
  );
}

DailyAggregateRow _sumRows(List<DailyAggregateRow> rows) {
  var work = 0;
  var travel = 0;
  var credited = 0;
  var planned = 0;
  var adjustment = 0;
  var delta = 0;
  final byType = <String, int>{};

  for (final row in rows.where((r) => !r.isTotal)) {
    work += row.workMinutes;
    travel += row.travelMinutes;
    credited += row.creditedLeaveMinutes;
    planned += row.plannedMinutes;
    adjustment += row.adjustmentMinutes;
    delta += row.deltaMinutes;
    for (final entry in row.creditedLeaveByType.entries) {
      byType[entry.key] = (byType[entry.key] ?? 0) + entry.value;
    }
  }

  return DailyAggregateRow(
    day: null,
    workMinutes: work,
    travelMinutes: travel,
    creditedLeaveMinutes: credited,
    creditedLeaveByType: byType,
    plannedMinutes: planned,
    adjustmentMinutes: adjustment,
    deltaMinutes: delta,
    isTotal: true,
  );
}

Entry _workEntry({
  required String id,
  required DateTime date,
  required int workedMinutes,
}) {
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.work,
    date: _dateOnly(date),
    shifts: [
      Shift(
        start: DateTime(date.year, date.month, date.day, 8, 0),
        end: DateTime(date.year, date.month, date.day, 8, 0)
            .add(Duration(minutes: workedMinutes)),
        unpaidBreakMinutes: 0,
      ),
    ],
    createdAt: _dateOnly(date),
  );
}

Entry _travelEntry({
  required String id,
  required DateTime date,
  required int minutes,
}) {
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.travel,
    date: _dateOnly(date),
    from: 'A',
    to: 'B',
    travelMinutes: minutes,
    createdAt: _dateOnly(date),
  );
}

void main() {
  test('aggregate RPC mapped rows match legacy calculator (travel enabled)',
      () {
    final start = DateTime(2026, 3, 2);
    final end = DateTime(2026, 3, 7);
    final trackingStart = DateTime(2026, 3, 2);
    const weeklyTargetMinutes = 1800; // 75%
    final customRedDays = {DateTime(2026, 3, 4)};

    final entries = <Entry>[
      _workEntry(id: 'w1', date: DateTime(2026, 3, 2), workedMinutes: 240),
      _travelEntry(id: 't1', date: DateTime(2026, 3, 2), minutes: 120),
      _workEntry(id: 'w2', date: DateTime(2026, 3, 3), workedMinutes: 360),
      _workEntry(id: 'w3', date: DateTime(2026, 3, 5), workedMinutes: 300),
      _travelEntry(id: 't2', date: DateTime(2026, 3, 5), minutes: 60),
    ];

    final absences = <AbsenceEntry>[
      AbsenceEntry(
        id: 'a1',
        date: DateTime(2026, 3, 4),
        minutes: 0,
        type: AbsenceType.parentalLeave,
      ),
      AbsenceEntry(
        id: 'a2',
        date: DateTime(2026, 3, 6),
        minutes: 0,
        type: AbsenceType.parentalLeave,
      ),
      AbsenceEntry(
        id: 'a3',
        date: DateTime(2026, 3, 6),
        minutes: 120,
        type: AbsenceType.sickPaid,
      ),
    ];

    final adjustments = <BalanceAdjustment>[
      BalanceAdjustment(
        id: 'adj1',
        userId: 'user-1',
        effectiveDate: DateTime(2026, 3, 2),
        deltaMinutes: 60,
      ),
      BalanceAdjustment(
        id: 'adj2',
        userId: 'user-1',
        effectiveDate: DateTime(2026, 3, 5),
        deltaMinutes: -30,
      ),
    ];

    final legacy = _legacyTotals(
      start: start,
      end: end,
      trackingStartDate: trackingStart,
      weeklyTargetMinutes: weeklyTargetMinutes,
      travelEnabled: true,
      entries: entries,
      absences: absences,
      adjustments: adjustments,
      customRedDays: customRedDays,
    );

    final rpcRows = <DailyAggregateRow>[
      DailyAggregateRow.fromMap({
        'day': '2026-03-02',
        'work_minutes': 240,
        'travel_minutes': 120,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': 60,
        'delta_minutes': 60,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-03',
        'work_minutes': 360,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-04',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 0,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-05',
        'work_minutes': 300,
        'travel_minutes': 60,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': -30,
        'delta_minutes': -30,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-06',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 360,
        'credited_leave_by_type': <String, dynamic>{'parentalLeave': 360},
        'planned_minutes': 360,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-07',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 0,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
    ];

    final rpcTotals = _sumRows(rpcRows);

    expect(rpcTotals.workMinutes, legacy.workMinutes);
    expect(rpcTotals.travelMinutes, legacy.travelMinutes);
    expect(rpcTotals.creditedLeaveMinutes, legacy.creditedLeaveMinutes);
    expect(rpcTotals.plannedMinutes, legacy.plannedMinutes);
    expect(rpcTotals.adjustmentMinutes, legacy.adjustmentMinutes);
    expect(rpcTotals.deltaMinutes, legacy.deltaMinutes);
    expect(
      rpcTotals.creditedLeaveByType['parentalLeave'],
      legacy.creditedLeaveByType['parentalLeave'],
    );
  });

  test('aggregate RPC mapped rows match legacy calculator (travel disabled)',
      () {
    final start = DateTime(2026, 3, 2);
    final end = DateTime(2026, 3, 7);
    final trackingStart = DateTime(2026, 3, 2);
    const weeklyTargetMinutes = 1800;
    final customRedDays = {DateTime(2026, 3, 4)};

    final entries = <Entry>[
      _workEntry(id: 'w1', date: DateTime(2026, 3, 2), workedMinutes: 240),
      _travelEntry(id: 't1', date: DateTime(2026, 3, 2), minutes: 120),
      _workEntry(id: 'w2', date: DateTime(2026, 3, 3), workedMinutes: 360),
      _workEntry(id: 'w3', date: DateTime(2026, 3, 5), workedMinutes: 300),
      _travelEntry(id: 't2', date: DateTime(2026, 3, 5), minutes: 60),
    ];

    final absences = <AbsenceEntry>[
      AbsenceEntry(
        id: 'a1',
        date: DateTime(2026, 3, 6),
        minutes: 0,
        type: AbsenceType.parentalLeave,
      ),
    ];

    final adjustments = <BalanceAdjustment>[
      BalanceAdjustment(
        id: 'adj1',
        userId: 'user-1',
        effectiveDate: DateTime(2026, 3, 2),
        deltaMinutes: 60,
      ),
      BalanceAdjustment(
        id: 'adj2',
        userId: 'user-1',
        effectiveDate: DateTime(2026, 3, 5),
        deltaMinutes: -30,
      ),
    ];

    final legacy = _legacyTotals(
      start: start,
      end: end,
      trackingStartDate: trackingStart,
      weeklyTargetMinutes: weeklyTargetMinutes,
      travelEnabled: false,
      entries: entries,
      absences: absences,
      adjustments: adjustments,
      customRedDays: customRedDays,
    );

    final rpcRows = <DailyAggregateRow>[
      DailyAggregateRow.fromMap({
        'day': '2026-03-02',
        'work_minutes': 240,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': 60,
        'delta_minutes': -60,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-03',
        'work_minutes': 360,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-04',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 0,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-05',
        'work_minutes': 300,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 360,
        'adjustment_minutes': -30,
        'delta_minutes': -90,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-06',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 360,
        'credited_leave_by_type': <String, dynamic>{'parentalLeave': 360},
        'planned_minutes': 360,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
      DailyAggregateRow.fromMap({
        'day': '2026-03-07',
        'work_minutes': 0,
        'travel_minutes': 0,
        'credited_leave_minutes': 0,
        'credited_leave_by_type': <String, dynamic>{},
        'planned_minutes': 0,
        'adjustment_minutes': 0,
        'delta_minutes': 0,
        'is_total': false,
      }),
    ];

    final rpcTotals = _sumRows(rpcRows);

    expect(rpcTotals.workMinutes, legacy.workMinutes);
    expect(rpcTotals.travelMinutes, legacy.travelMinutes);
    expect(rpcTotals.creditedLeaveMinutes, legacy.creditedLeaveMinutes);
    expect(rpcTotals.plannedMinutes, legacy.plannedMinutes);
    expect(rpcTotals.adjustmentMinutes, legacy.adjustmentMinutes);
    expect(rpcTotals.deltaMinutes, legacy.deltaMinutes);
  });

  test(
      'official holiday day has planned_minutes = 0 for legacy and RPC parsed row',
      () {
    final holidayDay = DateTime(2026, 1, 6); // Epiphany (weekday holiday)
    final trackingStart = DateTime(2026, 1, 1);
    const weeklyTargetMinutes = 1800;

    final legacy = _legacyTotals(
      start: holidayDay,
      end: holidayDay,
      trackingStartDate: trackingStart,
      weeklyTargetMinutes: weeklyTargetMinutes,
      travelEnabled: true,
      entries: const <Entry>[],
      absences: const <AbsenceEntry>[],
      adjustments: const <BalanceAdjustment>[],
      customRedDays: const <DateTime>{},
    );

    final rpcRow = DailyAggregateRow.fromMap({
      'day': '2026-01-06',
      'work_minutes': 0,
      'travel_minutes': 0,
      'credited_leave_minutes': 0,
      'credited_leave_by_type': <String, dynamic>{},
      'planned_minutes': 0,
      'adjustment_minutes': 0,
      'delta_minutes': 0,
      'is_total': false,
    });

    expect(legacy.plannedMinutes, 0);
    expect(rpcRow.plannedMinutes, 0);
  });
}
