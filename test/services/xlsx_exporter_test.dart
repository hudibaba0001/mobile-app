import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/export_data.dart';
import 'package:myapp/services/xlsx_exporter.dart';
import 'package:excel/excel.dart';

void main() {
  group('XlsxExporter', () {
    test('should convert ExportData to XLSX bytes', () {
      // Arrange
      final data = ExportData(
        headers: ['Header 1', 'Header 2'],
        rows: [
          ['Value 1', 2],
          ['Value 3', 4.5],
        ],
      );

      // Act
      final xlsxBytes = XlsxExporter.export(data);
      final excel = Excel.decodeBytes(xlsxBytes!);
      final sheet = excel[excel.getDefaultSheet()!];

      // Assert
      expect(sheet.maxRows, 3);
      expect(sheet.cell(CellIndex.indexByString('A1')).value.toString(), 'Header 1');
      expect(sheet.cell(CellIndex.indexByString('B1')).value.toString(), 'Header 2');
      expect(sheet.cell(CellIndex.indexByString('A2')).value.toString(), 'Value 1');
      expect(sheet.cell(CellIndex.indexByString('B2')).value.toString(), '2');
      expect(sheet.cell(CellIndex.indexByString('A3')).value.toString(), 'Value 3');
      expect(sheet.cell(CellIndex.indexByString('B3')).value.toString(), '4.5');
    });

    test('should handle empty data', () {
      // Arrange
      final data = ExportData(
        headers: [],
        rows: [],
      );

      // Act
      final xlsxBytes = XlsxExporter.export(data);
      final excel = Excel.decodeBytes(xlsxBytes!);
      final sheet = excel[excel.getDefaultSheet()!];

      // Assert
      expect(sheet.maxRows, 0);
    });

    test('should handle data with only headers', () {
      // Arrange
      final data = ExportData(
        headers: ['Header 1', 'Header 2'],
        rows: [],
      );

      // Act
      final xlsxBytes = XlsxExporter.export(data);
      final excel = Excel.decodeBytes(xlsxBytes!);
      final sheet = excel[excel.getDefaultSheet()!];

      // Assert
      expect(sheet.maxRows, 1);
      expect(sheet.cell(CellIndex.indexByString('A1')).value.toString(), 'Header 1');
      expect(sheet.cell(CellIndex.indexByString('B1')).value.toString(), 'Header 2');
    });
  });
}
