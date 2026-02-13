// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailSettingsAdapter extends TypeAdapter<EmailSettings> {
  @override
  final int typeId = 3;

  @override
  EmailSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailSettings(
      managerEmail: (fields[0] as String?) ?? '',
      senderEmail: (fields[1] as String?) ?? '',
      senderName: (fields[3] as String?) ?? '',
      autoSendEnabled: (fields[4] as bool?) ?? false,
      autoSendFrequency: (fields[5] as String?) ?? 'weekly',
      autoSendDay: (fields[6] as int?) ?? 1,
      defaultReportFormat: (fields[7] as String?) ?? 'excel',
      defaultReportPeriod: (fields[8] as String?) ?? 'lastWeek',
      customSubjectTemplate: (fields[9] as String?) ?? '',
      customMessageTemplate: (fields[10] as String?) ?? '',
      includeCharts: (fields[11] as bool?) ?? true,
      includeSummary: (fields[12] as bool?) ?? true,
      includeDetailedEntries: (fields[13] as bool?) ?? true,
      lastSentDate: fields[14] as DateTime?,
      smtpServer: (fields[15] as String?) ?? 'smtp.gmail.com',
      smtpPort: (fields[16] as int?) ?? 587,
      useSSL: (fields[17] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, EmailSettings obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.managerEmail)
      ..writeByte(1)
      ..write(obj.senderEmail)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.autoSendEnabled)
      ..writeByte(5)
      ..write(obj.autoSendFrequency)
      ..writeByte(6)
      ..write(obj.autoSendDay)
      ..writeByte(7)
      ..write(obj.defaultReportFormat)
      ..writeByte(8)
      ..write(obj.defaultReportPeriod)
      ..writeByte(9)
      ..write(obj.customSubjectTemplate)
      ..writeByte(10)
      ..write(obj.customMessageTemplate)
      ..writeByte(11)
      ..write(obj.includeCharts)
      ..writeByte(12)
      ..write(obj.includeSummary)
      ..writeByte(13)
      ..write(obj.includeDetailedEntries)
      ..writeByte(14)
      ..write(obj.lastSentDate)
      ..writeByte(15)
      ..write(obj.smtpServer)
      ..writeByte(16)
      ..write(obj.smtpPort)
      ..writeByte(17)
      ..write(obj.useSSL);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
