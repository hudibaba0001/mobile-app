class AccountedTimeSummary {
  final int trackedMinutes;
  final int leaveMinutes;
  final int accountedMinutes;
  final int targetMinutes;
  final int deltaMinutes;

  const AccountedTimeSummary({
    required this.trackedMinutes,
    required this.leaveMinutes,
    required this.accountedMinutes,
    required this.targetMinutes,
    required this.deltaMinutes,
  });
}
