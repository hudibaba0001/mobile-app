// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_time_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelTimeEntryAdapter extends TypeAdapter<TravelTimeEntry> {
  @override
  final int typeId = 0;

  @override
  TravelTimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelTimeEntry(
      date: fields[0] as DateTime,
      departure: fields[1] as String,
      arrival: fields[2] as String,
      info: fields[3] as String?,
      minutes: fields[4] as int,
      id: fields[5] as String? ?? const Uuid().v4(),
      createdAt: fields[6] as DateTime? ?? DateTime.now(),
      updatedAt: fields[7] as DateTime?,
      departureLocationId: fields[8] as String?,
      arrivalLocationId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TravelTimeEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.departure)
      ..writeByte(2)
      ..write(obj.arrival)
      ..writeByte(3)
      ..write(obj.info)
      ..writeByte(4)
      ..write(obj.minutes)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.departureLocationId)
      ..writeByte(9)
      ..write(obj.arrivalLocationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelTimeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}