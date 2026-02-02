// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_time_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelTimeEntryAdapter extends TypeAdapter<TravelTimeEntry> {
  @override
  final int typeId = 1;

  @override
  TravelTimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelTimeEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      departure: fields[2] as String,
      arrival: fields[3] as String,
      info: fields[4] as String?,
      minutes: fields[5] as int,
      createdAt: fields[6] as DateTime,
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
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.departure)
      ..writeByte(3)
      ..write(obj.arrival)
      ..writeByte(4)
      ..write(obj.info)
      ..writeByte(5)
      ..write(obj.minutes)
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
