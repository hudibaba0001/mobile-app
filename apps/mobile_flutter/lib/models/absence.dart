import 'package:flutter/foundation.dart';
import '../utils/date_parser.dart';

/// Type of absence entry
enum AbsenceType {
  vacationPaid,
  sickPaid,
  vabPaid,
  unpaid,
  unknown,
}

/// Model representing an absence entry
///
/// Represents paid or unpaid absences (vacation, sick leave, VAB, etc.)
/// Date is normalized to year/month/day only (no time component)
class AbsenceEntry {
  final String? id; // Optional ID for Supabase (null for new entries)
  final DateTime date; // date-only (normalized)
  final int minutes; // can be 0 meaning "full scheduled day"
  final AbsenceType type;
  final String? rawType; // Preserves backend value for unknown types

  const AbsenceEntry({
    this.id,
    required this.date,
    required this.minutes,
    required this.type,
    this.rawType,
  });

  /// Factory constructor that normalizes the date
  factory AbsenceEntry.normalized({
    required DateTime date,
    required int minutes,
    required AbsenceType type,
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    return AbsenceEntry(
      date: normalized,
      minutes: minutes,
      type: type,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'minutes': minutes,
      'type': type == AbsenceType.unknown && rawType != null ? rawType : type.name,
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }

  /// Create from map (from storage)
  factory AbsenceEntry.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;
    final date = DateParser.tryParseDateOnly(dateStr) ?? DateTime.now();

    final typeStr = map['type'] as String;
    AbsenceType type;
    switch (typeStr) {
      case 'vacationPaid':
        type = AbsenceType.vacationPaid;
        break;
      case 'sickPaid':
        type = AbsenceType.sickPaid;
        break;
      case 'vabPaid':
        type = AbsenceType.vabPaid;
        break;
      case 'unpaid':
        type = AbsenceType.unpaid;
        break;
      default:
        // Safely map unknown types without throwing, preserve raw value
        type = AbsenceType.unknown;
        debugPrint('AbsenceEntry: Safely mapped unknown absence type: $typeStr');
        break;
    }

    return AbsenceEntry(
      id: map['id'] as String?,
      date: date,
      minutes: map['minutes'] as int,
      type: type,
      rawType: type == AbsenceType.unknown ? typeStr : null,
    );
  }

  /// Check if this is a paid absence
  bool get isPaid => type != AbsenceType.unpaid && type != AbsenceType.unknown;

  @override
  String toString() {
    return 'AbsenceEntry(${date.year}-${date.month}-${date.day}, ${minutes}min, ${type.name})';
  }
}
