import '../models/absence.dart';

const int kDefaultFullLeaveDayMinutes = 480;

int normalizedLeaveMinutes(
  AbsenceEntry absence, {
  int fullDayMinutes = kDefaultFullLeaveDayMinutes,
}) {
  return absence.minutes == 0 ? fullDayMinutes : absence.minutes;
}

class LeaveMinutesSummary {
  final int paidMinutes;
  final int unpaidMinutes;

  const LeaveMinutesSummary({
    required this.paidMinutes,
    required this.unpaidMinutes,
  });

  int get totalMinutes => paidMinutes + unpaidMinutes;
}

LeaveMinutesSummary summarizeLeaveMinutes(
  Iterable<AbsenceEntry> absences, {
  int fullDayMinutes = kDefaultFullLeaveDayMinutes,
}) {
  var paidMinutes = 0;
  var unpaidMinutes = 0;

  for (final absence in absences) {
    final minutes =
        normalizedLeaveMinutes(absence, fullDayMinutes: fullDayMinutes);
    if (absence.isPaid) {
      paidMinutes += minutes;
    } else {
      unpaidMinutes += minutes;
    }
  }

  return LeaveMinutesSummary(
    paidMinutes: paidMinutes,
    unpaidMinutes: unpaidMinutes,
  );
}
