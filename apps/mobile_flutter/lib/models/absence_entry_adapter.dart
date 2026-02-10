import 'package:hive/hive.dart';
import 'absence.dart';

/// Hive adapter for AbsenceEntry (typeId: 10)
class AbsenceEntryAdapter extends TypeAdapter<AbsenceEntry> {
  @override
  final int typeId = 10;

  @override
  AbsenceEntry read(BinaryReader reader) {
    final id = reader.readString();
    final dateStr = reader.readString();
    final minutes = reader.readInt();
    final typeIndex = reader.readInt();

    final dateParts = dateStr.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

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
