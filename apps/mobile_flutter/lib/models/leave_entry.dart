import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'leave_entry.g.dart';

@HiveType(typeId: 4)
enum LeaveType {
  @HiveField(0)
  sick,

  @HiveField(1)
  vacation,

  @HiveField(2)
  unpaid,

  @HiveField(3)
  vab, // Care of sick child (Swedish system)

  @HiveField(4)
  unknown,
}

@HiveType(typeId: 5)
class LeaveEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final LeaveType type;

  @HiveField(3)
  final String reason;

  @HiveField(4)
  final bool isPaid;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final String userId;

  @HiveField(8)
  final String? rawType;

  LeaveEntry({
    required this.id,
    required this.date,
    required this.type,
    this.reason = '',
    required this.isPaid,
    required this.userId,
    this.rawType,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  LeaveEntry copyWith({
    String? id,
    DateTime? date,
    LeaveType? type,
    String? reason,
    bool? isPaid,
    String? userId,
    String? rawType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      isPaid: isPaid ?? this.isPaid,
      userId: userId ?? this.userId,
      rawType: rawType ?? this.rawType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type == LeaveType.unknown && rawType != null ? rawType! : type.name,
      'reason': reason,
      'isPaid': isPaid,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LeaveEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final resolvedType = LeaveType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () {
        debugPrint('LeaveEntry: Safely mapped unknown leave type: $typeStr');
        return LeaveType.unknown;
      },
    );

    return LeaveEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: resolvedType,
      reason: json['reason'] as String? ?? '',
      isPaid: json['isPaid'] as bool,
      userId: json['userId'] as String,
      rawType: resolvedType == LeaveType.unknown ? typeStr : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
