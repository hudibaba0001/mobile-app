import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/time_format.dart';
import 'package:myapp/reporting/time_range.dart';
import 'package:myapp/reporting/tracked_time_calculator.dart';
import 'package:myapp/reporting/tracked_time_summary.dart';

Entry _workEntry({
  required String id,
  required DateTime date,
  required int workedMinutes,
}) {
  final shiftStart = DateTime(date.year, date.month, date.day, 9, 0);
  final shiftEnd = shiftStart.add(Duration(minutes: workedMinutes));
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.work,
    date: date,
    shifts: [
      Shift(
        start: shiftStart,
        end: shiftEnd,
      ),
    ],
    createdAt: DateTime(2026, 1, 1),
  );
}

Entry _travelEntry({
  required String id,
  required DateTime date,
  required int travelMinutes,
}) {
  return Entry(
    id: id,
    userId: 'user-1',
    type: EntryType.travel,
    date: date,
    from: 'A',
    to: 'B',
    travelMinutes: travelMinutes,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('TrackedTimeCalculator', () {
    test('range boundaries are inclusive for start and exclusive for end', () {
      final entries = [
        _workEntry(
          id: 'start',
          date: DateTime(2026, 2, 1, 0, 0),
          workedMinutes: 60,
        ),
        _workEntry(
          id: 'inside',
          date: DateTime(2026, 2, 2, 23, 59),
          workedMinutes: 120,
        ),
        _workEntry(
          id: 'outside',
          date: DateTime(2026, 2, 3, 0, 0),
          workedMinutes: 240,
        ),
      ];

      final range = TimeRange.custom(
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 2),
      );

      final summary = TrackedTimeCalculator.computeTrackedSummary(
        entries: entries,
        range: range,
        travelEnabled: true,
      );

      expect(
        summary,
        const TrackedTimeSummary(
          workMinutes: 180,
          travelMinutes: 0,
          entryCount: 2,
        ),
      );
    });

    test('work and travel minutes sum correctly', () {
      final entries = [
        _workEntry(
          id: 'work-1',
          date: DateTime(2026, 2, 10, 9, 0),
          workedMinutes: 450,
        ),
        _travelEntry(
          id: 'travel-1',
          date: DateTime(2026, 2, 10, 18, 0),
          travelMinutes: 35,
        ),
        _workEntry(
          id: 'work-2',
          date: DateTime(2026, 2, 11, 9, 0),
          workedMinutes: 420,
        ),
      ];

      final range = TimeRange.custom(
        DateTime(2026, 2, 10),
        DateTime(2026, 2, 11),
      );

      final summary = TrackedTimeCalculator.computeTrackedSummary(
        entries: entries,
        range: range,
        travelEnabled: true,
      );

      expect(summary.workMinutes, 870);
      expect(summary.travelMinutes, 35);
      expect(summary.totalMinutes, 905);
      expect(summary.entryCount, 3);
    });

    test('travel minutes are zero when travel is disabled', () {
      final entries = [
        _workEntry(
          id: 'work',
          date: DateTime(2026, 2, 10, 9, 0),
          workedMinutes: 480,
        ),
        _travelEntry(
          id: 'travel',
          date: DateTime(2026, 2, 10, 18, 0),
          travelMinutes: 45,
        ),
      ];

      final range = TimeRange.custom(
        DateTime(2026, 2, 10),
        DateTime(2026, 2, 10),
      );

      final summary = TrackedTimeCalculator.computeTrackedSummary(
        entries: entries,
        range: range,
        travelEnabled: false,
      );

      expect(summary.workMinutes, 480);
      expect(summary.travelMinutes, 0);
      expect(summary.totalMinutes, 480);
      expect(summary.entryCount, 1);
    });
  });

  group('formatMinutes', () {
    test('formats English hours and minutes', () {
      expect(formatMinutes(7035), '117h 15m');
      expect(formatMinutes(0), '0h 0m');
      expect(formatMinutes(-75, signed: true), '-1h 15m');
    });

    test('formats Swedish hours and minutes', () {
      expect(formatMinutes(7035, localeCode: 'sv'), '117 h 15 min');
      expect(formatMinutes(0, localeCode: 'sv'), '0 h 0 min');
      expect(
        formatMinutes(0, localeCode: 'sv', signed: true, showPlusForZero: true),
        '+0 h 0 min',
      );
    });
  });
}
