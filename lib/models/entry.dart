import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'entry.g.dart';

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

  Shift({
    required this.start,
    required this.end,
    this.description,
    this.location,
  });

  /// Duration of this shift
  Duration get duration => end.difference(start);

  /// Convert to map for Supabase
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'description': description,
      'location': location,
    };
  }

  /// Create from Supabase map
  factory Shift.fromJson(Map<String, dynamic> data) {
    return Shift(
      start: DateTime.parse(data['start']),
      end: DateTime.parse(data['end']),
      description: data['description'],
      location: data['location'],
    );
  }

  Shift copyWith({
    DateTime? start,
    DateTime? end,
    String? description,
    String? location,
  }) {
    return Shift(
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      location: location ?? this.location,
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
    };

    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toIso8601String();
    }

    // Add type-specific fields
    if (type == EntryType.travel) {
      if (from != null) data['from_location'] = from;
      if (to != null) data['to_location'] = to;
      if (travelMinutes != null) data['travel_minutes'] = travelMinutes;
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
    );

    // Parse shifts for work entries
    if (type == EntryType.work && json['shifts'] != null) {
      final shiftsList = json['shifts'] as List;
      final shifts = shiftsList
          .map((s) => Shift.fromJson(s as Map<String, dynamic>))
          .toList();
      return entry.copyWith(shifts: shifts);
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
    );
  }

  /// Get total duration for work entries
  Duration? get totalWorkDuration {
    if (type != EntryType.work || shifts == null || shifts!.isEmpty) {
      return null;
    }

    var totalDuration = Duration.zero;
    for (final shift in shifts!) {
      totalDuration += shift.duration;
    }

    return totalDuration;
  }

  /// Get total duration for any entry type
  Duration get totalDuration {
    if (type == EntryType.work) {
      return totalWorkDuration ?? Duration.zero;
    } else if (type == EntryType.travel) {
      return Duration(minutes: travelMinutes ?? 0);
    }
    return Duration.zero;
  }

  /// Get work duration
  Duration get workDuration => totalWorkDuration ?? Duration.zero;

  /// Check if entry is a valid travel entry
  bool get isValidTravel {
    if (type != EntryType.travel) return false;
    return from != null && from!.isNotEmpty && 
           to != null && to!.isNotEmpty &&
           (travelMinutes != null && travelMinutes! > 0);
  }

  /// Get travel duration
  Duration get travelDuration => Duration(minutes: travelMinutes ?? 0);

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
