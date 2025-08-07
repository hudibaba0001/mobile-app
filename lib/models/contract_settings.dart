import 'package:hive/hive.dart';

part 'contract_settings.g.dart';

@HiveType(typeId: 3)
class ContractSettings extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int monthlyHours;

  @HiveField(2)
  final double contractPercentage;

  @HiveField(3)
  final DateTime effectiveFrom;

  @HiveField(4)
  final DateTime? effectiveTo;

  @HiveField(5)
  final String userId;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  ContractSettings({
    required this.id,
    required this.monthlyHours,
    required this.contractPercentage,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate target monthly minutes based on contract percentage
  int get targetMonthlyMinutes {
    return (monthlyHours * 60 * (contractPercentage / 100)).round();
  }

  /// Get target hours (monthly hours adjusted by contract percentage)
  double get targetHours {
    return monthlyHours * (contractPercentage / 100);
  }

  ContractSettings copyWith({
    String? id,
    int? monthlyHours,
    double? contractPercentage,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContractSettings(
      id: id ?? this.id,
      monthlyHours: monthlyHours ?? this.monthlyHours,
      contractPercentage: contractPercentage ?? this.contractPercentage,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monthlyHours': monthlyHours,
      'contractPercentage': contractPercentage,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ContractSettings.fromJson(Map<String, dynamic> json) {
    return ContractSettings(
      id: json['id'] as String,
      monthlyHours: json['monthlyHours'] as int,
      contractPercentage: (json['contractPercentage'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}