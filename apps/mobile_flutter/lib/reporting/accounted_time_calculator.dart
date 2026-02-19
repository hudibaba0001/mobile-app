import 'accounted_time_summary.dart';

class AccountedTimeCalculator {
  static AccountedTimeSummary compute({
    required int trackedMinutes,
    required int leaveMinutes,
    required int targetMinutes,
  }) {
    final accountedMinutes = trackedMinutes + leaveMinutes;
    return AccountedTimeSummary(
      trackedMinutes: trackedMinutes,
      leaveMinutes: leaveMinutes,
      accountedMinutes: accountedMinutes,
      targetMinutes: targetMinutes,
      deltaMinutes: accountedMinutes - targetMinutes,
    );
  }
}
