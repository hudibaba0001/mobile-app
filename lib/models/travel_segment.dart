import 'package:flutter/foundation.dart';
import '../models/location.dart';

/// Represents a single segment in a multi-segment journey
class TravelSegment {
  final String id;
  final String departure;
  final String arrival;
  final int minutes;
  final String? info;
  final Location? departureLocation;
  final Location? arrivalLocation;

  const TravelSegment({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.minutes,
    this.info,
    this.departureLocation,
    this.arrivalLocation,
  });

  TravelSegment copyWith({
    String? id,
    String? departure,
    String? arrival,
    int? minutes,
    String? info,
    Location? departureLocation,
    Location? arrivalLocation,
  }) {
    return TravelSegment(
      id: id ?? this.id,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      minutes: minutes ?? this.minutes,
      info: info ?? this.info,
      departureLocation: departureLocation ?? this.departureLocation,
      arrivalLocation: arrivalLocation ?? this.arrivalLocation,
    );
  }

  /// Check if this segment is valid (has all required fields)
  bool get isValid {
    return departure.trim().isNotEmpty && 
           arrival.trim().isNotEmpty && 
           minutes > 0;
  }

  /// Get total duration formatted as string
  String get formattedDuration {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TravelSegment &&
        other.id == id &&
        other.departure == departure &&
        other.arrival == arrival &&
        other.minutes == minutes &&
        other.info == info;
  }

  @override
  int get hashCode {
    return Object.hash(id, departure, arrival, minutes, info);
  }

  @override
  String toString() {
    return 'TravelSegment(id: $id, departure: $departure, arrival: $arrival, minutes: $minutes)';
  }
}