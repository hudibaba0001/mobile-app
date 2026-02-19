import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/leave_minutes.dart';
import 'package:myapp/reporting/period_summary_calculator.dart';
import 'package:myapp/reporting/time_range.dart';
import 'package:myapp/reports/report_aggregator.dart';
import 'package:myapp/services/export_service.dart';
import 'package:myapp/services/xlsx_exporter.dart';

const _entryHeaders = <String>[
  'Type',
  'Date',
  'From',
  'To',
  'Travel Minutes',
  'Travel Distance (km)',
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
];

const _colType = 0;
const _colDate = 1;
const _colFrom = 2;
const _colTo = 3;
const _colTravelMinutes = 4;
const _colTravelDistanceKm = 5;
const _colShiftNumber = 6;
const _colShiftStart = 7;
const _colShiftEnd = 8;
const _colSpanMinutes = 9;
const _colUnpaidBreakMinutes = 10;
const _colWorkedMinutes = 11;
const _colWorkedHours = 12;
const _colShiftLocation = 13;
const _colShiftNotes = 14;
const _colEntryNotes = 15;
const _colCreatedAt = 16;
const _colUpdatedAt = 17;
const _colHolidayWork = 18;
const _colHolidayName = 19;

ReportExportLabels _testReportLabels() {
  return const ReportExportLabels(
    entriesSheetName: 'Report',
    summarySheetName: 'Summary (Easy)',
    balanceEventsSheetName: 'Balance Events',
    openingBalanceRow: 'Opening balance',
    timeAdjustmentRow: 'Manual adjustment',
    timeAdjustmentsTotalRow: 'Manual adjustments total',
    periodStartBalanceRow: 'Balance at period start',
    periodEndBalanceRow: 'Balance at period end',
    metricHeader: 'Metric',
    minutesHeader: 'Minutes',
    hoursHeader: 'Hours',
    periodRow: 'Period',
    quickReadRow: 'Quick read',
    totalLoggedTimeRow: 'Total logged time',
    paidLeaveRow: 'Paid leave',
    accountedTimeRow: 'Accounted time',
    plannedTimeRow: 'Planned time',
    differenceVsPlanRow: 'Difference vs plan',
    balanceAfterPeriodRow: 'Your balance after this period',
    trackedTotalsNote:
        'TOTAL (tracked only) excludes Leave and Balance events. See Summary (Easy).',
    colType: 'Type',
    colDate: 'Date',
    colMinutes: 'Minutes',
    colHours: 'Hours',
    colNote: 'Note',
  );
}

LeavesSummary _buildLeavesSummaryForTest(List<AbsenceEntry> absences) {
  final byType = <AbsenceType, LeaveTypeSummary>{
    for (final type in AbsenceType.values)
      type: const LeaveTypeSummary(
        entryCount: 0,
        fullDayCount: 0,
        totalMinutes: 0,
        totalDays: 0,
      ),
  };

  var totalMinutes = 0;
  var totalDays = 0.0;
  for (final absence in absences) {
    final minutes = normalizedLeaveMinutes(absence);
    final fullDay = absence.minutes == 0;
    final days = fullDay ? 1.0 : minutes / kDefaultFullLeaveDayMinutes;
    totalMinutes += minutes;
    totalDays += days;

    final current = byType[absence.type]!;
    byType[absence.type] = LeaveTypeSummary(
      entryCount: current.entryCount + 1,
      fullDayCount: current.fullDayCount + (fullDay ? 1 : 0),
      totalMinutes: current.totalMinutes + minutes,
      totalDays: current.totalDays + days,
    );
  }

  return LeavesSummary(
    absences: absences,
    byType: byType,
    totalEntries: absences.length,
    totalMinutes: totalMinutes,
    totalDays: totalDays,
  );
}

void main() {
  group('ExportService Tests', () {
    test('uses fixed column contract for empty export', () {
      final entries = <Entry>[];
      final exportData = ExportService.prepareExportData(entries);

      expect(exportData.headers, equals(_entryHeaders));
      expect(exportData.rows, hasLength(1)); // totals row
      expect(exportData.rows.first.length, _entryHeaders.length);
      expect(exportData.rows.first[_colType], 'TOTAL');
      expect(exportData.rows.first[_colTravelMinutes], 0);
      expect(exportData.rows.first[_colWorkedMinutes], 0);
    });

    test('maps travel row into fixed columns without shifting', () {
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
      final row = exportData.rows.first;

      expect(exportData.headers, equals(_entryHeaders));
      expect(row.length, _entryHeaders.length);
      expect(row[_colType], 'travel');
      expect(row[_colDate], '2024-01-15');
      expect(row[_colFrom], 'Home');
      expect(row[_colTo], 'Office');
      expect(row[_colTravelMinutes], 30);
      expect(row[_colTravelDistanceKm], 0.0);
      expect(row[_colShiftNumber], '');
      expect(row[_colWorkedMinutes], '');
      expect(row[_colEntryNotes], 'Morning commute');
      expect(row[_colCreatedAt], '2024-01-15T08:00:00');
      expect(row[_colUpdatedAt], '2024-01-15T08:00:00');
    });

    test('maps work row into fixed columns without shifting', () {
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
      final row = exportData.rows[0];

      expect(exportData.headers, equals(_entryHeaders));
      expect(row.length, _entryHeaders.length);
      expect(row[0], 'work');
      expect(row[1], '2024-01-15');
      expect(row[_colFrom], '');
      expect(row[_colTravelMinutes], '');
      expect(row[_colShiftNumber], 1);
      expect(row[_colShiftStart], '09:00');
      expect(row[_colShiftEnd], '17:00');
      expect(row[_colSpanMinutes], 480);
      expect(row[_colUnpaidBreakMinutes], 0);
      expect(row[_colWorkedMinutes], 480);
      expect(row[_colWorkedHours], '8.00');
      expect(row[_colShiftLocation], 'Office');
      expect(row[_colShiftNotes], '');
      expect(row[_colEntryNotes], 'Productive day');
      expect(row[_colHolidayWork], 'No');
      expect(row[_colHolidayName], '');
    });

    test(
        'mixed work/travel export keeps every row aligned with headers and totals',
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

      // 4 atomic rows + 1 separator row + 1 totals row
      expect(exportData.rows.length, 6);
      for (final row in exportData.rows) {
        expect(row.length, exportData.headers.length);
      }

      final workRows =
          exportData.rows.where((row) => row[0] == 'work').toList();
      final workRow1 = workRows[0];
      final workRow2 = workRows[1];
      expect(workRow1[_colTravelMinutes], '');
      expect(workRow1[_colUnpaidBreakMinutes], 15);
      expect(workRow1[_colWorkedMinutes], 225);

      expect(workRow2[_colUnpaidBreakMinutes], 30);
      expect(workRow2[_colWorkedMinutes], 210);

      final travelRows =
          exportData.rows.where((row) => row[0] == 'travel').toList();
      expect(travelRows[0][_colTravelMinutes], 30);
      expect(travelRows[0][_colWorkedMinutes], '');
      expect(travelRows[1][_colTravelMinutes], 25);

      final separator = exportData.rows[exportData.rows.length - 2];
      expect(separator.every((cell) => cell == ''), isTrue);

      final totals = exportData.rows.last;
      expect(totals[_colType], 'TOTAL');
      expect(totals[_colTravelMinutes], 55);
      expect(totals[_colWorkedMinutes], 435);
      expect(totals[_colWorkedHours], '7.25');
    });

    test('xlsx layout lock keeps work/travel/totals in fixed columns', () {
      final date = DateTime(2025, 2, 1);
      final workEntry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 2, 1, 9, 0),
          end: DateTime(2025, 2, 1, 17, 0),
          unpaidBreakMinutes: 30,
          location: 'HQ',
        ),
      );
      final travelEntry = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'A',
        to: 'B',
        minutes: 40,
      );

      final exportData =
          ExportService.prepareExportData([workEntry, travelEntry]);
      final bytes = XlsxExporter.export(exportData)!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel[excel.getDefaultSheet()!];

      expect(sheet.maxColumns, 20);
      String readCell(int columnIndex, int rowIndex) {
        final value = sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .value;
        return value?.toString() ?? '';
      }

      for (var i = 0; i < _entryHeaders.length; i++) {
        final headerCell = readCell(i, 0);
        expect(headerCell, _entryHeaders[i]);
      }

      final workRow = 1;
      final travelRow = 2;
      final totalsRow = 4;

      final workType = readCell(_colType, workRow);
      final workTravelMinutes = readCell(_colTravelMinutes, workRow);
      final workWorkedMinutes = readCell(_colWorkedMinutes, workRow);
      expect(workType, 'work');
      expect(workTravelMinutes, '');
      expect(workWorkedMinutes, '450');

      final travelType = readCell(_colType, travelRow);
      final travelTravelMinutes = readCell(_colTravelMinutes, travelRow);
      final travelWorkedMinutes = readCell(_colWorkedMinutes, travelRow);
      expect(travelType, 'travel');
      expect(travelTravelMinutes, '40');
      expect(travelWorkedMinutes, '');

      final totalsType = readCell(_colType, totalsRow);
      final totalsTravelMinutes = readCell(_colTravelMinutes, totalsRow);
      final totalsWorkedMinutes = readCell(_colWorkedMinutes, totalsRow);
      expect(totalsType, 'TOTAL');
      expect(totalsTravelMinutes, '40');
      expect(totalsWorkedMinutes, '450');
    });

    test(
        'report export summary matches PeriodSummaryCalculator and leave rows do not affect tracked totals',
        () {
      final rangeStart = DateTime(2026, 2, 1);
      final rangeEnd = DateTime(2026, 2, 28);
      final range = TimeRange.custom(rangeStart, rangeEnd);

      final entries = <Entry>[
        Entry.makeWorkAtomicFromShift(
          userId: 'user-1',
          date: DateTime(2026, 2, 10),
          shift: Shift(
            start: DateTime(2026, 2, 10, 8, 0),
            end: DateTime(2026, 2, 10, 16, 0),
          ),
        ),
        Entry.makeTravelAtomicFromLeg(
          userId: 'user-1',
          date: DateTime(2026, 2, 10),
          from: 'A',
          to: 'B',
          minutes: 60,
        ),
      ];

      final absences = <AbsenceEntry>[
        AbsenceEntry(
          date: DateTime(2026, 2, 11),
          minutes: 120,
          type: AbsenceType.sickPaid,
        ),
        AbsenceEntry(
          date: DateTime(2026, 2, 12),
          minutes: 60,
          type: AbsenceType.unpaid,
        ),
      ];

      final periodSummary = PeriodSummaryCalculator.compute(
        entries: entries,
        absences: absences,
        range: range,
        travelEnabled: true,
        weeklyTargetMinutes: 0,
        holidays: SwedenHolidayCalendar(),
        trackingStartDate: DateTime(2026, 1, 1),
        startBalanceMinutes: 30,
        manualAdjustmentMinutes: -15,
      );

      final reportSummary = ReportSummary(
        filteredEntries: entries,
        workMinutes: 480,
        travelMinutes: 60,
        totalTrackedMinutes: 540,
        workInsights: const WorkInsights(
          longestShift: null,
          averageWorkedMinutesPerDay: 0,
          totalBreakMinutes: 0,
          averageBreakMinutesPerShift: 0,
          shiftCount: 0,
          activeWorkDays: 0,
        ),
        travelInsights: const TravelInsights(
          tripCount: 0,
          averageMinutesPerTrip: 0,
          topRoutes: [],
        ),
        leavesSummary: _buildLeavesSummaryForTest(absences),
        balanceOffsets: BalanceOffsetSummary(
          openingEvent: BalanceOffsetEvent.opening(
            effectiveDate: DateTime(2026, 1, 1),
            minutes: 30,
          ),
          adjustmentsInRange: [
            BalanceOffsetEvent.adjustment(
              effectiveDate: DateTime(2026, 2, 20),
              minutes: -15,
            ),
          ],
          eventsBeforeStart: const [],
          eventsInRange: const [],
          startingBalanceMinutes: 30,
          closingBalanceMinutes: 15,
        ),
      );

      final sections = ExportService.prepareReportExportData(
        summary: reportSummary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: _testReportLabels(),
      );

      expect(sections, hasLength(3));
      expect(sections[0].sheetName, 'Report');
      expect(sections[1].sheetName, 'Summary (Easy)');
      expect(sections[2].sheetName, 'Balance Events');

      final reportRows = sections[0].rows;
      expect(reportRows.first[_colType], 'NOTE');
      expect(
        reportRows.first[_colEntryNotes],
        'TOTAL (tracked only) excludes Leave and Balance events. See Summary (Easy).',
      );

      final paidLeaveRows = reportRows
          .where((row) => row[_colType].toString().startsWith('Leave ('))
          .toList();
      expect(paidLeaveRows, hasLength(1));
      expect(paidLeaveRows.first[_colType], 'Leave (Sick)');
      expect(paidLeaveRows.first[_colSpanMinutes], 120);
      expect(paidLeaveRows.first[_colWorkedMinutes], '');

      final unpaidLeaveRows = reportRows
          .where((row) => row[_colType].toString() == 'Leave (Unpaid)')
          .toList();
      expect(unpaidLeaveRows, isEmpty);

      final totalsRow = reportRows.last;
      expect(totalsRow[_colType], 'TOTAL (tracked only)');
      expect(totalsRow[_colWorkedMinutes], 480);
      expect(totalsRow[_colTravelMinutes], 60);

      final summaryRows = sections[1].rows;
      final summaryByMetric = <String, List<dynamic>>{
        for (final row in summaryRows) row.first.toString(): row,
      };
      expect(
        summaryByMetric['Total logged time']?[1],
        periodSummary.trackedTotalMinutes,
      );
      expect(summaryByMetric['Paid leave']?[1], periodSummary.paidLeaveMinutes);
      expect(
        summaryByMetric['Accounted time']?[1],
        periodSummary.accountedMinutes,
      );
      expect(summaryByMetric['Planned time']?[1], periodSummary.targetMinutes);
      expect(
        summaryByMetric['Difference vs plan']?[1],
        periodSummary.differenceMinutes,
      );
      expect(
        summaryByMetric['Your balance after this period']?[1],
        periodSummary.endBalanceMinutes,
      );
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
