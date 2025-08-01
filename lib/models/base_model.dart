import 'package:hive/hive.dart';

@HiveType(typeId: 0)
abstract class BaseModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final DateTime updatedAt;

  @HiveField(3)
  final String userId;

  BaseModel({
    required this.id,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if the model has meaningful changes that warrant an update
  bool hasSignificantChanges(BaseModel other) => false;

  /// Create a copy of this model with updated timestamps
  BaseModel copyWithTimestamps({
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  Map<String, dynamic> toJson();
}