import '../models/entry.dart';
import 'time_range.dart';
import 'tracked_time_summary.dart';

class TrackedTimeCalculator {
  static TrackedTimeSummary computeTrackedSummary({
    required List<Entry> entries,
    required TimeRange range,
    required bool travelEnabled,
  }) {
    var workMinutes = 0;
    var travelMinutes = 0;
    var entryCount = 0;

    for (final entry in entries) {
      if (!range.contains(entry.date)) {
        continue;
      }

      if (entry.type == EntryType.work) {
        workMinutes += entry.workDuration.inMinutes;
        entryCount += 1;
        continue;
      }

      if (entry.type == EntryType.travel && travelEnabled) {
        travelMinutes += entry.travelDuration.inMinutes;
        entryCount += 1;
      }
    }

    return TrackedTimeSummary(
      workMinutes: workMinutes,
      travelMinutes: travelMinutes,
      entryCount: entryCount,
    );
  }
}
