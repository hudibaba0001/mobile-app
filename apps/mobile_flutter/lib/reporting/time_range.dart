/// Inclusive day range represented as [startInclusive, endExclusive).
///
/// All helpers normalize to date-only boundaries.
class TimeRange {
  final DateTime startInclusive;
  final DateTime endExclusive;

  const TimeRange._({
    required this.startInclusive,
    required this.endExclusive,
  });

  factory TimeRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final start = _dateOnly(startInclusive);
    final end = _dateOnly(endExclusive);
    if (end.isBefore(start)) {
      throw ArgumentError.value(
        endExclusive,
        'endExclusive',
        'endExclusive must be on or after startInclusive.',
      );
    }
    return TimeRange._(
      startInclusive: start,
      endExclusive: end,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Creates a range from inclusive day bounds.
  static TimeRange custom(DateTime fromInclusive, DateTime toInclusive) {
    final start = _dateOnly(fromInclusive);
    final endInclusive = _dateOnly(toInclusive);
    if (endInclusive.isBefore(start)) {
      throw ArgumentError.value(
        toInclusive,
        'toInclusive',
        'toInclusive must be on or after fromInclusive.',
      );
    }
    return TimeRange._(
      startInclusive: start,
      endExclusive: endInclusive.add(const Duration(days: 1)),
    );
  }

  /// Empty range anchored at [point].
  static TimeRange empty(DateTime point) {
    final day = _dateOnly(point);
    return TimeRange._(startInclusive: day, endExclusive: day);
  }

  static TimeRange today({DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    return custom(current, current);
  }

  static TimeRange thisWeek({DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    final daysSinceMonday = current.weekday - DateTime.monday;
    final weekStart = current.subtract(Duration(days: daysSinceMonday));
    return custom(weekStart, current);
  }

  static TimeRange thisMonth({DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    final monthStart = DateTime(current.year, current.month, 1);
    return custom(monthStart, current);
  }

  static TimeRange thisYear({DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    final yearStart = DateTime(current.year, 1, 1);
    return custom(yearStart, current);
  }

  static TimeRange last7Days({DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    final start = current.subtract(const Duration(days: 6));
    return custom(start, current);
  }

  bool contains(DateTime value) {
    return !value.isBefore(startInclusive) && value.isBefore(endExclusive);
  }

  /// Returns a range with start clipped to [minimumStartInclusive].
  ///
  /// If the clipped start is on/after `endExclusive`, returns an empty range
  /// anchored at the clipped start day.
  TimeRange clipStart(DateTime minimumStartInclusive) {
    final minStart = _dateOnly(minimumStartInclusive);
    final clippedStart =
        startInclusive.isBefore(minStart) ? minStart : startInclusive;
    if (!endExclusive.isAfter(clippedStart)) {
      return TimeRange.empty(clippedStart);
    }
    return TimeRange(
      startInclusive: clippedStart,
      endExclusive: endExclusive,
    );
  }
}
