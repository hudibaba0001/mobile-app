import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'user_red_day.dart';
import '../utils/date_parser.dart';

T safeEnum<T>(List<T> values, int index, T fallback) {
  if (index < 0 || index >= values.length) return fallback;
  return values[index];
}

T? safeNullableEnum<T>(List<T> values, int index) {
  if (index < 0 || index >= values.length) return null;
  return values[index];
}

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
        kind: safeEnum(RedDayKind.values, kindIndex, RedDayKind.full),
        half: safeNullableEnum(HalfDay.values, halfIndex),
        reason: 'CORRUPTED: invalid date $dateStr',
        source: safeEnum(RedDaySource.values, sourceIndex, RedDaySource.manual),
      );
    }

    return UserRedDay(
      id: id.isEmpty ? null : id,
      userId: userId,
      date: date,
      kind: safeEnum(RedDayKind.values, kindIndex, RedDayKind.full),
      half: safeNullableEnum(HalfDay.values, halfIndex),
      reason: reason.isEmpty ? null : reason,
      source: safeEnum(RedDaySource.values, sourceIndex, RedDaySource.manual),
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
