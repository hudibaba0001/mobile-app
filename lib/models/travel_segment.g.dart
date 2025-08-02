// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_segment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelSegmentAdapter extends TypeAdapter<TravelSegment> {
  @override
  final int typeId = 4;

  @override
  TravelSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelSegment(
      id: fields[0] as String,
      departure: fields[1] as String,
      arrival: fields[2] as String,
      durationMinutes: fields[3] as int,
      departureLocation: fields[4] as String?,
      arrivalLocation: fields[5] as String?,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TravelSegment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.departure)
      ..writeByte(2)
      ..write(obj.arrival)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.departureLocation)
      ..writeByte(5)
      ..write(obj.arrivalLocation)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
