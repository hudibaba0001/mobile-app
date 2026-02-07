/// Kind of red day: full day or half day
enum RedDayKind {
  full,
  half,
}

/// Which half of the day (only for HALF kind)
enum HalfDay {
  am,
  pm,
}

/// Source of the red day
enum RedDaySource {
  manual, // User-added
  company, // From employer (future B2B)
  imported, // Bulk import
}

/// Model for user-defined red days
///
/// Users can mark their own personal red days (days off, etc.)
/// Stored in Supabase `user_red_days` table
class UserRedDay {
  final String? id;
  final String userId;
  final DateTime date;
  final RedDayKind kind;
  final HalfDay? half; // Only set if kind == HALF
  final String? reason;
  final RedDaySource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserRedDay({
    this.id,
    required this.userId,
    required this.date,
    required this.kind,
    this.half,
    this.reason,
    this.source = RedDaySource.manual,
    this.createdAt,
    this.updatedAt,
  });

  /// Validate: if kind is HALF, half must be set
  bool get isValid {
    if (kind == RedDayKind.half && half == null) return false;
    if (kind == RedDayKind.full && half != null) return false;
    return true;
  }

  /// Create from Supabase JSON
  factory UserRedDay.fromJson(Map<String, dynamic> json) {
    return UserRedDay(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      kind: json['kind'] == 'FULL' ? RedDayKind.full : RedDayKind.half,
      half: json['half'] == null
          ? null
          : (json['half'] == 'AM' ? HalfDay.am : HalfDay.pm),
      reason: json['reason'] as String?,
      source: _parseSource(json['source'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'kind': kind == RedDayKind.full ? 'FULL' : 'HALF',
      'source': _sourceToString(source),
    };

    if (id != null) {
      map['id'] = id;
    }

    if (kind == RedDayKind.half && half != null) {
      map['half'] = half == HalfDay.am ? 'AM' : 'PM';
    }

    if (reason != null && reason!.isNotEmpty) {
      map['reason'] = reason;
    }

    return map;
  }

  /// Copy with updated fields
  UserRedDay copyWith({
    String? id,
    String? userId,
    DateTime? date,
    RedDayKind? kind,
    HalfDay? half,
    String? reason,
    RedDaySource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRedDay(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      half: half ?? this.half,
      reason: reason ?? this.reason,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static RedDaySource _parseSource(String? source) {
    switch (source) {
      case 'COMPANY':
        return RedDaySource.company;
      case 'IMPORTED':
        return RedDaySource.imported;
      case 'MANUAL':
      default:
        return RedDaySource.manual;
    }
  }

  static String _sourceToString(RedDaySource source) {
    switch (source) {
      case RedDaySource.company:
        return 'COMPANY';
      case RedDaySource.imported:
        return 'IMPORTED';
      case RedDaySource.manual:
        return 'MANUAL';
    }
  }

  /// Display text for the kind
  String get kindDisplayText {
    switch (kind) {
      case RedDayKind.full:
        return 'Full day';
      case RedDayKind.half:
        return half == HalfDay.am ? 'Morning (AM)' : 'Afternoon (PM)';
    }
  }

  /// Display text for badge
  String get badgeText {
    return source == RedDaySource.manual ? 'Personal' : 'Company';
  }

  @override
  String toString() {
    return 'UserRedDay(date: $date, kind: $kind, half: $half, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRedDay && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
