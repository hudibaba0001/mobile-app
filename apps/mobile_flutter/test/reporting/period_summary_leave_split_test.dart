import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/reporting/period_summary.dart';

/// Regression test: leave must stay separate from tracked work so the UI
/// can show the correct heading ("Accounted" not "Worked") when leave > 0.
void main() {
  group('PeriodSummary leave-split correctness', () {
    test(
      'work=32h travel=1h55m creditedLeave=8h → '
      'tracked=33h55m, accounted=41h55m, diff uses accounted',
      () {
        const workMinutes = 32 * 60; // 1920
        const travelMinutes = (1 * 60) + 55; // 115
        const paidLeaveMinutes = 8 * 60; // 480
        const targetMinutes = 40 * 60; // 2400
        const startBalance = 0;
        const adjustments = 0;

        final summary = PeriodSummary.fromInputs(
          workMinutes: workMinutes,
          travelMinutes: travelMinutes,
          paidLeaveMinutes: paidLeaveMinutes,
          targetMinutes: targetMinutes,
          startBalanceMinutes: startBalance,
          manualAdjustmentMinutes: adjustments,
        );

        // Tracked = work + travel (no leave).
        expect(summary.trackedTotalMinutes, workMinutes + travelMinutes);
        expect(summary.trackedTotalMinutes, 2035); // 33 h 55 m

        // Accounted = tracked + credited leave.
        expect(summary.accountedMinutes,
            summary.trackedTotalMinutes + paidLeaveMinutes);
        expect(summary.accountedMinutes, 2515); // 41 h 55 m

        // Difference uses accounted, not just tracked.
        expect(summary.differenceMinutes,
            summary.accountedMinutes - targetMinutes);
        expect(summary.differenceMinutes, 115); // +1 h 55 m surplus

        // End balance propagates correctly.
        expect(summary.endBalanceMinutes,
            startBalance + adjustments + summary.differenceMinutes);
        expect(summary.endBalanceMinutes, 115);
      },
    );

    test('zero leave keeps accounted == tracked', () {
      final summary = PeriodSummary.fromInputs(
        workMinutes: 160 * 60,
        travelMinutes: 0,
        paidLeaveMinutes: 0,
        targetMinutes: 160 * 60,
        startBalanceMinutes: 0,
        manualAdjustmentMinutes: 0,
      );

      expect(summary.trackedTotalMinutes, summary.accountedMinutes);
      expect(summary.differenceMinutes, 0);
    });

    test('only leave counts as accounted when no work/travel logged', () {
      final summary = PeriodSummary.fromInputs(
        workMinutes: 0,
        travelMinutes: 0,
        paidLeaveMinutes: 8 * 60,
        targetMinutes: 8 * 60,
        startBalanceMinutes: 0,
        manualAdjustmentMinutes: 0,
      );

      expect(summary.trackedTotalMinutes, 0);
      expect(summary.accountedMinutes, 8 * 60);
      expect(summary.differenceMinutes, 0);
    });
  });
}
