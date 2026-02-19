import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/period_summary.dart';
import 'package:myapp/reporting/period_summary_calculator.dart';
import 'package:myapp/reporting/time_range.dart';
import 'package:myapp/utils/target_hours_calculator.dart';

Entry _workEntry({
  required String id,
  required DateTime date,
  required int workedMinutes,
}) {
  return Entry.makeWorkAtomicFromShift(
    id: id,
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
  required String id,
  required DateTime date,
  required int minutes,
}) {
  return Entry.makeTravelAtomicFromLeg(
    id: id,
    userId: 'user-1',
    date: date,
    from: 'A',
    to: 'B',
    minutes: minutes,
  );
}

AbsenceEntry _absence({
  required DateTime date,
  required int minutes,
  required AbsenceType type,
}) {
  return AbsenceEntry(
    id: '${date.year}-${date.month}-${date.day}-${type.name}',
    date: date,
    minutes: minutes,
    type: type,
  );
}

void main() {
  group('PeriodSummary', () {
    test('seed scenario: target 120h, tracked 112h, leave 8h gives 0 diff', () {
      final summary = PeriodSummary.fromInputs(
        workMinutes: 112 * 60,
        travelMinutes: 0,
        paidLeaveMinutes: 8 * 60,
        targetMinutes: 120 * 60,
        startBalanceMinutes: 60,
        manualAdjustmentMinutes: 30,
      );

      expect(summary.trackedTotalMinutes, 112 * 60);
      expect(summary.accountedMinutes, 120 * 60);
      expect(summary.differenceMinutes, 0);
      expect(summary.endBalanceMinutes, 90);
    });
  });

  group('PeriodSummaryCalculator', () {
    final holidays = SwedenHolidayCalendar();
    final range = TimeRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 28));

    test('computes tracked/accounted with paid leave and excludes unpaid leave',
        () {
      final summary = PeriodSummaryCalculator.compute(
        entries: [
          _workEntry(
            id: 'w-in',
            date: DateTime(2026, 2, 10),
            workedMinutes: 8 * 60,
          ),
          _travelEntry(
            id: 't-in',
            date: DateTime(2026, 2, 10),
            minutes: 60,
          ),
          _workEntry(
            id: 'w-out',
            date: DateTime(2026, 3, 1),
            workedMinutes: 8 * 60,
          ),
        ],
        absences: [
          _absence(
            date: DateTime(2026, 2, 11),
            minutes: 120,
            type: AbsenceType.vacationPaid,
          ),
          _absence(
            date: DateTime(2026, 2, 12),
            minutes: 60,
            type: AbsenceType.unpaid,
          ),
          _absence(
            date: DateTime(2026, 3, 1),
            minutes: 120,
            type: AbsenceType.sickPaid,
          ),
        ],
        range: range,
        travelEnabled: true,
        weeklyTargetMinutes: 0,
        holidays: holidays,
        trackingStartDate: DateTime(2026, 1, 1),
        startBalanceMinutes: 30,
        manualAdjustmentMinutes: -15,
      );

      expect(summary.workMinutes, 8 * 60);
      expect(summary.travelMinutes, 60);
      expect(summary.trackedTotalMinutes, 9 * 60);
      expect(summary.paidLeaveMinutes, 120);
      expect(summary.accountedMinutes, (9 * 60) + 120);
      expect(summary.targetMinutes, 0);
      expect(summary.differenceMinutes, (9 * 60) + 120);
      expect(summary.endBalanceMinutes, 30 - 15 + ((9 * 60) + 120));
    });

    test('travel disabled keeps travel at 0 while leave still counts', () {
      final summary = PeriodSummaryCalculator.compute(
        entries: [
          _workEntry(
            id: 'w-in',
            date: DateTime(2026, 2, 10),
            workedMinutes: 8 * 60,
          ),
          _travelEntry(
            id: 't-in',
            date: DateTime(2026, 2, 10),
            minutes: 60,
          ),
        ],
        absences: [
          _absence(
            date: DateTime(2026, 2, 11),
            minutes: 120,
            type: AbsenceType.vabPaid,
          ),
        ],
        range: range,
        travelEnabled: false,
        weeklyTargetMinutes: 0,
        holidays: holidays,
        trackingStartDate: DateTime(2026, 1, 1),
        startBalanceMinutes: 0,
        manualAdjustmentMinutes: 0,
      );

      expect(summary.workMinutes, 8 * 60);
      expect(summary.travelMinutes, 0);
      expect(summary.trackedTotalMinutes, 8 * 60);
      expect(summary.paidLeaveMinutes, 120);
      expect(summary.accountedMinutes, (8 * 60) + 120);
    });

    test('clips selected range start to tracking start date', () {
      final selectedRange =
          TimeRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 10));
      final trackingStartDate = DateTime(2026, 2, 5);
      final holidays = SwedenHolidayCalendar();

      final summary = PeriodSummaryCalculator.compute(
        entries: [
          _workEntry(
            id: 'w-before-tracking-start',
            date: DateTime(2026, 2, 2),
            workedMinutes: 120,
          ),
          _workEntry(
            id: 'w-after-tracking-start',
            date: DateTime(2026, 2, 6),
            workedMinutes: 240,
          ),
          _travelEntry(
            id: 't-after-tracking-start',
            date: DateTime(2026, 2, 7),
            minutes: 60,
          ),
        ],
        absences: [
          _absence(
            date: DateTime(2026, 2, 3),
            minutes: 120,
            type: AbsenceType.sickPaid,
          ),
          _absence(
            date: DateTime(2026, 2, 8),
            minutes: 60,
            type: AbsenceType.vabPaid,
          ),
        ],
        range: selectedRange,
        travelEnabled: true,
        weeklyTargetMinutes: 2400,
        holidays: holidays,
        trackingStartDate: trackingStartDate,
        startBalanceMinutes: 0,
        manualAdjustmentMinutes: 0,
      );

      final expectedTarget = TargetHoursCalculator.scheduledMinutesInRange(
        start: DateTime(2026, 2, 5),
        endInclusive: DateTime(2026, 2, 10),
        weeklyTargetMinutes: 2400,
        holidays: holidays,
      );

      expect(summary.workMinutes, 240);
      expect(summary.travelMinutes, 60);
      expect(summary.paidLeaveMinutes, 60);
      expect(summary.trackedTotalMinutes, 300);
      expect(summary.targetMinutes, expectedTarget);
    });
  });
}
