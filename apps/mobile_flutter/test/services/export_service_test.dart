import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/l10n/generated/app_localizations_en.dart';
import 'package:excel/excel.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/reporting/leave_minutes.dart';
import 'package:myapp/reporting/period_summary.dart';
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

AppLocalizations _testAppLocalizations() => AppLocalizationsEn();

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
      final exportData =
          ExportService.prepareExportData(entries, t: AppLocalizationsEn());

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

      final exportData =
          ExportService.prepareExportData(entries, t: AppLocalizationsEn());
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

      final exportData =
          ExportService.prepareExportData(entries, t: AppLocalizationsEn());
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
      final exportData =
          ExportService.prepareExportData(entries, t: AppLocalizationsEn());

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

      final exportData = ExportService.prepareExportData(
          [workEntry, travelEntry],
          t: AppLocalizationsEn());
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

      final labels = _testAppLocalizations();
      final sections = ExportService.prepareReportExportData(
        summary: reportSummary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        t: labels,
      );

      expect(sections, hasLength(3));
      expect(sections[0].sheetName, 'Entries');
      expect(sections[1].sheetName, 'Summary (Easy)');
      expect(sections[2].sheetName, 'Balance Events');

      final reportRows = sections[0].rows;
      expect(
        reportRows.where((row) => row[_colType].toString() == 'NOTE'),
        isEmpty,
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
        summaryByMetric[labels.exportSummary_totalTrackedOnly]?[1],
        periodSummary.trackedTotalMinutes,
      );
      expect(summaryByMetric[labels.exportSummary_paidLeaveCredit]?[1],
          periodSummary.paidLeaveMinutes);
      expect(
        summaryByMetric['Accounted']?[1],
        periodSummary.accountedMinutes,
      );
      expect(summaryByMetric['Planned']?[1], periodSummary.targetMinutes);
      expect(
        summaryByMetric['Difference']?[1],
        periodSummary.differenceMinutes,
      );
      expect(
        summaryByMetric[labels.exportSummary_balanceAfterThis]?[1],
        periodSummary.endBalanceMinutes,
      );
    });

    test(
        'xlsx report workbook keeps Report/Balance order and appends Sammanfattning',
        () {
      final labels = _testAppLocalizations();
      final rangeStart = DateTime(2026, 2, 1);
      final rangeEnd = DateTime(2026, 2, 19);
      final entries = <Entry>[
        Entry.makeWorkAtomicFromShift(
          userId: 'user-2',
          date: DateTime(2026, 2, 3),
          shift: Shift(
            start: DateTime(2026, 2, 3, 8, 0),
            end: DateTime(2026, 2, 3, 16, 0),
          ),
        ),
        Entry.makeTravelAtomicFromLeg(
          userId: 'user-2',
          date: DateTime(2026, 2, 3),
          from: 'Home',
          to: 'Site',
          minutes: 45,
        ),
      ];

      final reportSummary = ReportSummary(
        filteredEntries: entries,
        workMinutes: 480,
        travelMinutes: 45,
        totalTrackedMinutes: 525,
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
        leavesSummary: _buildLeavesSummaryForTest(const []),
        balanceOffsets: const BalanceOffsetSummary(
          openingEvent: null,
          adjustmentsInRange: [],
          eventsBeforeStart: [],
          eventsInRange: [],
          startingBalanceMinutes: 0,
          closingBalanceMinutes: 0,
        ),
      );

      final periodSummary = PeriodSummary.fromInputs(
        workMinutes: 6500,
        travelMinutes: 535,
        paidLeaveMinutes: 0,
        targetMinutes: 6720,
        startBalanceMinutes: 0,
        manualAdjustmentMinutes: 0,
      );

      final bytes = ExportService.buildReportSummaryWorkbookBytes(
        summary: reportSummary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        t: labels,
      );

      expect(bytes, isNotNull);
      final excel = Excel.decodeBytes(bytes!);
      expect(
        excel.tables.keys.toList(),
        equals(['Report', 'Balance Events', 'Sammanfattning']),
      );

      String readCell(Sheet sheet, int columnIndex, int rowIndex) {
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

      int findRowByFirstColumn(Sheet sheet, String target) {
        for (var rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
          if (readCell(sheet, 0, rowIndex) == target) {
            return rowIndex;
          }
        }
        return -1;
      }

      final summarySheet = excel['Sammanfattning'];
      expect(readCell(summarySheet, 2, 0), 'Hh Mm');

      final totalLoggedRow = findRowByFirstColumn(
          summarySheet, labels.exportSummary_totalTrackedOnly);
      expect(totalLoggedRow, greaterThanOrEqualTo(0));
      expect(readCell(summarySheet, 1, totalLoggedRow), '7035');
      expect(readCell(summarySheet, 2, totalLoggedRow), '117h 15m');

      final diffRow = findRowByFirstColumn(summarySheet, 'Difference');
      expect(diffRow, greaterThanOrEqualTo(0));
      expect(readCell(summarySheet, 1, diffRow), '315');
      expect(readCell(summarySheet, 2, diffRow), '+5h 15m');

      final balanceSheet = excel['Balance Events'];
      expect(readCell(balanceSheet, 3, 0), 'Hh Mm');
      final periodEndRow = findRowByFirstColumn(
          balanceSheet, labels.exportSummary_balanceAfterThis);
      expect(periodEndRow, greaterThanOrEqualTo(0));
      expect(readCell(balanceSheet, 3, periodEndRow), '+5h 15m');

      final reportSheet = excel['Report'];
      expect(readCell(reportSheet, 0, 3), 'Work');
      expect(readCell(reportSheet, 0, 4), 'Travel');
      for (var rowIndex = 0; rowIndex < reportSheet.maxRows; rowIndex++) {
        final type = readCell(reportSheet, 0, rowIndex);
        expect(type == 'work' || type == 'travel', isFalse);
      }
    });

    test(
      'xlsx summary uses effective tracking range metadata and keeps minute parity',
      () {
        final labels = _testAppLocalizations();
        final selectedStart = DateTime(2026, 1, 1);
        final selectedEnd = DateTime(2026, 1, 31);
        final selectedRange = TimeRange.custom(selectedStart, selectedEnd);
        final trackingStartDate = DateTime(2026, 1, 10);
        final effectiveStart = DateTime(2026, 1, 10);

        final entries = <Entry>[
          Entry.makeWorkAtomicFromShift(
            userId: 'user-3',
            date: DateTime(2026, 1, 5),
            shift: Shift(
              start: DateTime(2026, 1, 5, 8, 0),
              end: DateTime(2026, 1, 5, 10, 0),
            ),
          ),
          Entry.makeWorkAtomicFromShift(
            userId: 'user-3',
            date: DateTime(2026, 1, 12),
            shift: Shift(
              start: DateTime(2026, 1, 12, 8, 0),
              end: DateTime(2026, 1, 12, 13, 15),
            ),
          ),
        ];
        final absences = <AbsenceEntry>[
          AbsenceEntry(
            date: DateTime(2026, 1, 8),
            minutes: 120,
            type: AbsenceType.sickPaid,
          ),
          AbsenceEntry(
            date: DateTime(2026, 1, 20),
            minutes: 60,
            type: AbsenceType.vabPaid,
          ),
        ];

        final periodSummary = PeriodSummaryCalculator.compute(
          entries: entries,
          absences: absences,
          range: selectedRange,
          travelEnabled: true,
          weeklyTargetMinutes: 0,
          holidays: SwedenHolidayCalendar(),
          trackingStartDate: trackingStartDate,
          startBalanceMinutes: 0,
          manualAdjustmentMinutes: 0,
        );

        final reportSummary = ReportSummary(
          filteredEntries: entries,
          workMinutes: 435,
          travelMinutes: 0,
          totalTrackedMinutes: 435,
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
          balanceOffsets: const BalanceOffsetSummary(
            openingEvent: null,
            adjustmentsInRange: [],
            eventsBeforeStart: [],
            eventsInRange: [],
            startingBalanceMinutes: 0,
            closingBalanceMinutes: 0,
          ),
        );

        final bytes = ExportService.buildReportSummaryWorkbookBytes(
          summary: reportSummary,
          periodSummary: periodSummary,
          rangeStart: selectedStart,
          rangeEnd: selectedEnd,
          t: labels,
          trackingStartDate: trackingStartDate,
          effectiveRangeStart: effectiveStart,
        );

        expect(bytes, isNotNull);
        final excel = Excel.decodeBytes(bytes!);
        final summarySheet = excel['Sammanfattning'];
        final balanceSheet = excel['Balance Events'];

        String readCell(Sheet sheet, int columnIndex, int rowIndex) {
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

        int findRowByFirstColumn(Sheet sheet, String target) {
          for (var rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
            if (readCell(sheet, 0, rowIndex) == target) {
              return rowIndex;
            }
          }
          return -1;
        }

        expect(
          readCell(summarySheet, 0, 0),
          'Report period: 2026-01-01 → 2026-01-31',
        );
        expect(
          readCell(summarySheet, 0, 1),
          'Calculated from: 2026-01-10 → 2026-01-31',
        );
        expect(readCell(summarySheet, 2, 3), 'Hh Mm');

        final totalLoggedRow = findRowByFirstColumn(
            summarySheet, labels.exportSummary_totalTrackedOnly);
        expect(totalLoggedRow, greaterThanOrEqualTo(0));
        expect(
          readCell(summarySheet, 1, totalLoggedRow),
          periodSummary.trackedTotalMinutes.toString(),
        );
        expect(
          readCell(summarySheet, 2, totalLoggedRow),
          '5h 15m',
        );

        expect(
          readCell(balanceSheet, 0, 0),
          'Baseline date: 2026-01-10',
        );
      },
    );

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

  group('Travel minimal export', () {
    test('produces 5-column headers and TOTAL row', () {
      final date = DateTime(2026, 2, 10);
      final entries = [
        Entry.makeTravelAtomicFromLeg(
          userId: 'u1',
          date: date,
          from: 'Home',
          to: 'Office',
          minutes: 30,
        ),
        Entry.makeTravelAtomicFromLeg(
          userId: 'u1',
          date: date,
          from: 'Office',
          to: 'Client',
          minutes: 45,
        ),
        // Work entry should be excluded
        Entry.makeWorkAtomicFromShift(
          userId: 'u1',
          date: date,
          shift: Shift(
            start: DateTime(2026, 2, 10, 8, 0),
            end: DateTime(2026, 2, 10, 16, 0),
          ),
        ),
      ];

      final exportData = ExportService.prepareTravelMinimalExportData(
          entries, AppLocalizationsEn());

      expect(exportData.headers, [
        'Type',
        'Date',
        'From',
        'To',
        'Travel Minutes',
      ]);
      // 2 travel rows + 1 TOTAL
      expect(exportData.rows, hasLength(3));
      for (final row in exportData.rows) {
        expect(row.length, 5);
      }

      // TOTAL row
      final totalRow = exportData.rows.last;
      expect(totalRow[0], 'TOTAL');
      expect(totalRow[4], 75); // 30 + 45
    });

    test('expands travel legs into separate rows', () {
      final date = DateTime(2026, 3, 1);
      final entry = Entry(
        userId: 'u1',
        type: EntryType.travel,
        date: date,
        travelLegs: [
          TravelLeg(fromText: 'A', toText: 'B', minutes: 20),
          TravelLeg(fromText: 'B', toText: 'C', minutes: 35),
        ],
        createdAt: date,
      );

      final exportData = ExportService.prepareTravelMinimalExportData(
          [entry], AppLocalizationsEn());

      // 2 leg rows + 1 TOTAL
      expect(exportData.rows, hasLength(3));
      expect(exportData.rows[0][0], 'travel');
      expect(exportData.rows[0][2], 'A');
      expect(exportData.rows[0][3], 'B');
      expect(exportData.rows[0][4], 20);
      expect(exportData.rows[1][0], 'travel');
      expect(exportData.rows[1][2], 'B');
      expect(exportData.rows[1][3], 'C');
      expect(exportData.rows[1][4], 35);

      final totalRow = exportData.rows.last;
      expect(totalRow[0], 'TOTAL');
      expect(totalRow[4], 55);
    });

    test('empty travel entries produce only TOTAL row', () {
      final exportData = ExportService.prepareTravelMinimalExportData(
          <Entry>[], AppLocalizationsEn());

      expect(exportData.headers, hasLength(5));
      expect(exportData.rows, hasLength(1));
      expect(exportData.rows.first[0], 'TOTAL');
      expect(exportData.rows.first[4], 0);
    });
  });

  group('Leave minimal export', () {
    test('produces 4-column headers and TOTAL row', () {
      final absences = <AbsenceEntry>[
        AbsenceEntry(
          date: DateTime(2026, 2, 5),
          minutes: 0, // full day = 480
          type: AbsenceType.vacationPaid,
        ),
        AbsenceEntry(
          date: DateTime(2026, 2, 10),
          minutes: 240,
          type: AbsenceType.sickPaid,
        ),
        AbsenceEntry(
          date: DateTime(2026, 2, 15),
          minutes: 480,
          type: AbsenceType.unpaid,
        ),
      ];

      final exportData = ExportService.prepareLeaveMinimalExportData(
          absences, AppLocalizationsEn());

      expect(exportData.headers, [
        'Date',
        'Type',
        'Minutes',
        'Paid/Unpaid',
      ]);
      // 3 absence rows + 1 TOTAL
      expect(exportData.rows, hasLength(4));
      for (final row in exportData.rows) {
        expect(row.length, 4);
      }

      // First row: vacation full day normalized to 480
      expect(exportData.rows[0][0], '2026-02-05');
      expect(exportData.rows[0][2], 480);
      expect(exportData.rows[0][3], 'Paid');

      // Second row: sick 240 min
      expect(exportData.rows[1][2], 240);
      expect(exportData.rows[1][3], 'Paid');

      // Third row: unpaid 480 min
      expect(exportData.rows[2][2], 480);
      expect(exportData.rows[2][3], 'Unpaid');

      // TOTAL row
      final totalRow = exportData.rows.last;
      expect(totalRow[0], 'TOTAL');
      expect(totalRow[2], 1200); // 480 + 240 + 480
    });

    test('sorts absences by date', () {
      final absences = <AbsenceEntry>[
        AbsenceEntry(
          date: DateTime(2026, 3, 20),
          minutes: 60,
          type: AbsenceType.sickPaid,
        ),
        AbsenceEntry(
          date: DateTime(2026, 3, 5),
          minutes: 120,
          type: AbsenceType.vabPaid,
        ),
      ];

      final exportData = ExportService.prepareLeaveMinimalExportData(
          absences, AppLocalizationsEn());

      // Sorted: Mar 5 before Mar 20
      expect(exportData.rows[0][0], '2026-03-05');
      expect(exportData.rows[1][0], '2026-03-20');
    });

    test('empty absences produce only TOTAL row', () {
      final exportData = ExportService.prepareLeaveMinimalExportData(
          <AbsenceEntry>[], AppLocalizationsEn());

      expect(exportData.headers, hasLength(4));
      expect(exportData.rows, hasLength(1));
      expect(exportData.rows.first[0], 'TOTAL');
      expect(exportData.rows.first[2], 0);
    });
  });
}
