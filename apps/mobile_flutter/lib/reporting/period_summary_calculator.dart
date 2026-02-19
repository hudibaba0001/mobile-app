import '../calendar/sweden_holidays.dart';
import '../models/absence.dart';
import '../models/entry.dart';
import '../utils/target_hours_calculator.dart';
import 'leave_minutes.dart';
import 'period_summary.dart';
import 'time_range.dart';
import 'tracked_time_calculator.dart';

class PeriodSummaryCalculator {
  static PeriodSummary compute({
    required List<Entry> entries,
    required List<AbsenceEntry> absences,
    required TimeRange range,
    required bool travelEnabled,
    required int weeklyTargetMinutes,
    required SwedenHolidayCalendar holidays,
    required DateTime trackingStartDate,
    required int startBalanceMinutes,
    required int manualAdjustmentMinutes,
  }) {
    final tracked = TrackedTimeCalculator.computeTrackedSummary(
      entries: entries,
      range: range,
      travelEnabled: travelEnabled,
    );

    final paidLeaveMinutes = summarizeLeaveMinutes(
      absences.where((absence) => range.contains(absence.date)),
    ).paidMinutes;

    final normalizedTrackingStart = DateTime(
      trackingStartDate.year,
      trackingStartDate.month,
      trackingStartDate.day,
    );
    final targetStart = range.startInclusive.isBefore(normalizedTrackingStart)
        ? normalizedTrackingStart
        : range.startInclusive;
    final targetEndInclusive =
        range.endExclusive.subtract(const Duration(days: 1));

    final targetMinutes = targetEndInclusive.isBefore(targetStart)
        ? 0
        : TargetHoursCalculator.scheduledMinutesInRange(
            start: targetStart,
            endInclusive: targetEndInclusive,
            weeklyTargetMinutes: weeklyTargetMinutes,
            holidays: holidays,
          );

    return PeriodSummary.fromInputs(
      workMinutes: tracked.workMinutes,
      travelMinutes: tracked.travelMinutes,
      paidLeaveMinutes: paidLeaveMinutes,
      targetMinutes: targetMinutes,
      startBalanceMinutes: startBalanceMinutes,
      manualAdjustmentMinutes: manualAdjustmentMinutes,
    );
  }
}
