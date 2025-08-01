// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContractSettingsAdapter extends TypeAdapter<ContractSettings> {
  @override
  final int typeId = 3;

  @override
  ContractSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContractSettings(
      id: fields[0] as String,
      monthlyHours: fields[1] as int,
      contractPercentage: fields[2] as double,
      effectiveFrom: fields[3] as DateTime,
      effectiveTo: fields[4] as DateTime?,
      userId: fields[5] as String,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ContractSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monthlyHours)
      ..writeByte(2)
      ..write(obj.contractPercentage)
      ..writeByte(3)
      ..write(obj.effectiveFrom)
      ..writeByte(4)
      ..write(obj.effectiveTo)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
