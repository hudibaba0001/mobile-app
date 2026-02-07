/// Model representing weekly work hours summary
class WeeklySummary {
  final int year;
  final int weekNumber; // ISO week number (1-53)
  final DateTime weekStart; // First day of the week (Monday)
  final double actualWorkedHours;

  WeeklySummary({
    required this.year,
    required this.weekNumber,
    required this.weekStart,
    required this.actualWorkedHours,
  });

  /// Get week range as string (e.g., "Jan 1 - Jan 7")
  String get weekRange {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startMonth = _getMonthName(weekStart.month);
    final endMonth = _getMonthName(weekEnd.month);

    if (weekStart.month == weekEnd.month) {
      return '$startMonth ${weekStart.day} - ${weekEnd.day}';
    } else {
      return '$startMonth ${weekStart.day} - $endMonth ${weekEnd.day}';
    }
  }

  /// Get short week range (e.g., "Jan 1-7")
  String get weekRangeShort {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startMonth = _getMonthNameShort(weekStart.month);
    final endMonth = _getMonthNameShort(weekEnd.month);

    if (weekStart.month == weekEnd.month) {
      return '$startMonth ${weekStart.day}-${weekEnd.day}';
    } else {
      return '$startMonth ${weekStart.day} - $endMonth ${weekEnd.day}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getMonthNameShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  String toString() {
    return 'WeeklySummary(Week $weekNumber, $year: ${actualWorkedHours}h)';
  }
}
