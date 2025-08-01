// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeaveEntryAdapter extends TypeAdapter<LeaveEntry> {
  @override
  final int typeId = 5;

  @override
  LeaveEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaveEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as LeaveType,
      reason: fields[3] as String,
      isPaid: fields[4] as bool,
      userId: fields[7] as String,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LeaveEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.isPaid)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LeaveTypeAdapter extends TypeAdapter<LeaveType> {
  @override
  final int typeId = 4;

  @override
  LeaveType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LeaveType.sick;
      case 1:
        return LeaveType.vacation;
      case 2:
        return LeaveType.unpaid;
      case 3:
        return LeaveType.vab;
      default:
        return LeaveType.sick;
    }
  }

  @override
  void write(BinaryWriter writer, LeaveType obj) {
    switch (obj) {
      case LeaveType.sick:
        writer.writeByte(0);
        break;
      case LeaveType.vacation:
        writer.writeByte(1);
        break;
      case LeaveType.unpaid:
        writer.writeByte(2);
        break;
      case LeaveType.vab:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
