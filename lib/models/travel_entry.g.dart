// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelEntryAdapter extends TypeAdapter<TravelEntry> {
  @override
  final int typeId = 1;

  @override
  TravelEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelEntry(
      id: fields[0] as String,
      userId: fields[3] as String,
      date: fields[4] as DateTime,
      fromLocation: fields[5] as String,
      toLocation: fields[6] as String,
      travelMinutes: fields[7] as int,
      remarks: fields[8] as String,
      createdAt: fields[1] as DateTime?,
      updatedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TravelEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.fromLocation)
      ..writeByte(6)
      ..write(obj.toLocation)
      ..writeByte(7)
      ..write(obj.travelMinutes)
      ..writeByte(8)
      ..write(obj.remarks)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
