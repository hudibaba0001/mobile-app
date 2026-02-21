import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'balance_adjustment.dart';
import '../utils/date_parser.dart';

/// Hive adapter for BalanceAdjustment (typeId: 11)
class BalanceAdjustmentAdapter extends TypeAdapter<BalanceAdjustment> {
  @override
  final int typeId = 11;

  /// Sentinel ID used to mark records that failed deserialization.
  static const String corruptedSentinelId = '__corrupted__';

  @override
  BalanceAdjustment read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final dateStr = reader.readString();
    final deltaMinutes = reader.readInt();
    final note = reader.readString();

    final effectiveDate = DateParser.tryParseDateOnly(dateStr);
    if (effectiveDate == null) {
      debugPrint(
          'BalanceAdjustmentAdapter: Skipping corrupted record (id=$id, date=$dateStr)');
      return BalanceAdjustment(
        id: corruptedSentinelId,
        userId: userId,
        effectiveDate: DateTime(1970),
        deltaMinutes: 0,
        note: 'CORRUPTED: invalid date $dateStr',
      );
    }

    return BalanceAdjustment(
      id: id.isEmpty ? null : id,
      userId: userId,
      effectiveDate: effectiveDate,
      deltaMinutes: deltaMinutes,
      note: note.isEmpty ? null : note,
    );
  }

  @override
  void write(BinaryWriter writer, BalanceAdjustment obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(obj.userId);
    writer.writeString(
        '${obj.effectiveDate.year}-${obj.effectiveDate.month.toString().padLeft(2, '0')}-${obj.effectiveDate.day.toString().padLeft(2, '0')}');
    writer.writeInt(obj.deltaMinutes);
    writer.writeString(obj.note ?? '');
  }
}
