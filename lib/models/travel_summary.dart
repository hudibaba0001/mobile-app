class TravelSummary {
  final int totalEntries;
  final int totalMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> locationFrequency;
  final double averageMinutesPerTrip;
  final String mostFrequentRoute;
  final int totalHours;

  TravelSummary({
    required this.totalEntries,
    required this.totalMinutes,
    required this.startDate,
    required this.endDate,
    required this.locationFrequency,
  }) : averageMinutesPerTrip = totalEntries > 0 ? totalMinutes / totalEntries : 0,
       mostFrequentRoute = _getMostFrequentRoute(locationFrequency),
       totalHours = (totalMinutes / 60).round();

  static String _getMostFrequentRoute(Map<String, int> locationFrequency) {
    if (locationFrequency.isEmpty) return 'No routes';
    
    var sortedEntries = locationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.first.key;
  }

  String get formattedDuration {
    if (totalHours > 0) {
      final remainingMinutes = totalMinutes % 60;
      return '${totalHours}h ${remainingMinutes}m';
    }
    return '${totalMinutes}m';
  }

  @override
  String toString() {
    return 'TravelSummary(entries: $totalEntries, duration: $formattedDuration, period: ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]})';
  }
}