import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('should prepare export data with correct headers', () {
      final entries = <Entry>[];
      final exportData = ExportService.prepareExportData(entries);

      // The exportData should contain headers
      expect(exportData.headers, contains('Entry ID'));
      expect(exportData.headers, contains('Type'));
      expect(exportData.headers, contains('Date'));
      expect(exportData.headers, contains('From'));
      expect(exportData.headers, contains('To'));
      expect(exportData.headers, contains('Duration (Hours)'));
      expect(exportData.headers, contains('Duration (Minutes)'));
      expect(exportData.headers, contains('Notes'));
      expect(exportData.headers, contains('Created At'));
      expect(exportData.headers, contains('Updated At'));
      expect(exportData.headers, contains('Journey ID'));
      expect(exportData.headers, contains('Segment Order'));
      expect(exportData.headers, contains('Total Segments'));
      expect(exportData.headers, contains('Work Hours'));
      expect(exportData.headers, contains('Shifts Count'));
      expect(exportData.headers, contains('Shift Details'));
    });

    test('should prepare export data with travel entry data', () {
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

      final exportData = ExportService.prepareExportData(entries);

      // Should contain the travel entry data
      expect(exportData.rows[0], contains('test-id-1'));
      expect(exportData.rows[0], contains('travel'));
      expect(exportData.rows[0], contains('2024-01-15'));
      expect(exportData.rows[0], contains('Home'));
      expect(exportData.rows[0], contains('Office'));
      expect(exportData.rows[0], contains(0)); // 0 hours
      expect(exportData.rows[0], contains(30)); // 30 minutes
      expect(exportData.rows[0], contains('Morning commute'));
    });

    test('should prepare export data with work entry data', () {
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

      final exportData = ExportService.prepareExportData(entries);

      // Should contain the work entry data
      expect(exportData.rows[0], contains('test-id-2'));
      expect(exportData.rows[0], contains('work'));
      expect(exportData.rows[0], contains('2024-01-15'));
      expect(exportData.rows[0], contains(8)); // 8 hours
      expect(exportData.rows[0], contains(480)); // 480 minutes
      expect(exportData.rows[0], contains('Productive day'));
      expect(exportData.rows[0], contains(1)); // 1 shift
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
