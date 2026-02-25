import '../calendar/sweden_holidays.dart';
import '../services/holiday_service.dart';
import 'target_hours_calculator.dart';

final SwedenHolidayCalendar _defaultHolidayCalendar = SwedenHolidayCalendar();

/// Shared resolver for daily scheduled/planned minutes.
///
/// This mirrors TimeProvider's scheduling behavior:
/// - Use HolidayService red-day info (including personal half-days) when available.
/// - Otherwise use TargetHoursCalculator with SwedenHolidayCalendar.
int scheduledMinutesForDate({
  required DateTime date,
  required int weeklyTargetMinutes,
  required double contractPercent,
  HolidayService? holidayService,
}) {
  assert(!contractPercent.isNaN);

  if (holidayService != null) {
    final redDayInfo = holidayService.getRedDayInfo(date);
    if (redDayInfo.isRedDay) {
      return TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
        date: date,
        weeklyTargetMinutes: weeklyTargetMinutes,
        isFullRedDay: redDayInfo.isFullDay,
        isHalfRedDay: redDayInfo.halfDay != null,
      );
    }
  }

  return TargetHoursCalculator.scheduledMinutesForDate(
    date: date,
    weeklyTargetMinutes: weeklyTargetMinutes,
    holidays: _defaultHolidayCalendar,
  );
}
