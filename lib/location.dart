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
}
