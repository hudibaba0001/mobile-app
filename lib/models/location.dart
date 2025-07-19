import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'location.g.dart';

@HiveType(typeId: 1)
class Location extends HiveObject {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final String address;
  
  @HiveField(2)
  final String id;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final int usageCount;
  
  @HiveField(5)
  final bool isFavorite;

  Location({
    required this.name,
    required this.address,
    String? id,
    DateTime? createdAt,
    this.usageCount = 0,
    this.isFavorite = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Location copyWith({
    String? name,
    String? address,
    String? id,
    DateTime? createdAt,
    int? usageCount,
    bool? isFavorite,
  }) {
    return Location(
      name: name ?? this.name,
      address: address ?? this.address,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Location incrementUsage() {
    return copyWith(usageCount: usageCount + 1);
  }

  Location toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  @override
  String toString() {
    return 'Location(id: $id, name: $name, address: $address, usageCount: $usageCount)';
  }
}