import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/accounted_time_calculator.dart';
import 'package:myapp/reporting/time_range.dart';
import 'package:myapp/reporting/tracked_time_calculator.dart';

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
  required int travelMinutes,
}) {
  return Entry.makeTravelAtomicFromLeg(
    id: id,
    userId: 'user-1',
    date: date,
    from: 'A',
    to: 'B',
    minutes: travelMinutes,
  );
}

void main() {
  group('AccountedTimeCalculator', () {
    test('target 120h, tracked 112h, leave 8h gives delta 0', () {
      final summary = AccountedTimeCalculator.compute(
        trackedMinutes: 112 * 60,
        leaveMinutes: 8 * 60,
        targetMinutes: 120 * 60,
      );

      expect(summary.trackedMinutes, 112 * 60);
      expect(summary.leaveMinutes, 8 * 60);
      expect(summary.accountedMinutes, 120 * 60);
      expect(summary.deltaMinutes, 0);
    });

    test('leave minutes do not change tracked totals', () {
      final range =
          TimeRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 1));
      final tracked = TrackedTimeCalculator.computeTrackedSummary(
        entries: [
          _workEntry(
            id: 'w-1',
            date: DateTime(2026, 2, 1),
            workedMinutes: 112 * 60,
          ),
        ],
        range: range,
        travelEnabled: true,
      );

      final accounted = AccountedTimeCalculator.compute(
        trackedMinutes: tracked.totalMinutes,
        leaveMinutes: 8 * 60,
        targetMinutes: 120 * 60,
      );

      expect(tracked.totalMinutes, 112 * 60);
      expect(accounted.trackedMinutes, tracked.totalMinutes);
      expect(accounted.accountedMinutes, 120 * 60);
    });

    test('travel disabled keeps travel at 0 but leave still counts', () {
      final range =
          TimeRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 1));
      final tracked = TrackedTimeCalculator.computeTrackedSummary(
        entries: [
          _workEntry(
            id: 'w-1',
            date: DateTime(2026, 2, 1),
            workedMinutes: 112 * 60,
          ),
          _travelEntry(
            id: 't-1',
            date: DateTime(2026, 2, 1),
            travelMinutes: 30,
          ),
        ],
        range: range,
        travelEnabled: false,
      );

      final accounted = AccountedTimeCalculator.compute(
        trackedMinutes: tracked.totalMinutes,
        leaveMinutes: 8 * 60,
        targetMinutes: 120 * 60,
      );

      expect(tracked.workMinutes, 112 * 60);
      expect(tracked.travelMinutes, 0);
      expect(tracked.totalMinutes, 112 * 60);
      expect(accounted.leaveMinutes, 8 * 60);
      expect(accounted.accountedMinutes, 120 * 60);
      expect(accounted.deltaMinutes, 0);
    });
  });
}
