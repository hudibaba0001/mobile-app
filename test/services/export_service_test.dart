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
      expect(exportData.headers, contains('Travel Minutes'));
      expect(exportData.headers, contains('Travel Source'));
      expect(exportData.headers, contains('Travel Distance (km)'));
      expect(exportData.headers, contains('Leg Number'));
      expect(exportData.headers, contains('Shift Number'));
      expect(exportData.headers, contains('Shift Start'));
      expect(exportData.headers, contains('Shift End'));
      expect(exportData.headers, contains('Span Minutes'));
      expect(exportData.headers, contains('Unpaid Break Minutes'));
      expect(exportData.headers, contains('Worked Minutes'));
      expect(exportData.headers, contains('Worked Hours'));
      expect(exportData.headers, contains('Shift Location'));
      expect(exportData.headers, contains('Shift Notes'));
      expect(exportData.headers, contains('Entry Notes'));
      expect(exportData.headers, contains('Created At'));
      expect(exportData.headers, contains('Updated At'));
      expect(exportData.headers, contains('Journey ID'));
      expect(exportData.headers, contains('Total Legs'));
      expect(exportData.headers, contains('Holiday Work'));
      expect(exportData.headers, contains('Holiday Name'));
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
      expect(exportData.rows[0], [
        'test-id-1',
        'travel',
        '2024-01-15',
        'Home',
        'Office',
        30,
        'manual',
        0.0, // Travel Distance (km) - use 0 instead of '' for consistency
        1,
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'Morning commute',
        '2024-01-15 08:00:00',
        '2024-01-15 08:00:00',
        '',
        1,
        'No',
        '',
      ]);
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
      expect(exportData.rows[0][0], 'test-id-2'); // Entry ID
      expect(exportData.rows[0][1], 'work'); // Type
      expect(exportData.rows[0][2], '2024-01-15'); // Date
      expect(exportData.rows[0][12], 480); // Span Minutes (8 hours = 480)
      expect(exportData.rows[0][13], 0); // Unpaid Break Minutes (default 0)
      expect(exportData.rows[0][14], 480); // Worked Minutes (480 - 0 = 480)
      expect(exportData.rows[0][15], '8.00'); // Worked Hours (string with 2 decimals)
      expect(exportData.rows[0][18], 'Productive day'); // Entry Notes
    });

    test('given 2 work entries + 2 travel entries same date: CSV row count equals expected', () {
      final date = DateTime(2025, 1, 15);
      
      // Two atomic work entries for same date
      final workEntry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 8, 0),
          end: DateTime(2025, 1, 15, 12, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 15,
        ),
      );
      
      final workEntry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 13, 0),
          end: DateTime(2025, 1, 15, 17, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 30,
        ),
      );
      
      // Two atomic travel entries for same date
      final travelEntry1 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'Home',
        to: 'Office',
        minutes: 30,
      );
      
      final travelEntry2 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'Office',
        to: 'Home',
        minutes: 25,
      );
      
      final entries = [workEntry1, workEntry2, travelEntry1, travelEntry2];
      final exportData = ExportService.prepareExportData(entries);
      
      // Should have 4 rows (one per atomic entry)
      // Each work entry = 1 row, each travel entry = 1 row
      expect(exportData.rows.length, 4);
      
      // Verify worked minutes and unpaid break minutes in rows
      // Work entry 1: worked = 240 - 15 = 225, break = 15
      final workRow1 = exportData.rows.firstWhere((row) => 
        row[0] == workEntry1.id && row[1] == 'work'
      );
      expect(workRow1[13], 15); // Unpaid Break Minutes
      expect(workRow1[14], 225); // Worked Minutes
      
      // Work entry 2: worked = 240 - 30 = 210, break = 30
      final workRow2 = exportData.rows.firstWhere((row) => 
        row[0] == workEntry2.id && row[1] == 'work'
      );
      expect(workRow2[13], 30); // Unpaid Break Minutes
      expect(workRow2[14], 210); // Worked Minutes
    });

    test('given 2 work entries + 2 travel entries same date: XLSX row count equals expected', () {
      final date = DateTime(2025, 1, 16);
      
      final workEntry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 9, 0),
          end: DateTime(2025, 1, 16, 17, 0), // 8 hours = 480 minutes
          unpaidBreakMinutes: 30,
        ),
      );
      
      final workEntry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 18, 0),
          end: DateTime(2025, 1, 16, 22, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 15,
        ),
      );
      
      final travelEntry1 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'A',
        to: 'B',
        minutes: 20,
      );
      
      final travelEntry2 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'B',
        to: 'C',
        minutes: 15,
      );
      
      final entries = [workEntry1, workEntry2, travelEntry1, travelEntry2];
      final exportData = ExportService.prepareExportData(entries);
      
      // XLSX uses same data structure as CSV
      expect(exportData.rows.length, 4);
      
      // Spot-check worked_minutes and unpaid_break_minutes cells
      // Work entry 1: worked = 480 - 30 = 450, break = 30
      final workRow1 = exportData.rows.firstWhere((row) => 
        row[0] == workEntry1.id && row[1] == 'work'
      );
      expect(workRow1[13], 30); // Unpaid Break Minutes
      expect(workRow1[14], 450); // Worked Minutes
      
      // Work entry 2: worked = 240 - 15 = 225, break = 15
      final workRow2 = exportData.rows.firstWhere((row) => 
        row[0] == workEntry2.id && row[1] == 'work'
      );
      expect(workRow2[13], 15); // Unpaid Break Minutes
      expect(workRow2[14], 225); // Worked Minutes
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
