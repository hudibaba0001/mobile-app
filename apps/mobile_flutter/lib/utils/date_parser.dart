import 'package:flutter/foundation.dart';

/// Safe date parser replacing fragile string split operations.
class DateParser {
  // Matches yyyy-mm-dd format strictly
  static final RegExp _dateRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Attempts to parse a date-only string (e.g. "YYYY-MM-DD") securely.
  /// Returns null if the string is empty, null, or has an invalid calendar date
  /// (such as "2024-02-30" or "2024-13-01").
  static DateTime? tryParseDateOnly(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) return null;

    final match = _dateRegex.firstMatch(dateString.trim());
    if (match == null) {
      debugPrint(
          'DateParser: Format error on "$dateString": must be YYYY-MM-DD');
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    // Initial fast bounds check
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      debugPrint(
          'DateParser: Out of bounds error on "$dateString": month=$month, day=$day');
      return null;
    }

    // Round-trip verification to catch invalid leap years or days like 02-30
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) {
      debugPrint(
          'DateParser: Round-trip calendar error on "$dateString". Normalized to ${dt.toIso8601String()}');
      return null;
    }

    return dt;
  }
}
