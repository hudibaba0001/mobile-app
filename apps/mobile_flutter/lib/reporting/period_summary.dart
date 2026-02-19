class PeriodSummary {
  final int workMinutes;
  final int travelMinutes;
  final int trackedTotalMinutes;
  final int paidLeaveMinutes;
  final int accountedMinutes;
  final int targetMinutes;
  final int differenceMinutes;
  final int startBalanceMinutes;
  final int manualAdjustmentMinutes;
  final int endBalanceMinutes;

  const PeriodSummary({
    required this.workMinutes,
    required this.travelMinutes,
    required this.trackedTotalMinutes,
    required this.paidLeaveMinutes,
    required this.accountedMinutes,
    required this.targetMinutes,
    required this.differenceMinutes,
    required this.startBalanceMinutes,
    required this.manualAdjustmentMinutes,
    required this.endBalanceMinutes,
  });

  factory PeriodSummary.fromInputs({
    required int workMinutes,
    required int travelMinutes,
    required int paidLeaveMinutes,
    required int targetMinutes,
    required int startBalanceMinutes,
    required int manualAdjustmentMinutes,
  }) {
    final trackedTotalMinutes = workMinutes + travelMinutes;
    final accountedMinutes = trackedTotalMinutes + paidLeaveMinutes;
    final differenceMinutes = accountedMinutes - targetMinutes;
    final endBalanceMinutes =
        startBalanceMinutes + manualAdjustmentMinutes + differenceMinutes;

    return PeriodSummary(
      workMinutes: workMinutes,
      travelMinutes: travelMinutes,
      trackedTotalMinutes: trackedTotalMinutes,
      paidLeaveMinutes: paidLeaveMinutes,
      accountedMinutes: accountedMinutes,
      targetMinutes: targetMinutes,
      differenceMinutes: differenceMinutes,
      startBalanceMinutes: startBalanceMinutes,
      manualAdjustmentMinutes: manualAdjustmentMinutes,
      endBalanceMinutes: endBalanceMinutes,
    );
  }
}
