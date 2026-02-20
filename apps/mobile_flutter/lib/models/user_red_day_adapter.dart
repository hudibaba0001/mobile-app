import 'package:hive/hive.dart';
import 'user_red_day.dart';
import '../utils/date_parser.dart';

/// Hive adapter for UserRedDay (typeId: 12)
class UserRedDayAdapter extends TypeAdapter<UserRedDay> {
  @override
  final int typeId = 12;

  @override
  UserRedDay read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final dateStr = reader.readString();
    final kindIndex = reader.readInt();
    final halfIndex = reader.readInt(); // -1 means null
    final reason = reader.readString();
    final sourceIndex = reader.readInt();

    final date = DateParser.tryParseDateOnly(dateStr) ?? DateTime.now();

    return UserRedDay(
      id: id.isEmpty ? null : id,
      userId: userId,
      date: date,
      kind: RedDayKind.values[kindIndex],
      half: halfIndex >= 0 ? HalfDay.values[halfIndex] : null,
      reason: reason.isEmpty ? null : reason,
      source: RedDaySource.values[sourceIndex],
    );
  }

  @override
  void write(BinaryWriter writer, UserRedDay obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(obj.userId);
    writer.writeString(
        '${obj.date.year}-${obj.date.month.toString().padLeft(2, '0')}-${obj.date.day.toString().padLeft(2, '0')}');
    writer.writeInt(obj.kind.index);
    writer.writeInt(obj.half?.index ?? -1);
    writer.writeString(obj.reason ?? '');
    writer.writeInt(obj.source.index);
  }
}
