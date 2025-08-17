import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/export_service.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('ExportService Tests', () {
    test('should generate CSV with correct headers', () {
      final entries = <Entry>[];
      final csvData = ExportService.convertEntriesToCSV(
        entries,
        null,
        null,
      );

      // The CSV should contain headers
      expect(csvData, contains('Entry ID'));
      expect(csvData, contains('Type'));
      expect(csvData, contains('Date'));
      expect(csvData, contains('From'));
      expect(csvData, contains('To'));
      expect(csvData, contains('Duration (Hours)'));
      expect(csvData, contains('Duration (Minutes)'));
      expect(csvData, contains('Notes'));
      expect(csvData, contains('Created At'));
      expect(csvData, contains('Updated At'));
      expect(csvData, contains('Journey ID'));
      expect(csvData, contains('Segment Order'));
      expect(csvData, contains('Total Segments'));
      expect(csvData, contains('Work Hours'));
      expect(csvData, contains('Shifts Count'));
      expect(csvData, contains('Shift Details'));
    });

    test('should generate CSV with travel entry data', () {
      final entries = [
        Entry(
          id: 'test-id-1',
          userId: 'user-123',
          type: EntryType.travel,
          from: 'Home',
          to: 'Office',
          travelMinutes: 30,
          date: DateTime(2024, 1, 15),
          notes: 'Morning commute',
          createdAt: DateTime(2024, 1, 15, 8, 0),
          updatedAt: DateTime(2024, 1, 15, 8, 0),
        ),
      ];

      final csvData = ExportService.convertEntriesToCSV(
        entries,
        null,
        null,
      );

      // Should contain the travel entry data
      expect(csvData, contains('test-id-1'));
      expect(csvData, contains('travel'));
      expect(csvData, contains('2024-01-15'));
      expect(csvData, contains('Home'));
      expect(csvData, contains('Office'));
      expect(csvData, contains('0')); // 0 hours
      expect(csvData, contains('30')); // 30 minutes
      expect(csvData, contains('Morning commute'));
    });

    test('should generate CSV with work entry data', () {
      final entries = [
        Entry(
          id: 'test-id-2',
          userId: 'user-123',
          type: EntryType.work,
          shifts: [
            Shift(
              start: DateTime(2024, 1, 15, 9, 0),
              end: DateTime(2024, 1, 15, 17, 0),
              description: 'Regular work day',
              location: 'Office',
            ),
          ],
          date: DateTime(2024, 1, 15),
          notes: 'Productive day',
          createdAt: DateTime(2024, 1, 15, 9, 0),
          updatedAt: DateTime(2024, 1, 15, 17, 0),
        ),
      ];

      final csvData = ExportService.convertEntriesToCSV(
        entries,
        null,
        null,
      );

      // Should contain the work entry data
      expect(csvData, contains('test-id-2'));
      expect(csvData, contains('work'));
      expect(csvData, contains('2024-01-15'));
      expect(csvData, contains('8')); // 8 hours
      expect(csvData, contains('480')); // 480 minutes
      expect(csvData, contains('Productive day'));
      expect(csvData, contains('1')); // 1 shift
    });

    test('should generate filename correctly', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final fileName = ExportService.generateFileName(
        startDate: startDate,
        endDate: endDate,
      );

      expect(fileName, 'time_tracker_export_20240101_to_20240131');
    });

    test('should generate filename with custom name', () {
      final fileName = ExportService.generateFileName(
        customName: 'my_custom_export',
      );

      expect(fileName, 'my_custom_export');
    });

    test('should generate filename for single date', () {
      final startDate = DateTime(2024, 1, 15);

      final fileName = ExportService.generateFileName(
        startDate: startDate,
      );

      expect(fileName, 'time_tracker_export_from_20240115');
    });

    test('should generate default filename when no parameters provided', () {
      final fileName = ExportService.generateFileName();

      expect(fileName, 'time_tracker_export');
    });
  });
}
