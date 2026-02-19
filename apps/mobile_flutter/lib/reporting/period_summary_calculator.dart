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
    final normalizedTrackingStart = DateTime(
      trackingStartDate.year,
      trackingStartDate.month,
      trackingStartDate.day,
    );
    final effectiveRange = range.clipStart(normalizedTrackingStart);
    final tracked = TrackedTimeCalculator.computeTrackedSummary(
      entries: entries,
      range: effectiveRange,
      travelEnabled: travelEnabled,
    );
    final effectivePaidLeaveMinutes = summarizeLeaveMinutes(
      absences.where((absence) => effectiveRange.contains(absence.date)),
    ).paidMinutes;

    final targetStart = effectiveRange.startInclusive;
    final targetEndInclusive =
        effectiveRange.endExclusive.subtract(const Duration(days: 1));

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
      paidLeaveMinutes: effectivePaidLeaveMinutes,
      targetMinutes: targetMinutes,
      startBalanceMinutes: startBalanceMinutes,
      manualAdjustmentMinutes: manualAdjustmentMinutes,
    );
  }
}
