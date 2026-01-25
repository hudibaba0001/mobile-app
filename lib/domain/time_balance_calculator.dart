import '../models/entry.dart';

/// Summary of time balance for a single day
class DaySummary {
  final DateTime date;
  final int workedMinutes;
  final int travelMinutes;
  final int targetMinutes;
  final int varianceMinutes;

  DaySummary({
    required this.date,
    required this.workedMinutes,
    required this.travelMinutes,
    required this.targetMinutes,
    required this.varianceMinutes,
  });

  @override
  String toString() {
    return 'DaySummary(date: $date, worked: ${workedMinutes}m, travel: ${travelMinutes}m, target: ${targetMinutes}m, variance: ${varianceMinutes}m)';
  }
}

/// Pure calculator for time balance calculations
/// Groups entries by date and calculates daily summaries
class TimeBalanceCalculator {
  /// Calculate daily summaries from a list of entries
  /// 
  /// Groups entries by date and applies target ONCE per date.
  /// 
  /// [entries] List of entries (can be atomic or legacy)
  /// [targetForDate] Function that returns target minutes for a given date
  /// 
  /// Returns a list of DaySummary, one per unique date
  static List<DaySummary> calculateDailySummaries({
    required List<Entry> entries,
    required int Function(DateTime) targetForDate,
  }) {
    // Group entries by date (normalize to date-only for grouping)
    final Map<DateTime, List<Entry>> entriesByDate = {};
    
    for (final entry in entries) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      entriesByDate.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Calculate summary for each date
    final List<DaySummary> summaries = [];
    
    for (final entry in entriesByDate.entries) {
      final date = entry.key;
      final dayEntries = entry.value;
      
      // Aggregate worked minutes from all work entries for this date
      int totalWorkedMinutes = 0;
      for (final e in dayEntries) {
        if (e.type == EntryType.work && e.shifts != null) {
          for (final shift in e.shifts!) {
            totalWorkedMinutes += shift.workedMinutes;
          }
        }
      }
      
      // Aggregate travel minutes from all travel entries for this date
      int totalTravelMinutes = 0;
      for (final e in dayEntries) {
        if (e.type == EntryType.travel) {
          if (e.travelLegs != null && e.travelLegs!.isNotEmpty) {
            for (final leg in e.travelLegs!) {
              totalTravelMinutes += leg.minutes;
            }
          } else if (e.travelMinutes != null) {
            // Legacy single travel entry
            totalTravelMinutes += e.travelMinutes!;
          }
        }
      }
      
      // Get target for this date (applied ONCE per date, not per entry)
      final targetMinutes = targetForDate(date);
      
      // Variance = worked - target (travel is not included in variance)
      final varianceMinutes = totalWorkedMinutes - targetMinutes;
      
      summaries.add(DaySummary(
        date: date,
        workedMinutes: totalWorkedMinutes,
        travelMinutes: totalTravelMinutes,
        targetMinutes: targetMinutes,
        varianceMinutes: varianceMinutes,
      ));
    }
    
    // Sort by date
    summaries.sort((a, b) => a.date.compareTo(b.date));
    
    return summaries;
  }
}
