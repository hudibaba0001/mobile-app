/// Safe date parser replacing fragile string split operations.
class DateParser {
  /// Attempts to parse a date-only string (e.g. "YYYY-MM-DD") securely.
  /// Returns null if the string is empty, null, or improperly formatted.
  static DateTime? tryParseDateOnly(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) return null;

    final parts = dateString.split('-');
    if (parts.length < 3) return null; // Needs at least 3 parts for Year, Month, Day

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      // In case DateTime throws for very weird ranges, though uncommon in dart
      return null;
    }
  }
}
