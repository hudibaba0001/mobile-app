import 'package:hive/hive.dart';

part 'travel_time_entry.g.dart';

@HiveType(typeId: 1)
class TravelTimeEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String departure;

  @HiveField(3)
  final String arrival;

  @HiveField(4)
  final String? info;

  @HiveField(5)
  final int minutes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  @HiveField(8)
  final String? departureLocationId;

  @HiveField(9)
  final String? arrivalLocationId;

  TravelTimeEntry({
    required this.id,
    required this.date,
    required this.departure,
    required this.arrival,
    this.info,
    required this.minutes,
    required this.createdAt,
    this.updatedAt,
    this.departureLocationId,
    this.arrivalLocationId,
  });
}
