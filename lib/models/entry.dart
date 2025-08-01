import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'description': description,
      'location': location,
    };
  }

  /// Create from Firestore map
  factory Shift.fromFirestore(Map<String, dynamic> data) {
    return Shift(
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
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
/// Supports Hive local storage and Firestore cloud sync
@HiveType(typeId: 5)
class Entry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final EntryType type;

  // Travel-specific fields
  @HiveField(3)
  final String? from;

  @HiveField(4)
  final String? to;

  @HiveField(5)
  final int? travelMinutes;

  // Work-specific fields
  @HiveField(6)
  final List<Shift>? shifts;

  @HiveField(7)
  final DateTime date;

  // Common fields
  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? updatedAt;

  // Journey-related fields (for multi-segment travel)
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
    this.from,
    this.to,
    this.travelMinutes,
    this.shifts,
    required this.date,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.journeyId,
    this.segmentOrder,
    this.totalSegments,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Computed getters
  double get workHours {
    if (type != EntryType.work || shifts == null || shifts!.isEmpty) {
      return 0.0;
    }
    final totalMinutes = shifts!.fold<int>(
      0,
      (total, shift) => total + shift.duration.inMinutes,
    );
    return totalMinutes / 60.0;
  }

  /// Duration for travel entries
  Duration get travelDuration =>
      type == EntryType.travel && travelMinutes != null
      ? Duration(minutes: travelMinutes!)
      : Duration.zero;

  /// Duration for work entries (sum of all shifts)
  Duration get workDuration {
    if (type != EntryType.work || shifts == null) return Duration.zero;
    return shifts!.map((s) => s.duration).fold(Duration.zero, (a, b) => a + b);
  }

  /// Total duration regardless of entry type
  Duration get totalDuration {
    switch (type) {
      case EntryType.travel:
        return travelDuration;
      case EntryType.work:
        return workDuration;
    }
  }

  /// Formatted duration string
  String get formattedDuration {
    final duration = totalDuration;
    if (duration.inMinutes == 0) return '0m';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  /// Check if this is part of a multi-segment journey
  bool get isMultiSegment => journeyId != null && (totalSegments ?? 0) > 1;

  /// Check if this is a travel entry
  bool get isTravel => type == EntryType.travel;

  /// Check if this is a work entry
  bool get isWork => type == EntryType.work;

  /// Validation for travel entries
  bool get isValidTravel {
    if (type != EntryType.travel) return false;
    return from != null &&
        from!.isNotEmpty &&
        to != null &&
        to!.isNotEmpty &&
        travelMinutes != null &&
        travelMinutes! > 0;
  }

  /// Validation for work entries
  bool get isValidWork {
    if (type != EntryType.work) return false;
    return shifts != null && shifts!.isNotEmpty;
  }

  /// Overall validation
  bool get isValid {
    switch (type) {
      case EntryType.travel:
        return isValidTravel;
      case EntryType.work:
        return isValidWork;
    }
  }

  // Firestore integration

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'id': id,
      'userId': userId,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };

    // Add travel-specific fields
    if (type == EntryType.travel) {
      data.addAll({
        'from': from,
        'to': to,
        'travelMinutes': travelMinutes,
        'journeyId': journeyId,
        'segmentOrder': segmentOrder,
        'totalSegments': totalSegments,
      });
    }

    // Add work-specific fields
    if (type == EntryType.work && shifts != null) {
      data['shifts'] = shifts!.map((shift) => shift.toFirestore()).toList();
    }

    return data;
  }

  /// Create from Firestore document
  factory Entry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Entry(
      id: data['id'] ?? doc.id,
      userId: data['userId'],
      type: EntryType.values.firstWhere((e) => e.name == data['type']),
      from: data['from'],
      to: data['to'],
      travelMinutes: data['travelMinutes'],
      shifts: data['shifts'] != null
          ? (data['shifts'] as List)
                .map((s) => Shift.fromFirestore(s as Map<String, dynamic>))
                .toList()
          : null,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      journeyId: data['journeyId'],
      segmentOrder: data['segmentOrder'],
      totalSegments: data['totalSegments'],
    );
  }

  /// Create from Firestore map
  factory Entry.fromFirestoreMap(Map<String, dynamic> data) {
    return Entry(
      id: data['id'],
      userId: data['userId'],
      type: EntryType.values.firstWhere((e) => e.name == data['type']),
      from: data['from'],
      to: data['to'],
      travelMinutes: data['travelMinutes'],
      shifts: data['shifts'] != null
          ? (data['shifts'] as List)
                .map((s) => Shift.fromFirestore(s as Map<String, dynamic>))
                .toList()
          : null,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      journeyId: data['journeyId'],
      segmentOrder: data['segmentOrder'],
      totalSegments: data['totalSegments'],
    );
  }

  // Utility methods

  Entry copyWith({
    String? id,
    String? userId,
    EntryType? type,
    String? from,
    String? to,
    int? travelMinutes,
    List<Shift>? shifts,
    DateTime? date,
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
      from: from ?? this.from,
      to: to ?? this.to,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      shifts: shifts ?? this.shifts,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      journeyId: journeyId ?? this.journeyId,
      segmentOrder: segmentOrder ?? this.segmentOrder,
      totalSegments: totalSegments ?? this.totalSegments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    switch (type) {
      case EntryType.travel:
        return 'Entry(travel: $from → $to, $formattedDuration)';
      case EntryType.work:
        return 'Entry(work: ${shifts?.length ?? 0} shifts, $formattedDuration)';
    }
  }
}

/// Extension for converting legacy TravelTimeEntry to Entry
extension TravelTimeEntryToEntry on dynamic {
  Entry toEntry(String userId) {
    // Assuming this is called on a TravelTimeEntry object
    return Entry(
      id: this.id,
      userId: userId,
      type: EntryType.travel,
      from: this.departure,
      to: this.arrival,
      travelMinutes: this.minutes,
      date: this.date,
      notes: this.info,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      journeyId: this.journeyId,
      segmentOrder: this.segmentOrder,
      totalSegments: this.totalSegments,
    );
  }
}
