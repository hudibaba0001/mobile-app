import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('should prepare export data with correct headers', () {
      final entries = <Entry>[];
      final exportData = ExportService.prepareExportData(entries);

      // With no entries we include the minimal set of columns
      expect(exportData.headers, equals(['Type', 'Date', 'Entry Notes']));
    });

    test('should prepare export data with travel entry data', () {
      final entries = [
        Entry(
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

      // Travel-only export uses travel + entry columns
      expect(
          exportData.headers,
          equals([
            'Type',
            'Date',
            'From',
            'To',
            'Travel Minutes',
            'Travel Distance (km)',
            'Entry Notes',
          ]));

      expect(exportData.rows[0], [
        'travel',
        '2024-01-15',
        'Home',
        'Office',
        30,
        0.0,
        'Morning commute',
      ]);
    });

    test('should prepare export data with work entry data', () {
      final entries = [
        Entry(
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

      // Work-only export headers
      expect(
          exportData.headers,
          equals([
            'Type',
            'Date',
            'Shift Number',
            'Shift Start',
            'Shift End',
            'Span Minutes',
            'Unpaid Break Minutes',
            'Worked Minutes',
            'Worked Hours',
            'Shift Location',
            'Shift Notes',
            'Entry Notes',
            'Created At',
            'Updated At',
            'Holiday Work',
            'Holiday Name',
          ]));

      final row = exportData.rows[0];
      expect(row[0], 'work');
      expect(row[1], '2024-01-15');
      expect(row[5], 480); // Span Minutes
      expect(row[6], 0); // Unpaid Break Minutes
      expect(row[7], 480); // Worked Minutes
      expect(row[8], '8.00'); // Worked Hours
      expect(row[11], 'Productive day'); // Entry Notes
    });

    test(
        'given 2 work entries + 2 travel entries same date: CSV row count equals expected',
        () {
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

      // 4 atomic rows + 1 totals row
      expect(exportData.rows.length, 5);

      // Verify worked minutes and unpaid break minutes in rows
      // Work entry 1: worked = 240 - 15 = 225, break = 15
      final workRows =
          exportData.rows.where((row) => row[0] == 'work').toList();
      final workRow1 = workRows[0];
      final workRow2 = workRows[1];
      // In combined export, travel placeholders (8) precede work columns
      expect(workRow1[14], 15); // Unpaid Break Minutes
      expect(workRow1[15], 225); // Worked Minutes

      // Work entry 2: worked = 240 - 30 = 210, break = 30
      expect(workRow2[14], 30); // Unpaid Break Minutes
      expect(workRow2[15], 210); // Worked Minutes
    });

    test(
        'given 2 work entries + 2 travel entries same date: XLSX row count equals expected',
        () {
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
      expect(exportData.rows.length, 5);

      // Spot-check worked_minutes and unpaid_break_minutes cells
      // Work entry 1: worked = 480 - 30 = 450, break = 30
      final workRows =
          exportData.rows.where((row) => row[0] == 'work').toList();
      final workRow1 = workRows[0];
      final workRow2 = workRows[1];
      expect(workRow1[14], 30); // Unpaid Break Minutes
      expect(workRow1[15], 450); // Worked Minutes

      // Work entry 2: worked = 240 - 15 = 225, break = 15
      expect(workRow2[14], 15); // Unpaid Break Minutes
      expect(workRow2[15], 225); // Worked Minutes
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
