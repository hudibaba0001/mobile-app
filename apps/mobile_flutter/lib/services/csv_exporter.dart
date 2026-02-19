import 'package:csv/csv.dart';
import '../models/export_data.dart';

class CsvExporter {
  static String export(ExportData data) {
    return exportMultiple([data]);
  }

  static String exportMultiple(List<ExportData> sections) {
    final List<List<dynamic>> rows = [];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      if (i > 0) {
        rows.add(<dynamic>[]);
      }

      rows.add([_sanitizeCsvValue(section.sheetName)]);
      rows.add(section.headers.map(_sanitizeCsvValue).toList());
      rows.addAll(
        section.rows.map(
          (row) => row.map(_sanitizeCsvValue).toList(),
        ),
      );
    }

    return '${const ListToCsvConverter().convert(rows)}\r\n';
  }

  /// Sanitize a value to prevent CSV formula injection.
  /// Strings starting with =, +, -, @, \t, or \r can be interpreted
  /// as formulas in Excel/Sheets.
  static dynamic _sanitizeCsvValue(dynamic value) {
    if (value is! String || value.isEmpty) return value;
    final firstChar = value[0];
    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r') {
      return "'$value";
    }
    return value;
  }
}
