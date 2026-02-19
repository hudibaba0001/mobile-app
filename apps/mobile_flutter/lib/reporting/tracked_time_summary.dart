class TrackedTimeSummary {
  final int workMinutes;
  final int travelMinutes;
  final int totalMinutes;
  final int entryCount;

  const TrackedTimeSummary({
    required this.workMinutes,
    required this.travelMinutes,
    required this.entryCount,
  }) : totalMinutes = workMinutes + travelMinutes;

  static const zero = TrackedTimeSummary(
    workMinutes: 0,
    travelMinutes: 0,
    entryCount: 0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackedTimeSummary &&
        other.workMinutes == workMinutes &&
        other.travelMinutes == travelMinutes &&
        other.totalMinutes == totalMinutes &&
        other.entryCount == entryCount;
  }

  @override
  int get hashCode =>
      workMinutes.hashCode ^
      travelMinutes.hashCode ^
      totalMinutes.hashCode ^
      entryCount.hashCode;
}
