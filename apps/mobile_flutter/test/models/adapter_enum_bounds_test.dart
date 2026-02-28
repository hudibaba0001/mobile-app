import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/absence_entry_adapter.dart';
import 'package:myapp/models/user_red_day.dart';
import 'package:myapp/models/user_red_day_adapter.dart';

class _ListBinaryWriter extends BinaryWriter {
  final List<Object?> values = <Object?>[];

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    values.add(value);
  }

  @override
  void writeInt(int value) {
    values.add(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected BinaryWriter call: $invocation');
}

class _ListBinaryReader extends BinaryReader {
  _ListBinaryReader(this._values);

  final List<Object?> _values;
  int _cursor = 0;

  @override
  int get availableBytes => _values.length - _cursor;

  @override
  int get usedBytes => _cursor;

  @override
  String readString([
    int? byteCount,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) {
    return _values[_cursor++] as String;
  }

  @override
  int readInt() {
    return _values[_cursor++] as int;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected BinaryReader call: $invocation');
}

void main() {
  group('Hive adapter enum index bounds safety', () {
    test('AbsenceEntryAdapter falls back to AbsenceType.unknown for bad index',
        () {
      final writer = _ListBinaryWriter()
        ..writeString('absence-1')
        ..writeString('2026-02-03')
        ..writeInt(480)
        ..writeInt(999);

      final entry = AbsenceEntryAdapter().read(_ListBinaryReader(writer.values));

      expect(entry.id, 'absence-1');
      expect(entry.type, AbsenceType.unknown);
    });

    test('UserRedDayAdapter falls back for bad enum indexes', () {
      final writer = _ListBinaryWriter()
        ..writeString('redday-1')
        ..writeString('user-1')
        ..writeString('2026-02-03')
        ..writeInt(999) // kind
        ..writeInt(999) // half
        ..writeString('')
        ..writeInt(999); // source

      final redDay = UserRedDayAdapter().read(_ListBinaryReader(writer.values));

      expect(redDay.id, 'redday-1');
      expect(redDay.kind, RedDayKind.full);
      expect(redDay.half, isNull);
      expect(redDay.source, RedDaySource.manual);
    });
  });
}
