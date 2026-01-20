import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/export_data.dart';
import 'package:myapp/services/csv_exporter.dart';

void main() {
  group('CsvExporter', () {
    test('should convert ExportData to CSV string', () {
      // Arrange
      final data = ExportData(
        headers: ['Header 1', 'Header 2'],
        rows: [
          ['Value 1', 'Value 2'],
          ['Value 3', 'Value 4'],
        ],
      );

      // Act
      final csvString = CsvExporter.export(data);

      // Assert
      expect(csvString, 'Header 1,Header 2\r\nValue 1,Value 2\r\nValue 3,Value 4\r\n');
    });

    test('should handle empty data', () {
      // Arrange
      final data = ExportData(
        headers: [],
        rows: [],
      );

      // Act
      final csvString = CsvExporter.export(data);

      // Assert
      expect(csvString, '\r\n');
    });

    test('should handle data with only headers', () {
      // Arrange
      final data = ExportData(
        headers: ['Header 1', 'Header 2'],
        rows: [],
      );

      // Act
      final csvString = CsvExporter.export(data);

      // Assert
      expect(csvString, 'Header 1,Header 2\r\n');
    });
  });
}
