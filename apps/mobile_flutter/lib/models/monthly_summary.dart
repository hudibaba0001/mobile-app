/// Model representing monthly work hours summary
class MonthlySummary {
  final int year;
  final int month; // 1-12 (January = 1, December = 12)
  final double actualWorkedHours;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.actualWorkedHours,
  });

  /// Get month name (e.g., "January", "February")
  String get monthName {
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

  /// Get short month name (e.g., "Jan", "Feb")
  String get monthNameShort {
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
    return 'MonthlySummary($monthName $year: ${actualWorkedHours}h)';
  }
}
