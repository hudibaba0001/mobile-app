import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 8)
class Location extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final int usageCount;

  @HiveField(5)
  final bool isFavorite;

  Location({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    this.usageCount = 0,
    this.isFavorite = false,
  });

  Location copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    int? usageCount,
    bool? isFavorite,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'usageCount': usageCount,
      'isFavorite': isFavorite,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usageCount: json['usageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
