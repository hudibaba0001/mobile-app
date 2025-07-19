import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 1)
class Location {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String address;

  Location({
    required this.name,
    required this.address,
  });
}
