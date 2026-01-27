import 'package:hive/hive.dart';

part 'work_entry.g.dart';

@HiveType(typeId: 2)
class WorkEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int workMinutes;

  @HiveField(3)
  final String remarks;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String userId;

  WorkEntry({
    required this.id,
    required this.date,
    required this.workMinutes,
    this.remarks = '',
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WorkEntry copyWith({
    String? id,
    DateTime? date,
    int? workMinutes,
    String? remarks,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      workMinutes: workMinutes ?? this.workMinutes,
      remarks: remarks ?? this.remarks,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'workMinutes': workMinutes,
      'remarks': remarks,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      workMinutes: json['workMinutes'] as int,
      remarks: json['remarks'] as String? ?? '',
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
