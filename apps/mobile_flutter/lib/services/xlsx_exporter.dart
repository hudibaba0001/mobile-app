import 'package:excel/excel.dart';
import '../models/export_data.dart';

class XlsxExporter {
  static List<int>? export(ExportData data) {
    return exportMultiple([data]);
  }

  static List<int>? exportMultiple(List<ExportData> sections) {
    final excel = Excel.createExcel();
    if (sections.isEmpty) {
      return excel.save();
    }

    final defaultSheet = excel.getDefaultSheet()!;

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sheetName = _safeSheetName(section.sheetName, i);
      final sheet = i == 0 ? excel[defaultSheet] : excel[sheetName];

      _appendSheetRows(sheet, section);
    }

    return excel.save();
  }

  static String _safeSheetName(String rawName, int index) {
    final cleaned = rawName.replaceAll(RegExp(r'[\[\]\*\/\\\?\:]'), '').trim();
    if (cleaned.isEmpty) {
      return 'Sheet${index + 1}';
    }
    if (cleaned.length > 31) {
      return cleaned.substring(0, 31);
    }
    return cleaned;
  }

  static void _appendSheetRows(Sheet sheet, ExportData data) {
    sheet.appendRow(
      data.headers.map((header) => TextCellValue(header)).toList(),
    );

    for (final row in data.rows) {
      sheet.appendRow(
        row.map((cell) {
          if (cell is num) {
            return DoubleCellValue(cell.toDouble());
          }
          return TextCellValue(cell.toString());
        }).toList(),
      );
    }
  }
}
