import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/period_summary_calculator.dart';
import 'package:myapp/reporting/time_range.dart';

Entry _workEntry({
  required DateTime date,
  required int workedMinutes,
}) {
  return Entry.makeWorkAtomicFromShift(
    id: 'work-${date.toIso8601String()}',
    userId: 'user-1',
    date: date,
    shift: Shift(
      start: DateTime(date.year, date.month, date.day, 8, 0),
      end: DateTime(date.year, date.month, date.day, 8, 0)
          .add(Duration(minutes: workedMinutes)),
    ),
  );
}

Entry _travelEntry({
  required DateTime date,
  required int minutes,
}) {
  return Entry.makeTravelAtomicFromLeg(
    id: 'travel-${date.toIso8601String()}',
    userId: 'user-1',
    date: date,
    from: 'A',
    to: 'B',
    minutes: minutes,
  );
}

void main() {
  test(
      'travel contributes to actual/logged minutes when enabled; disabled keeps work-only actual',
      () {
    final day = DateTime(2026, 2, 27); // Friday
    final range = TimeRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 28));
    final trackingStartDate = DateTime(2026, 2, 27);
    const weeklyTargetMinutes = 1800; // 75%
    const noOffsets = 0;

    final entries = [
      _workEntry(date: day, workedMinutes: 240), // 4h work
      _travelEntry(date: day, minutes: 120), // 2h travel
    ];

    // Scenario A: travelEnabled = true
    final enabled = PeriodSummaryCalculator.compute(
      entries: entries,
      absences: const <AbsenceEntry>[],
      range: range,
      travelEnabled: true,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: SwedenHolidayCalendar(),
      trackingStartDate: trackingStartDate,
      startBalanceMinutes: noOffsets,
      manualAdjustmentMinutes: noOffsets,
    );

    // 1) actual/logged equivalent used by balance engine = trackedTotalMinutes
    expect(enabled.trackedTotalMinutes, 360);
    // 2) planned minutes for Feb 27-28 at 75% = 360
    expect(enabled.targetMinutes, 360);
    // 3) delta = accounted - planned = 0
    expect(enabled.differenceMinutes, 0);

    // Scenario B: travelEnabled = false (control)
    final disabled = PeriodSummaryCalculator.compute(
      entries: entries,
      absences: const <AbsenceEntry>[],
      range: range,
      travelEnabled: false,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: SwedenHolidayCalendar(),
      trackingStartDate: trackingStartDate,
      startBalanceMinutes: noOffsets,
      manualAdjustmentMinutes: noOffsets,
    );

    expect(disabled.trackedTotalMinutes, 240);
    expect(disabled.targetMinutes, 360);
    expect(disabled.differenceMinutes, -120);
  });
}
