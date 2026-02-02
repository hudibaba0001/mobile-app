import 'package:hive/hive.dart';

part 'travel_segment.g.dart';

@HiveType(typeId: 4)
class TravelSegment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String departure;

  @HiveField(2)
  final String arrival;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final String? departureLocation;

  @HiveField(5)
  final String? arrivalLocation;

  @HiveField(6)
  final String? notes;

  TravelSegment({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.durationMinutes,
    this.departureLocation,
    this.arrivalLocation,
    this.notes,
  });

  // Getter for backward compatibility
  String? get info => notes;

  // Getter for formatted duration
  String get formattedDuration {
    if (durationMinutes == 0) return '0m';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  TravelSegment copyWith({
    String? id,
    String? departure,
    String? arrival,
    int? durationMinutes,
    String? departureLocation,
    String? arrivalLocation,
    String? notes,
  }) {
    return TravelSegment(
      id: id ?? this.id,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      departureLocation: departureLocation ?? this.departureLocation,
      arrivalLocation: arrivalLocation ?? this.arrivalLocation,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departure': departure,
      'arrival': arrival,
      'durationMinutes': durationMinutes,
      'departureLocation': departureLocation,
      'arrivalLocation': arrivalLocation,
      'notes': notes,
    };
  }

  factory TravelSegment.fromJson(Map<String, dynamic> json) {
    return TravelSegment(
      id: json['id'] as String,
      departure: json['departure'] as String,
      arrival: json['arrival'] as String,
      durationMinutes: json['durationMinutes'] as int,
      departureLocation: json['departureLocation'] as String?,
      arrivalLocation: json['arrivalLocation'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
