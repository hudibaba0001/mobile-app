import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'absence.dart';
import '../utils/date_parser.dart';

/// Hive adapter for AbsenceEntry (typeId: 10)
class AbsenceEntryAdapter extends TypeAdapter<AbsenceEntry> {
  @override
  final int typeId = 10;

  /// Sentinel ID used to mark records that failed deserialization.
  static const String corruptedSentinelId = '__corrupted__';

  @override
  AbsenceEntry read(BinaryReader reader) {
    final id = reader.readString();
    final dateStr = reader.readString();
    final minutes = reader.readInt();
    final typeIndex = reader.readInt();

    final date = DateParser.tryParseDateOnly(dateStr);
    if (date == null) {
      debugPrint(
          'AbsenceEntryAdapter: Skipping corrupted record (id=$id, date=$dateStr)');
      // Return a sentinel that the provider will filter out.
      return AbsenceEntry(
        id: corruptedSentinelId,
        date: DateTime(1970),
        minutes: 0,
        type: AbsenceType.unknown,
      );
    }

    return AbsenceEntry(
      id: id.isEmpty ? null : id,
      date: date,
      minutes: minutes,
      type: AbsenceType.values[typeIndex],
    );
  }

  @override
  void write(BinaryWriter writer, AbsenceEntry obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(
        '${obj.date.year}-${obj.date.month.toString().padLeft(2, '0')}-${obj.date.day.toString().padLeft(2, '0')}');
    writer.writeInt(obj.minutes);
    writer.writeInt(obj.type.index);
  }
}
