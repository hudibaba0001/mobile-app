import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'travel_time_entry.g.dart';

@HiveType(typeId: 0)
class TravelTimeEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final String departure;
  
  @HiveField(2)
  final String arrival;
  
  @HiveField(3)
  final String? info;
  
  @HiveField(4)
  final int minutes;
  
  @HiveField(5)
  final String id;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime? updatedAt;
  
  @HiveField(8)
  final String? departureLocationId;
  
  @HiveField(9)
  final String? arrivalLocationId;

  TravelTimeEntry({
    required this.date,
    required this.departure,
    required this.arrival,
    this.info,
    required this.minutes,
    String? id,
    DateTime? createdAt,
    this.updatedAt,
    this.departureLocationId,
    this.arrivalLocationId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  TravelTimeEntry copyWith({
    DateTime? date,
    String? departure,
    String? arrival,
    String? info,
    int? minutes,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? departureLocationId,
    String? arrivalLocationId,
  }) {
    return TravelTimeEntry(
      date: date ?? this.date,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      info: info ?? this.info,
      minutes: minutes ?? this.minutes,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      departureLocationId: departureLocationId ?? this.departureLocationId,
      arrivalLocationId: arrivalLocationId ?? this.arrivalLocationId,
    );
  }

  @override
  String toString() {
    return 'TravelTimeEntry(id: $id, date: $date, departure: $departure, arrival: $arrival, minutes: $minutes)';
  }
}