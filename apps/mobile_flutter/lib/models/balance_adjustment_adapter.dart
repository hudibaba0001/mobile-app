import 'package:hive/hive.dart';
import 'balance_adjustment.dart';

/// Hive adapter for BalanceAdjustment (typeId: 11)
class BalanceAdjustmentAdapter extends TypeAdapter<BalanceAdjustment> {
  @override
  final int typeId = 11;

  @override
  BalanceAdjustment read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final dateStr = reader.readString();
    final deltaMinutes = reader.readInt();
    final note = reader.readString();

    final dateParts = dateStr.split('-');
    final effectiveDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

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
