import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'user_red_day.dart';
import '../utils/date_parser.dart';

/// Hive adapter for UserRedDay (typeId: 12)
class UserRedDayAdapter extends TypeAdapter<UserRedDay> {
  @override
  final int typeId = 12;

  /// Sentinel ID used to mark records that failed deserialization.
  static const String corruptedSentinelId = '__corrupted__';

  @override
  UserRedDay read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final dateStr = reader.readString();
    final kindIndex = reader.readInt();
    final halfIndex = reader.readInt(); // -1 means null
    final reason = reader.readString();
    final sourceIndex = reader.readInt();

    final date = DateParser.tryParseDateOnly(dateStr);
    if (date == null) {
      debugPrint(
          'UserRedDayAdapter: Skipping corrupted record (id=$id, date=$dateStr)');
      return UserRedDay(
        id: corruptedSentinelId,
        userId: userId,
        date: DateTime(1970),
        kind: RedDayKind.values[kindIndex],
        half: halfIndex >= 0 ? HalfDay.values[halfIndex] : null,
        reason: 'CORRUPTED: invalid date $dateStr',
        source: RedDaySource.values[sourceIndex],
      );
    }

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
