import 'package:hive/hive.dart';
import 'base_model.dart';

part 'travel_entry.g.dart';

@HiveType(typeId: 1)
class TravelEntry extends BaseModel {
  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String fromLocation;

  @HiveField(6)
  final String toLocation;

  @HiveField(7)
  final int travelMinutes;

  @HiveField(8)
  final String remarks;

  TravelEntry({
    required super.id,
    required super.userId,
    required this.date,
    required this.fromLocation,
    required this.toLocation,
    required this.travelMinutes,
    this.remarks = '',
    super.createdAt,
    super.updatedAt,
  });

  TravelEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? fromLocation,
    String? toLocation,
    int? travelMinutes,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TravelEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'travelMinutes': travelMinutes,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TravelEntry.fromJson(Map<String, dynamic> json) {
    return TravelEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      fromLocation: json['fromLocation'] as String,
      toLocation: json['toLocation'] as String,
      travelMinutes: json['travelMinutes'] as int,
      remarks: json['remarks'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  BaseModel copyWithTimestamps({DateTime? createdAt, DateTime? updatedAt}) {
    return copyWith(
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
