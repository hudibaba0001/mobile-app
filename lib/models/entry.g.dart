// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftAdapter extends TypeAdapter<Shift> {
  @override
  final int typeId = 7;

  @override
  Shift read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shift(
      start: fields[0] as DateTime,
      end: fields[1] as DateTime,
      description: fields[2] as String?,
      location: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 5;

  @override
  Entry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Entry(
      id: fields[0] as String?,
      userId: fields[1] as String,
      type: fields[2] as EntryType,
      from: fields[3] as String?,
      to: fields[4] as String?,
      travelMinutes: fields[5] as int?,
      shifts: (fields[6] as List?)?.cast<Shift>(),
      date: fields[7] as DateTime,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
      journeyId: fields[11] as String?,
      segmentOrder: fields[12] as int?,
      totalSegments: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.from)
      ..writeByte(4)
      ..write(obj.to)
      ..writeByte(5)
      ..write(obj.travelMinutes)
      ..writeByte(6)
      ..write(obj.shifts)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.journeyId)
      ..writeByte(12)
      ..write(obj.segmentOrder)
      ..writeByte(13)
      ..write(obj.totalSegments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryTypeAdapter extends TypeAdapter<EntryType> {
  @override
  final int typeId = 6;

  @override
  EntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryType.travel;
      case 1:
        return EntryType.work;
      default:
        return EntryType.travel;
    }
  }

  @override
  void write(BinaryWriter writer, EntryType obj) {
    switch (obj) {
      case EntryType.travel:
        writer.writeByte(0);
        break;
      case EntryType.work:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
