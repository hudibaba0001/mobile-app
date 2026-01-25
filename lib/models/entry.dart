import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'entry.g.dart';

/// Travel leg model for multiple travel segments per day
@HiveType(typeId: 8)
class TravelLeg extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fromText;

  @HiveField(2)
  final String toText;

  @HiveField(3)
  final String? fromPlaceId;

  @HiveField(4)
  final String? toPlaceId;

  @HiveField(5)
  final int minutes;

  @HiveField(6)
  final String source; // "manual" | "auto"

  @HiveField(7)
  final double? distanceKm;

  @HiveField(8)
  final DateTime? calculatedAt;

  TravelLeg({
    String? id,
    required this.fromText,
    required this.toText,
    this.fromPlaceId,
    this.toPlaceId,
    required this.minutes,
    this.source = 'manual',
    this.distanceKm,
    this.calculatedAt,
  }) : id = id ?? const Uuid().v4();

  /// Convert to map for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_text': fromText,
      'to_text': toText,
      'from_place_id': fromPlaceId,
      'to_place_id': toPlaceId,
      'minutes': minutes,
      'source': source,
      'distance_km': distanceKm,
      'calculated_at': calculatedAt?.toIso8601String(),
    };
  }

  /// Create from Supabase map
  factory TravelLeg.fromJson(Map<String, dynamic> data) {
    return TravelLeg(
      id: data['id'] as String? ?? const Uuid().v4(),
      fromText:
          data['from_text'] as String? ?? data['fromText'] as String? ?? '',
      toText: data['to_text'] as String? ?? data['toText'] as String? ?? '',
      fromPlaceId:
          data['from_place_id'] as String? ?? data['fromPlaceId'] as String?,
      toPlaceId: data['to_place_id'] as String? ?? data['toPlaceId'] as String?,
      minutes: data['minutes'] as int? ?? 0,
      source: data['source'] as String? ?? 'manual',
      distanceKm:
          data['distance_km'] as double? ?? data['distanceKm'] as double?,
      calculatedAt: data['calculated_at'] != null
          ? DateTime.parse(data['calculated_at'] as String)
          : data['calculatedAt'] != null
              ? DateTime.parse(data['calculatedAt'] as String)
              : null,
    );
  }

  TravelLeg copyWith({
    String? id,
    String? fromText,
    String? toText,
    String? fromPlaceId,
    String? toPlaceId,
    int? minutes,
    String? source,
    double? distanceKm,
    DateTime? calculatedAt,
  }) {
    return TravelLeg(
      id: id ?? this.id,
      fromText: fromText ?? this.fromText,
      toText: toText ?? this.toText,
      fromPlaceId: fromPlaceId ?? this.fromPlaceId,
      toPlaceId: toPlaceId ?? this.toPlaceId,
      minutes: minutes ?? this.minutes,
      source: source ?? this.source,
      distanceKm: distanceKm ?? this.distanceKm,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  String toString() {
    return 'TravelLeg(id: $id, from: $fromText, to: $toText, minutes: $minutes, source: $source)';
  }
}

/// Entry type enumeration for different kinds of entries
@HiveType(typeId: 6)
enum EntryType {
  @HiveField(0)
  travel,
  @HiveField(1)
  work,
}

/// Shift model for work entries
@HiveType(typeId: 7)
class Shift extends HiveObject {
  // Static values for enum-like behavior
  static const List<String> values = [
    'morning',
    'afternoon',
    'evening',
    'night'
  ];
  @HiveField(0)
  final DateTime start;

  @HiveField(1)
  final DateTime end;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? location;

  @HiveField(4)
  final int unpaidBreakMinutes;

  @HiveField(5)
  final String? notes;

  Shift({
    required this.start,
    required this.end,
    this.description,
    this.location,
    this.unpaidBreakMinutes = 0,
    this.notes,
  });

  /// Duration of this shift (span from start to end)
  Duration get duration => end.difference(start);

  /// Worked minutes (duration minus unpaid break)
  int get workedMinutes {
    final spanMinutes = duration.inMinutes;
    final breakMinutes = unpaidBreakMinutes;
    final worked = spanMinutes - breakMinutes;
    return worked > 0 ? worked : 0; // Never negative
  }

  /// Worked duration (as Duration object)
  Duration get workedDuration => Duration(minutes: workedMinutes);

  /// Convert to map for Supabase
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'description': description,
      'location': location,
      'unpaid_break_minutes': unpaidBreakMinutes,
      'notes': notes,
    };
  }

  /// Create from Supabase map
  factory Shift.fromJson(Map<String, dynamic> data) {
    return Shift(
      start: DateTime.parse(data['start']),
      end: DateTime.parse(data['end']),
      description: data['description'],
      location: data['location'],
      // Backward compatible: default to 0 if missing
      unpaidBreakMinutes: data['unpaid_break_minutes'] as int? ??
          data['unpaidBreakMinutes'] as int? ??
          0,
      notes: data['notes'] as String?,
    );
  }

  Shift copyWith({
    DateTime? start,
    DateTime? end,
    String? description,
    String? location,
    int? unpaidBreakMinutes,
    String? notes,
  }) {
    return Shift(
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      location: location ?? this.location,
      unpaidBreakMinutes: unpaidBreakMinutes ?? this.unpaidBreakMinutes,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Shift(start: $start, end: $end, duration: ${duration.inMinutes}m)';
  }
}

/// Unified Entry model for both travel and work entries
/// Supports Hive local storage and Supabase cloud sync
@HiveType(typeId: 5)
class Entry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final EntryType type;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? from;

  @HiveField(5)
  final String? to;

  @HiveField(6)
  final int? travelMinutes;

  @HiveField(7)
  final List<Shift>? shifts;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? updatedAt;

  @HiveField(11)
  final String? journeyId;

  @HiveField(12)
  final int? segmentOrder;

  @HiveField(13)
  final int? totalSegments;

  /// Whether this entry is work done on a public holiday (red day)
  /// Auto-set when saving an entry on a holiday date with hours > 0
  @HiveField(14)
  final bool isHolidayWork;

  /// Holiday name if this is holiday work (for display/export)
  @HiveField(15)
  final String? holidayName;

  @HiveField(16)
  final List<TravelLeg>? travelLegs;

  Entry({
    String? id,
    required this.userId,
    required this.type,
    required this.date,
    this.from,
    this.to,
    this.travelMinutes,
    this.shifts,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.journeyId,
    this.segmentOrder,
    this.totalSegments,
    this.isHolidayWork = false,
    this.holidayName,
    this.travelLegs,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert to map for Supabase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_holiday_work': isHolidayWork,
    };

    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toIso8601String();
    }

    if (holidayName != null) {
      data['holiday_name'] = holidayName;
    }

    // Add type-specific fields
    if (type == EntryType.travel) {
      // Support both legacy single travel and new travelLegs
      if (travelLegs != null && travelLegs!.isNotEmpty) {
        data['travel_legs'] = travelLegs!.map((leg) => leg.toJson()).toList();
        // Also store total for backward compatibility
        final totalMinutes =
            travelLegs!.fold<int>(0, (sum, leg) => sum + leg.minutes);
        data['travel_minutes'] = totalMinutes;
      } else {
        // Legacy single travel fields
        if (from != null) data['from_location'] = from;
        if (to != null) data['to_location'] = to;
        if (travelMinutes != null) data['travel_minutes'] = travelMinutes;
      }
      if (journeyId != null) data['journey_id'] = journeyId;
      if (segmentOrder != null) data['segment_order'] = segmentOrder;
      if (totalSegments != null) data['total_segments'] = totalSegments;
    } else if (type == EntryType.work && shifts != null) {
      data['shifts'] = shifts!.map((s) => s.toJson()).toList();
    }

    return data;
  }

  /// Create from Supabase map
  factory Entry.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = EntryType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => EntryType.travel,
    );

    final entry = Entry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: type,
      date: DateTime.parse(json['date'] as String),
      from: json['from_location'] as String?,
      to: json['to_location'] as String?,
      travelMinutes: json['travel_minutes'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      journeyId: json['journey_id'] as String?,
      segmentOrder: json['segment_order'] as int?,
      totalSegments: json['total_segments'] as int?,
      isHolidayWork: json['is_holiday_work'] as bool? ?? false,
      holidayName: json['holiday_name'] as String?,
    );

    // Parse shifts for work entries
    if (type == EntryType.work && json['shifts'] != null) {
      final shiftsList = json['shifts'] as List;
      final shifts = shiftsList
          .map((s) => Shift.fromJson(s as Map<String, dynamic>))
          .toList();
      return entry.copyWith(shifts: shifts);
    }

    // Parse travel legs for travel entries
    if (type == EntryType.travel && json['travel_legs'] != null) {
      final legsList = json['travel_legs'] as List;
      final travelLegs = legsList
          .map((leg) => TravelLeg.fromJson(leg as Map<String, dynamic>))
          .toList();
      return entry.copyWith(travelLegs: travelLegs);
    } else if (type == EntryType.travel &&
        entry.from != null &&
        entry.to != null &&
        entry.travelMinutes != null) {
      // Backward compatibility: convert legacy single travel to travelLegs
      final leg = TravelLeg(
        fromText: entry.from!,
        toText: entry.to!,
        minutes: entry.travelMinutes!,
        source: 'manual',
      );
      return entry.copyWith(travelLegs: [leg]);
    }

    return entry;
  }

  /// Create a copy with updated fields
  Entry copyWith({
    String? id,
    String? userId,
    EntryType? type,
    DateTime? date,
    String? from,
    String? to,
    int? travelMinutes,
    List<Shift>? shifts,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? journeyId,
    int? segmentOrder,
    int? totalSegments,
    bool? isHolidayWork,
    String? holidayName,
    List<TravelLeg>? travelLegs,
  }) {
    return Entry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      date: date ?? this.date,
      from: from ?? this.from,
      to: to ?? this.to,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      shifts: shifts ?? this.shifts,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      journeyId: journeyId ?? this.journeyId,
      segmentOrder: segmentOrder ?? this.segmentOrder,
      totalSegments: totalSegments ?? this.totalSegments,
      isHolidayWork: isHolidayWork ?? this.isHolidayWork,
      holidayName: holidayName ?? this.holidayName,
      travelLegs: travelLegs ?? this.travelLegs,
    );
  }

  /// Get total duration for work entries (worked minutes, excluding unpaid breaks)
  Duration? get totalWorkDuration {
    if (type != EntryType.work || shifts == null || shifts!.isEmpty) {
      return null;
    }

    var totalWorkedMinutes = 0;
    for (final shift in shifts!) {
      totalWorkedMinutes += shift.workedMinutes;
    }

    return Duration(minutes: totalWorkedMinutes);
  }

  /// Get total duration for any entry type
  Duration get totalDuration {
    if (type == EntryType.work) {
      return totalWorkDuration ?? Duration.zero;
    } else if (type == EntryType.travel) {
      // Use travelLegs if available, otherwise fall back to legacy travelMinutes
      if (travelLegs != null && travelLegs!.isNotEmpty) {
        final totalMinutes =
            travelLegs!.fold<int>(0, (sum, leg) => sum + leg.minutes);
        return Duration(minutes: totalMinutes);
      }
      return Duration(minutes: travelMinutes ?? 0);
    }
    return Duration.zero;
  }

  /// Get work duration
  Duration get workDuration => totalWorkDuration ?? Duration.zero;

  /// Check if entry is a valid travel entry
  bool get isValidTravel {
    if (type != EntryType.travel) return false;
    return from != null &&
        from!.isNotEmpty &&
        to != null &&
        to!.isNotEmpty &&
        (travelMinutes != null && travelMinutes! > 0);
  }

  /// Get travel duration
  Duration get travelDuration {
    if (travelLegs != null && travelLegs!.isNotEmpty) {
      final totalMinutes =
          travelLegs!.fold<int>(0, (sum, leg) => sum + leg.minutes);
      return Duration(minutes: totalMinutes);
    }
    return Duration(minutes: travelMinutes ?? 0);
  }

  /// Get total hours for work entries
  double? get totalWorkHours {
    final duration = totalWorkDuration;
    if (duration == null) return null;
    return duration.inMinutes / 60.0;
  }

  /// Get travel duration in minutes
  int? get travelDurationMinutes {
    if (type != EntryType.travel) return null;
    return travelMinutes;
  }

  /// Get travel duration in hours
  double? get travelDurationHours {
    final minutes = travelDurationMinutes;
    if (minutes == null) return null;
    return minutes / 60.0;
  }

  /// Get work hours
  double get workHours => totalWorkHours ?? 0.0;

  /// Get formatted duration string
  String get formattedDuration {
    final duration = totalDuration;
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }

  /// Get the first shift for work entries
  Shift? get shift {
    if (type == EntryType.work && shifts != null && shifts!.isNotEmpty) {
      return shifts!.first;
    }
    return null;
  }

  /// Get work location from first shift
  String? get workLocation => shift?.location;

  /// Get departure location for travel entries
  String? get departureLocation => type == EntryType.travel ? from : null;

  /// Get arrival location for travel entries
  String? get arrivalLocation => type == EntryType.travel ? to : null;

  /// Get minutes for travel entries
  int? get minutes => type == EntryType.travel ? travelMinutes : null;

  /// Get description (alias for notes)
  String? get description => notes;

  /// Check if this is an atomic work entry (exactly 1 shift)
  /// New entries should be atomic (1 shift = 1 Entry)
  bool get isAtomicWork =>
      type == EntryType.work && shifts != null && shifts!.length == 1;

  /// Get the single shift for atomic work entries
  /// Returns null if not atomic work
  Shift? get atomicShift => isAtomicWork ? shifts!.first : null;

  /// Check if this is a legacy multi-shift entry (work with >1 shift)
  /// Legacy entries may have multiple shifts in one Entry
  bool get isLegacyMultiShift =>
      type == EntryType.work && shifts != null && shifts!.length > 1;

  /// Check if this is an atomic travel entry (single leg)
  /// New entries should be atomic (1 leg = 1 Entry)
  bool get isAtomicTravel {
    if (type != EntryType.travel) return false;
    // Atomic if it has single from/to/minutes (legacy) or single travelLeg
    if (travelLegs != null && travelLegs!.isNotEmpty) {
      return travelLegs!.length == 1;
    }
    // Legacy single travel entry is atomic
    return from != null && to != null && travelMinutes != null;
  }

  /// Create an atomic work entry from a single shift
  /// This is the canonical way to create new work entries (1 shift = 1 Entry)
  factory Entry.makeWorkAtomicFromShift({
    required String userId,
    required DateTime date,
    required Shift shift,
    String? dayNotes,
    String? id,
    DateTime? createdAt,
  }) {
    final entry = Entry(
      id: id,
      userId: userId,
      type: EntryType.work,
      date: date,
      shifts: [shift], // Exactly 1 shift for atomic entry
      notes: dayNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
    assert(entry.shifts!.length == 1,
        'Work entries created via makeWorkAtomicFromShift must have exactly one shift.');
    return entry;
  }

  /// Create an atomic travel entry from a single leg
  /// This is the canonical way to create new travel entries (1 leg = 1 Entry)
  factory Entry.makeTravelAtomicFromLeg({
    required String userId,
    required DateTime date,
    required String from,
    required String to,
    required int minutes,
    String? dayNotes,
    String? fromPlaceId,
    String? toPlaceId,
    String? source,
    double? distanceKm,
    DateTime? calculatedAt,
    String? id,
    DateTime? createdAt,
    int? segmentOrder,
    int? totalSegments,
  }) {
    final entry = Entry(
      id: id,
      userId: userId,
      type: EntryType.travel,
      date: date,
      from: from,
      to: to,
      travelMinutes: minutes,
      notes: dayNotes,
      segmentOrder: segmentOrder,
      totalSegments: totalSegments,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      // Optionally store as travelLegs for consistency
      travelLegs: [
        TravelLeg(
          id: id,
          fromText: from,
          toText: to,
          fromPlaceId: fromPlaceId,
          toPlaceId: toPlaceId,
          minutes: minutes,
          source: source ?? 'manual',
          distanceKm: distanceKm,
          calculatedAt: calculatedAt,
        ),
      ],
    );
    assert(entry.travelLegs!.length == 1,
        'Travel entries created via makeTravelAtomicFromLeg must have exactly one travel leg.');
    return entry;
  }

  @override
  String toString() {
    switch (type) {
      case EntryType.travel:
        return 'Entry(id: $id, type: $type, date: $date, from: $from, to: $to, minutes: $travelMinutes)';
      case EntryType.work:
        return 'Entry(id: $id, type: $type, date: $date, shifts: ${shifts?.length ?? 0})';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension for converting legacy TravelTimeEntry to Entry
extension TravelTimeEntryToEntry on dynamic {
  Entry toEntry(String userId) {
    return Entry(
      userId: userId,
      type: EntryType.travel,
      date: DateTime.parse(this['date']),
      from: this['from'],
      to: this['to'],
      travelMinutes: this['travelMinutes'],
      notes: this['remarks'],
    );
  }
}
