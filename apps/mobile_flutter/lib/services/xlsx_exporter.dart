import 'package:excel/excel.dart';
import '../models/export_data.dart';

class XlsxExporter {
  static List<int>? export(ExportData data) {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    sheet.appendRow(
        data.headers.map((header) => TextCellValue(header)).toList());

    for (final row in data.rows) {
      sheet.appendRow(row.map((cell) {
        if (cell is num) {
          return DoubleCellValue(cell.toDouble());
        }
        return TextCellValue(cell.toString());
      }).toList());
    }

    return excel.save();
  }
}
