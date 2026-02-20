import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import '../models/absence.dart';
import '../models/entry.dart';
import '../models/export_data.dart';
import '../reporting/leave_minutes.dart';
import '../reporting/period_summary.dart';
import '../reporting/time_format.dart';
import '../reports/report_aggregator.dart';
import 'csv_exporter.dart';
import 'xlsx_exporter.dart';

// Web-specific imports (conditional)
import 'dart:convert' show utf8;

// Conditional import for web download functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart'
    as web_download;

class ReportExportLabels {
  final String entriesSheetName;
  final String summarySheetName;
  final String balanceEventsSheetName;
  final String openingBalanceRow;
  final String timeAdjustmentRow;
  final String timeAdjustmentsTotalRow;
  final String periodStartBalanceRow;
  final String periodEndBalanceRow;
  final String metricHeader;
  final String minutesHeader;
  final String hoursHeader;
  final String periodRow;
  final String quickReadRow;
  final String totalLoggedTimeRow;
  final String paidLeaveRow;
  final String accountedTimeRow;
  final String plannedTimeRow;
  final String differenceVsPlanRow;
  final String balanceAfterPeriodRow;
  final String trackedTotalsNote;
  final String colType;
  final String colDate;
  final String colMinutes;
  final String colHours;
  final String colNote;

  const ReportExportLabels({
    required this.entriesSheetName,
    required this.summarySheetName,
    required this.balanceEventsSheetName,
    required this.openingBalanceRow,
    required this.timeAdjustmentRow,
    required this.timeAdjustmentsTotalRow,
    required this.periodStartBalanceRow,
    required this.periodEndBalanceRow,
    required this.metricHeader,
    required this.minutesHeader,
    required this.hoursHeader,
    required this.periodRow,
    required this.quickReadRow,
    required this.totalLoggedTimeRow,
    required this.paidLeaveRow,
    required this.accountedTimeRow,
    required this.plannedTimeRow,
    required this.differenceVsPlanRow,
    required this.balanceAfterPeriodRow,
    required this.trackedTotalsNote,
    required this.colType,
    required this.colDate,
    required this.colMinutes,
    required this.colHours,
    required this.colNote,
  });
}

class ExportService {
  static const String _fileNamePrefix = 'time_tracker_export';
  static const String _csvFileExtension = '.csv';
  static const String _excelFileExtension = '.xlsx';
  static const MethodChannel _downloadsChannel =
      MethodChannel('se.kviktime.app/file_export');

  // Fixed entry export column contract (order must never change without
  // coordinated migration of readers/tests).
  static const List<String> _entryExportHeaders = [
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

  static const int _colType = 0;
  static const int _colDate = 1;
  static const int _colFrom = 2;
  static const int _colTo = 3;
  static const int _colTravelMinutes = 4;
  static const int _colTravelDistanceKm = 5;
  static const int _colShiftNumber = 6;
  static const int _colShiftStart = 7;
  static const int _colShiftEnd = 8;
  static const int _colSpanMinutes = 9;
  static const int _colUnpaidBreakMinutes = 10;
  static const int _colWorkedMinutes = 11;
  static const int _colWorkedHours = 12;
  static const int _colShiftLocation = 13;
  static const int _colShiftNotes = 14;
  static const int _colEntryNotes = 15;
  static const int _colCreatedAt = 16;
  static const int _colUpdatedAt = 17;
  static const int _colHolidayWork = 18;
  static const int _colHolidayName = 19;
  static const String _hhMmHeader = 'Hh Mm';
  static const String _payrollNoteTitle = 'Payroll note';

  static ExportData prepareExportData(
    List<Entry> entries, {
    ReportSummary? summary,
  }) {
    int calculatedTravelMinutes = 0;
    double totalTravelDistanceKm = 0.0;
    int calculatedWorkedMinutes = 0;

    final rows = <List<dynamic>>[];

    for (final entry in entries) {
      if (entry.type == EntryType.travel) {
        // Travel entry: one row per leg (prefer travelLegs, fallback to legacy)
        if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
          final legs = entry.travelLegs!;
          for (var i = 0; i < legs.length; i++) {
            final leg = legs[i];
            final row = _newEntryExportRow(entry);
            row[_colFrom] = leg.fromText;
            row[_colTo] = leg.toText;
            row[_colTravelMinutes] = leg.minutes;
            row[_colTravelDistanceKm] = leg.distanceKm ?? 0.0;
            rows.add(_normalizeEntryExportRow(row));
            calculatedTravelMinutes += leg.minutes;
            totalTravelDistanceKm += (leg.distanceKm ?? 0.0);
          }
        } else {
          // Legacy single travel entry: one row
          final row = _newEntryExportRow(entry);
          row[_colFrom] = entry.from ?? '';
          row[_colTo] = entry.to ?? '';
          row[_colTravelMinutes] = entry.travelMinutes ?? 0;
          row[_colTravelDistanceKm] = 0.0;
          rows.add(_normalizeEntryExportRow(row));
          calculatedTravelMinutes += entry.travelMinutes ?? 0;
        }
      } else if (entry.type == EntryType.work &&
          entry.shifts != null &&
          entry.shifts!.isNotEmpty) {
        // Work entry: one row per shift
        for (var i = 0; i < entry.shifts!.length; i++) {
          final shift = entry.shifts![i];
          final spanMinutes = shift.duration.inMinutes;
          final breakMinutes = shift.unpaidBreakMinutes;
          final workedMinutes = shift.workedMinutes;
          final workedHours = workedMinutes / 60.0;

          final row = _newEntryExportRow(entry);
          row[_colShiftNumber] = i + 1;
          row[_colShiftStart] = DateFormat('HH:mm').format(shift.start);
          row[_colShiftEnd] = DateFormat('HH:mm').format(shift.end);
          row[_colSpanMinutes] = spanMinutes;
          row[_colUnpaidBreakMinutes] = breakMinutes;
          row[_colWorkedMinutes] = workedMinutes;
          row[_colWorkedHours] = workedHours.toStringAsFixed(2);
          row[_colShiftLocation] = shift.location ?? '';
          row[_colShiftNotes] = shift.notes ?? '';
          rows.add(_normalizeEntryExportRow(row));
          calculatedWorkedMinutes += workedMinutes;
        }
      } else {
        // Work entry with no shifts: one row with empty shift data
        rows.add(_normalizeEntryExportRow(_newEntryExportRow(entry)));
        // Without shifts we can't infer worked minutes; leave total unchanged
      }
    }

    final totalTravelMinutes =
        summary?.travelMinutes ?? calculatedTravelMinutes;
    final totalWorkedMinutes = summary?.workMinutes ?? calculatedWorkedMinutes;

    // Add a blank separator before totals for readability.
    if (rows.isNotEmpty) {
      rows.add(List<dynamic>.filled(_entryExportHeaders.length, ''));
    }

    // Append summary row with totals in fixed columns.
    final summaryRow = List<dynamic>.filled(_entryExportHeaders.length, '');
    summaryRow[_colType] = 'TOTAL';
    summaryRow[_colTravelMinutes] = totalTravelMinutes;
    summaryRow[_colTravelDistanceKm] =
        double.parse(totalTravelDistanceKm.toStringAsFixed(2));
    summaryRow[_colWorkedMinutes] = totalWorkedMinutes;
    summaryRow[_colWorkedHours] = (totalWorkedMinutes / 60).toStringAsFixed(2);
    summaryRow[_colEntryNotes] = 'TOTAL';
    rows.add(_normalizeEntryExportRow(summaryRow));

    return ExportData(
      sheetName: 'Poster',
      headers: List<String>.from(_entryExportHeaders),
      rows: rows,
    );
  }

  static List<dynamic> _newEntryExportRow(Entry entry) {
    final row = List<dynamic>.filled(_entryExportHeaders.length, '');
    row[_colType] = entry.type.name;
    row[_colDate] = DateFormat('yyyy-MM-dd').format(entry.date);
    row[_colEntryNotes] = entry.notes ?? '';
    row[_colCreatedAt] = _formatIsoDateTime(entry.createdAt);
    row[_colUpdatedAt] =
        entry.updatedAt != null ? _formatIsoDateTime(entry.updatedAt!) : '';
    row[_colHolidayWork] = entry.isHolidayWork ? 'Yes' : 'No';
    row[_colHolidayName] = entry.holidayName ?? '';
    return row;
  }

  static List<dynamic> _normalizeEntryExportRow(List<dynamic> row) {
    if (row.length == _entryExportHeaders.length) return row;
    if (row.length < _entryExportHeaders.length) {
      return [
        ...row,
        ...List<dynamic>.filled(_entryExportHeaders.length - row.length, ''),
      ];
    }
    return row.sublist(0, _entryExportHeaders.length);
  }

  static String _formatIsoDateTime(DateTime value) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(value);
  }

  static bool _isEntryExportBlankRow(List<dynamic> row) {
    return row.every((cell) => cell.toString().isEmpty);
  }

  static bool _isEntryExportTotalsRow(List<dynamic> row) {
    return row.length > _colType &&
        row[_colType].toString().trim().toUpperCase() == 'TOTAL';
  }

  static String _leaveTypeForExport(AbsenceType type) {
    switch (type) {
      case AbsenceType.sickPaid:
        return 'Leave (Sick)';
      case AbsenceType.vabPaid:
        return 'Leave (VAB)';
      case AbsenceType.vacationPaid:
        return 'Leave (Paid Vacation)';
      case AbsenceType.unpaid:
        return 'Leave (Unpaid)';
    }
  }

  static String _formatUnsignedHours(int minutes) {
    final hours = minutes / 60.0;
    return hours.toStringAsFixed(2);
  }

  static String _formatEntryTypeForReport(
    String rawType, {
    required bool titleCaseType,
  }) {
    if (!titleCaseType) {
      return rawType;
    }

    final normalized = rawType.trim().toLowerCase();
    if (normalized == EntryType.work.name) {
      return 'Work';
    }
    if (normalized == EntryType.travel.name) {
      return 'Travel';
    }
    return rawType;
  }

  static ExportData _prepareReportEntriesExportData({
    required ReportSummary summary,
    required String sheetName,
    bool titleCaseType = false,
  }) {
    final base = prepareExportData(
      summary.filteredEntries,
      summary: summary,
    );
    final rows = <List<dynamic>>[];
    var trackedTravelDistanceKm = 0.0;

    for (final sourceRow in base.rows) {
      final row = List<dynamic>.from(sourceRow);
      if (_isEntryExportTotalsRow(row)) {
        final value = row[_colTravelDistanceKm];
        if (value is num) {
          trackedTravelDistanceKm = value.toDouble();
        } else {
          trackedTravelDistanceKm = double.tryParse(value.toString()) ?? 0.0;
        }
        continue;
      }
      if (_isEntryExportBlankRow(row)) {
        continue;
      }
      row[_colType] = _formatEntryTypeForReport(
        row[_colType].toString(),
        titleCaseType: titleCaseType,
      );
      rows.add(row);
    }

    final paidLeaves = summary.leavesSummary.absences
        .where((absence) => absence.isPaid)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final leave in paidLeaves) {
      final leaveMinutes = normalizedLeaveMinutes(leave);
      final row = List<dynamic>.filled(_entryExportHeaders.length, '');
      row[_colType] = _leaveTypeForExport(leave.type);
      row[_colDate] = DateFormat('yyyy-MM-dd').format(leave.date);
      row[_colSpanMinutes] = leaveMinutes;
      row[_colEntryNotes] =
          'Paid leave credit: ${_formatUnsignedHours(leaveMinutes)}h (not worked)';
      row[_colHolidayWork] = 'No';
      rows.add(_normalizeEntryExportRow(row));
    }

    if (rows.isNotEmpty) {
      rows.add(List<dynamic>.filled(_entryExportHeaders.length, ''));
    }

    final totalsRow = List<dynamic>.filled(_entryExportHeaders.length, '');
    totalsRow[_colType] = 'TOTAL (tracked only)';
    totalsRow[_colTravelMinutes] = summary.travelMinutes;
    totalsRow[_colTravelDistanceKm] =
        double.parse(trackedTravelDistanceKm.toStringAsFixed(2));
    totalsRow[_colWorkedMinutes] = summary.workMinutes;
    totalsRow[_colWorkedHours] = _formatUnsignedHours(summary.workMinutes);
    totalsRow[_colEntryNotes] = 'TOTAL (tracked only)';
    rows.add(_normalizeEntryExportRow(totalsRow));

    return ExportData(
      sheetName: sheetName,
      headers: List<String>.from(_entryExportHeaders),
      rows: rows,
    );
  }

  static ExportData _prepareSummarySheet({
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    String? sheetNameOverride,
    bool useHhMm = false,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final summaryRows = <List<dynamic>>[
      [
        labels.periodRow,
        '${dateFormat.format(rangeStart)} - ${dateFormat.format(rangeEnd)}',
        '',
      ],
      [
        labels.totalLoggedTimeRow,
        periodSummary.trackedTotalMinutes,
        useHhMm
            ? formatMinutes(periodSummary.trackedTotalMinutes)
            : _formatUnsignedHours(periodSummary.trackedTotalMinutes),
      ],
      [
        labels.paidLeaveRow,
        periodSummary.paidLeaveMinutes,
        useHhMm
            ? formatMinutes(periodSummary.paidLeaveMinutes)
            : _formatUnsignedHours(periodSummary.paidLeaveMinutes),
      ],
      [
        labels.accountedTimeRow,
        periodSummary.accountedMinutes,
        useHhMm
            ? formatMinutes(periodSummary.accountedMinutes)
            : _formatUnsignedHours(periodSummary.accountedMinutes),
      ],
      [
        labels.plannedTimeRow,
        periodSummary.targetMinutes,
        useHhMm
            ? formatMinutes(periodSummary.targetMinutes)
            : _formatUnsignedHours(periodSummary.targetMinutes),
      ],
      [
        labels.differenceVsPlanRow,
        periodSummary.differenceMinutes,
        useHhMm
            ? formatMinutes(periodSummary.differenceMinutes, signed: true)
            : _formatSignedHours(periodSummary.differenceMinutes),
      ],
      [
        labels.balanceAfterPeriodRow,
        periodSummary.endBalanceMinutes,
        useHhMm
            ? formatMinutes(periodSummary.endBalanceMinutes, signed: true)
            : _formatSignedHours(periodSummary.endBalanceMinutes),
      ],
    ];

    return ExportData(
      sheetName: sheetNameOverride ?? labels.summarySheetName,
      headers: [
        labels.metricHeader,
        labels.minutesHeader,
        useHhMm ? _hhMmHeader : labels.hoursHeader,
      ],
      rows: summaryRows,
    );
  }

  static ExportData _prepareBalanceEventsSheet({
    required ReportSummary summary,
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    String? sheetNameOverride,
    bool useHhMm = false,
    bool fillFriendlyNotes = false,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final adjustmentRows = <List<dynamic>>[];
    final opening = summary.balanceOffsets.openingEvent;
    if (opening != null) {
      final openingNote = fillFriendlyNotes ? 'Carry-over from earlier' : '';
      adjustmentRows.add([
        labels.openingBalanceRow,
        dateFormat.format(opening.effectiveDate),
        opening.minutes,
        useHhMm
            ? formatMinutes(opening.minutes, signed: true)
            : _formatSignedHours(opening.minutes),
        openingNote,
      ]);
    }

    for (final adjustment in summary.balanceOffsets.adjustmentsInRange) {
      adjustmentRows.add([
        labels.timeAdjustmentRow,
        dateFormat.format(adjustment.effectiveDate),
        adjustment.minutes,
        useHhMm
            ? formatMinutes(adjustment.minutes, signed: true)
            : _formatSignedHours(adjustment.minutes),
        adjustment.note ?? '',
      ]);
    }

    final adjustmentsTotalNote =
        fillFriendlyNotes ? 'Manual corrections in this period' : '';
    adjustmentRows.add([
      labels.timeAdjustmentsTotalRow,
      '',
      periodSummary.manualAdjustmentMinutes,
      useHhMm
          ? formatMinutes(periodSummary.manualAdjustmentMinutes, signed: true)
          : _formatSignedHours(periodSummary.manualAdjustmentMinutes),
      adjustmentsTotalNote,
    ]);
    final startBalanceNote =
        fillFriendlyNotes ? 'Balance at start of selected period' : '';
    adjustmentRows.add([
      labels.periodStartBalanceRow,
      dateFormat.format(rangeStart),
      periodSummary.startBalanceMinutes,
      useHhMm
          ? formatMinutes(periodSummary.startBalanceMinutes, signed: true)
          : _formatSignedHours(periodSummary.startBalanceMinutes),
      startBalanceNote,
    ]);
    final endBalanceNote = fillFriendlyNotes ? 'Balance after this period' : '';
    adjustmentRows.add([
      labels.periodEndBalanceRow,
      dateFormat.format(rangeEnd),
      periodSummary.endBalanceMinutes,
      useHhMm
          ? formatMinutes(periodSummary.endBalanceMinutes, signed: true)
          : _formatSignedHours(periodSummary.endBalanceMinutes),
      endBalanceNote,
    ]);

    return ExportData(
      sheetName: sheetNameOverride ?? labels.balanceEventsSheetName,
      headers: [
        labels.colType,
        labels.colDate,
        labels.colMinutes,
        useHhMm ? _hhMmHeader : labels.colHours,
        labels.colNote,
      ],
      rows: adjustmentRows,
    );
  }

  static List<ExportData> prepareReportExportData({
    required ReportSummary summary,
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    bool forXlsxPresentation = false,
  }) {
    final entriesSheetName =
        forXlsxPresentation ? 'Report' : labels.entriesSheetName;
    final summarySheetName =
        forXlsxPresentation ? 'Summary (Easy)' : labels.summarySheetName;
    final balanceEventsSheetName =
        forXlsxPresentation ? 'Balance Events' : labels.balanceEventsSheetName;

    final entriesSheet = _prepareReportEntriesExportData(
      summary: summary,
      sheetName: entriesSheetName,
      titleCaseType: forXlsxPresentation,
    );
    final summarySheet = _prepareSummarySheet(
      periodSummary: periodSummary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      labels: labels,
      sheetNameOverride: summarySheetName,
      useHhMm: forXlsxPresentation,
    );
    final balanceEventsSheet = _prepareBalanceEventsSheet(
      summary: summary,
      periodSummary: periodSummary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      labels: labels,
      sheetNameOverride: balanceEventsSheetName,
      useHhMm: forXlsxPresentation,
      fillFriendlyNotes: forXlsxPresentation,
    );

    return [entriesSheet, summarySheet, balanceEventsSheet];
  }

  @visibleForTesting
  static List<int>? buildReportSummaryWorkbookBytes({
    required ReportSummary summary,
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    DateTime? trackingStartDate,
    DateTime? effectiveRangeStart,
  }) {
    final sections = prepareReportExportData(
      summary: summary,
      periodSummary: periodSummary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      labels: labels,
      forXlsxPresentation: true,
    );
    return _buildStyledReportWorkbook(
      sections: sections,
      labels: labels,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      effectiveRangeStart: effectiveRangeStart,
      trackingStartDate: trackingStartDate,
    );
  }

  static List<int>? _buildStyledReportWorkbook({
    required List<ExportData> sections,
    required ReportExportLabels labels,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime? effectiveRangeStart,
    DateTime? trackingStartDate,
  }) {
    final excel = Excel.createExcel();
    if (sections.isEmpty) {
      return excel.save();
    }

    final defaultSheet = excel.getDefaultSheet()!;
    final safeSheetNames = <String>[];

    for (var i = 0; i < sections.length; i++) {
      final safeName = _safeSheetName(sections[i].sheetName, i);
      safeSheetNames.add(safeName);
      if (i == 0 && safeName != defaultSheet) {
        excel.rename(defaultSheet, safeName);
      } else if (i > 0) {
        excel[safeName];
      }
    }

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sheet = excel[safeSheetNames[i]];
      if (i == 0) {
        _writeStyledReportSheet(
          sheet: sheet,
          section: section,
        );
      } else if (i == 1) {
        _writeStyledSummarySheet(
          sheet: sheet,
          section: section,
          labels: labels,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          effectiveRangeStart: effectiveRangeStart,
        );
      } else if (i == 2) {
        _writeStyledBalanceEventsSheet(
          sheet: sheet,
          section: section,
          trackingStartDate: trackingStartDate,
        );
      } else {
        _writeSimpleSheet(sheet: sheet, section: section);
      }
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

  static void _writeSimpleSheet({
    required Sheet sheet,
    required ExportData section,
  }) {
    _writeRow(sheet: sheet, rowIndex: 0, row: section.headers);
    for (var i = 0; i < section.rows.length; i++) {
      _writeRow(sheet: sheet, rowIndex: i + 1, row: section.rows[i]);
    }
  }

  static void _writeStyledReportSheet({
    required Sheet sheet,
    required ExportData section,
  }) {
    final titleStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.lightBlue100,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final noteStyle = CellStyle(
      backgroundColorHex: ExcelColor.lightBlue50,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    final totalsStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey100,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final payrollNote =
        'Work/Travel = logged time. Leave rows = credited leave (not worked). '
        'TOTAL (tracked only) excludes Leave and Balance events. See Summary (Easy).';

    final startTitle = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);
    final endTitle = CellIndex.indexByColumnRow(
      columnIndex: _entryExportHeaders.length - 1,
      rowIndex: 0,
    );
    sheet.merge(startTitle, endTitle);
    final titleCell = sheet.cell(startTitle);
    titleCell.value = TextCellValue(_payrollNoteTitle);
    titleCell.cellStyle = titleStyle;
    sheet.setMergedCellStyle(startTitle, titleStyle);

    final startNote = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1);
    final endNote = CellIndex.indexByColumnRow(
      columnIndex: _entryExportHeaders.length - 1,
      rowIndex: 1,
    );
    sheet.merge(startNote, endNote);
    final noteCell = sheet.cell(startNote);
    noteCell.value = TextCellValue(payrollNote);
    noteCell.cellStyle = noteStyle;
    sheet.setMergedCellStyle(startNote, noteStyle);

    _writeRow(sheet: sheet, rowIndex: 2, row: section.headers);
    for (var col = 0; col < section.headers.length; col++) {
      final headerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2),
      );
      headerCell.cellStyle = headerStyle;
    }

    for (var i = 0; i < section.rows.length; i++) {
      final rowIndex = i + 3;
      final row = section.rows[i];
      _writeRow(sheet: sheet, rowIndex: rowIndex, row: row);
      final isTotalRow =
          row.length > _colType && row[_colType] == 'TOTAL (tracked only)';
      if (!isTotalRow) {
        continue;
      }
      for (var col = 0; col < _entryExportHeaders.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );
        cell.cellStyle = totalsStyle;
      }
    }

    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(9, 14);
    sheet.setColumnWidth(10, 18);
    sheet.setColumnWidth(11, 14);
    sheet.setColumnWidth(12, 12);
    sheet.setColumnWidth(15, 48);
  }

  static void _writeStyledSummarySheet({
    required Sheet sheet,
    required ExportData section,
    required ReportExportLabels labels,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime? effectiveRangeStart,
  }) {
    var headerRowIndex = 0;

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    final metadataStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.lightBlue50,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    final highlightStyle = CellStyle(
      backgroundColorHex: ExcelColor.yellow100,
      verticalAlign: VerticalAlign.Center,
    );
    final positiveStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.green100,
      verticalAlign: VerticalAlign.Center,
    );
    final negativeStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.red100,
      verticalAlign: VerticalAlign.Center,
    );
    final quickReadTitleStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.lightBlue100,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final quickReadItemStyle = CellStyle(
      backgroundColorHex: ExcelColor.lightBlue50,
      verticalAlign: VerticalAlign.Center,
    );

    if (rangeStart != null && rangeEnd != null && effectiveRangeStart != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final selectedStart = rangeStart;
      final selectedEnd = rangeEnd;
      final effectiveStartValue = effectiveRangeStart;
      final reportPeriodRow =
          'Report period: ${dateFormat.format(selectedStart)} -> ${dateFormat.format(selectedEnd)}';
      final effectiveRangeRow =
          'Calculated from: ${dateFormat.format(effectiveStartValue)} -> ${dateFormat.format(selectedEnd)}';

      final metadataStartRow = 0;
      final metadataEndColumn = section.headers.length - 1;

      final periodStart = CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: metadataStartRow,
      );
      final periodEnd = CellIndex.indexByColumnRow(
        columnIndex: metadataEndColumn,
        rowIndex: metadataStartRow,
      );
      sheet.merge(periodStart, periodEnd);
      final periodCell = sheet.cell(periodStart);
      periodCell.value = TextCellValue(reportPeriodRow);
      periodCell.cellStyle = metadataStyle;
      sheet.setMergedCellStyle(periodStart, metadataStyle);

      final effectiveStart = CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: metadataStartRow + 1,
      );
      final effectiveEnd = CellIndex.indexByColumnRow(
        columnIndex: metadataEndColumn,
        rowIndex: metadataStartRow + 1,
      );
      sheet.merge(effectiveStart, effectiveEnd);
      final effectiveCell = sheet.cell(effectiveStart);
      effectiveCell.value = TextCellValue(effectiveRangeRow);
      effectiveCell.cellStyle = metadataStyle;
      sheet.setMergedCellStyle(effectiveStart, metadataStyle);

      headerRowIndex = 3;
    }

    _writeRow(sheet: sheet, rowIndex: headerRowIndex, row: section.headers);
    for (var col = 0; col < section.headers.length; col++) {
      final headerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex),
      );
      headerCell.cellStyle = headerStyle;
    }

    final highlightedMetrics = <String>{
      labels.totalLoggedTimeRow,
      labels.paidLeaveRow,
      labels.accountedTimeRow,
      labels.plannedTimeRow,
      labels.differenceVsPlanRow,
      labels.balanceAfterPeriodRow,
    };

    final rowByMetric = <String, List<dynamic>>{};

    for (var i = 0; i < section.rows.length; i++) {
      final rowIndex = headerRowIndex + i + 1;
      final row = section.rows[i];
      _writeRow(sheet: sheet, rowIndex: rowIndex, row: row);
      if (row.isEmpty) {
        continue;
      }
      final metric = row.first.toString();
      rowByMetric[metric] = row;
      if (highlightedMetrics.contains(metric)) {
        for (var col = 0; col < section.headers.length; col++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: col, rowIndex: rowIndex))
              .cellStyle = highlightStyle;
        }
      }

      final isSignedMetric = metric == labels.differenceVsPlanRow ||
          metric == labels.balanceAfterPeriodRow;
      if (!isSignedMetric || row.length < 2) {
        continue;
      }
      final minutes =
          row[1] is int ? row[1] as int : int.tryParse(row[1].toString()) ?? 0;
      final signStyle = minutes < 0 ? negativeStyle : positiveStyle;
      for (var col = 0; col < section.headers.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: col, rowIndex: rowIndex))
            .cellStyle = signStyle;
      }
    }

    final quickReadStart = CellIndex.indexByColumnRow(
      columnIndex: 4,
      rowIndex: headerRowIndex,
    );
    final quickReadEnd = CellIndex.indexByColumnRow(
      columnIndex: 5,
      rowIndex: headerRowIndex,
    );
    sheet.merge(quickReadStart, quickReadEnd);
    final quickReadTitleCell = sheet.cell(quickReadStart);
    quickReadTitleCell.value = TextCellValue(labels.quickReadRow);
    quickReadTitleCell.cellStyle = quickReadTitleStyle;
    sheet.setMergedCellStyle(quickReadStart, quickReadTitleStyle);

    final quickReadRows = <List<String>>[
      [
        labels.totalLoggedTimeRow,
        rowByMetric[labels.totalLoggedTimeRow]?[2].toString() ?? ''
      ],
      [
        labels.paidLeaveRow,
        rowByMetric[labels.paidLeaveRow]?[2].toString() ?? ''
      ],
      [
        labels.differenceVsPlanRow,
        rowByMetric[labels.differenceVsPlanRow]?[2].toString() ?? ''
      ],
      [
        labels.balanceAfterPeriodRow,
        rowByMetric[labels.balanceAfterPeriodRow]?[2].toString() ?? '',
      ],
    ];

    for (var i = 0; i < quickReadRows.length; i++) {
      final rowIndex = headerRowIndex + i + 1;
      _writeRow(
        sheet: sheet,
        rowIndex: rowIndex,
        startColumn: 4,
        row: quickReadRows[i],
      );
      for (var col = 4; col <= 5; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: col, rowIndex: rowIndex))
            .cellStyle = quickReadItemStyle;
      }
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(4, 28);
    sheet.setColumnWidth(5, 16);
  }

  static void _writeStyledBalanceEventsSheet({
    required Sheet sheet,
    required ExportData section,
    DateTime? trackingStartDate,
  }) {
    var headerRowIndex = 0;

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.grey200,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    final noteStyle = CellStyle(
      backgroundColorHex: ExcelColor.lightBlue50,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    if (trackingStartDate != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final noteText = 'Baseline date: ${dateFormat.format(trackingStartDate)}';
      final noteStart = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);
      final noteEnd = CellIndex.indexByColumnRow(
        columnIndex: section.headers.length - 1,
        rowIndex: 0,
      );
      sheet.merge(noteStart, noteEnd);
      final noteCell = sheet.cell(noteStart);
      noteCell.value = TextCellValue(noteText);
      noteCell.cellStyle = noteStyle;
      sheet.setMergedCellStyle(noteStart, noteStyle);
      headerRowIndex = 1;
    }

    _writeRow(sheet: sheet, rowIndex: headerRowIndex, row: section.headers);
    for (var col = 0; col < section.headers.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: headerRowIndex,
            ),
          )
          .cellStyle = headerStyle;
    }

    for (var i = 0; i < section.rows.length; i++) {
      _writeRow(
        sheet: sheet,
        rowIndex: headerRowIndex + i + 1,
        row: section.rows[i],
      );
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 42);
  }

  static void _writeRow({
    required Sheet sheet,
    required int rowIndex,
    required List<dynamic> row,
    int startColumn = 0,
  }) {
    for (var i = 0; i < row.length; i++) {
      final value = row[i];
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: startColumn + i,
          rowIndex: rowIndex,
        ),
      );
      cell.value = _toCellValue(value);
    }
  }

  static CellValue _toCellValue(dynamic value) {
    if (value is CellValue) {
      return value;
    }
    if (value is int) {
      return IntCellValue(value);
    }
    if (value is double) {
      return DoubleCellValue(value);
    }
    if (value is bool) {
      return BoolCellValue(value);
    }
    return TextCellValue(value.toString());
  }

  static String _formatSignedHours(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final hours = minutes.abs() / 60.0;
    return '$sign${hours.toStringAsFixed(2)}';
  }

  static Future<String> exportReportSummaryToCSV({
    required ReportSummary summary,
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    String? fileName,
    DateTime? trackingStartDate,
    DateTime? effectiveRangeStart,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = fileName ??
          generateFileName(
            startDate: rangeStart,
            endDate: rangeEnd,
            customName: 'rapport_export',
          );
      final fullFileName = '${baseName}_$timestamp$_csvFileExtension';

      final sections = prepareReportExportData(
        summary: summary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: labels,
      );
      final csvData = CsvExporter.exportMultiple(sections);

      if (csvData.isEmpty) {
        throw Exception('Generated CSV data is empty');
      }

      if (kIsWeb) {
        _downloadFileWeb(csvData, fullFileName, 'text/csv;charset=utf-8');
        return '';
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsString(csvData);

      await _saveCopyToDownloads(
        fileName: fullFileName,
        mimeType: 'text/csv;charset=utf-8',
        bytes: Uint8List.fromList(utf8.encode(csvData)),
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to export report CSV: $e');
    }
  }

  static Future<String> exportReportSummaryToExcel({
    required ReportSummary summary,
    required PeriodSummary periodSummary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
    String? fileName,
    DateTime? trackingStartDate,
    DateTime? effectiveRangeStart,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = fileName ??
          generateFileName(
            startDate: rangeStart,
            endDate: rangeEnd,
            customName: 'rapport_export',
          );
      final fullFileName = '${baseName}_$timestamp$_excelFileExtension';

      final excelData = buildReportSummaryWorkbookBytes(
        summary: summary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: labels,
        trackingStartDate: trackingStartDate,
        effectiveRangeStart: effectiveRangeStart,
      );

      if (excelData == null || excelData.isEmpty) {
        throw Exception('Generated Excel data is empty');
      }

      if (kIsWeb) {
        _downloadFileWeb(
          excelData,
          fullFileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        return '';
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsBytes(excelData);

      await _saveCopyToDownloads(
        fileName: fullFileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        bytes: Uint8List.fromList(excelData),
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to export report Excel: $e');
    }
  }

  /// Export entries to CSV file
  /// Returns the file path of the generated CSV (or empty string on web)
  static Future<String> exportEntriesToCSV({
    required List<Entry> entries,
    required String fileName,
  }) async {
    try {
      if (entries.isEmpty) {
        throw Exception('No entries to export');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp$_csvFileExtension';

      // Create CSV data
      final exportData = prepareExportData(entries);
      final csvData = CsvExporter.export(exportData);

      if (csvData.isEmpty) {
        throw Exception('Generated CSV data is empty');
      }

      if (kIsWeb) {
        // Web: Trigger browser download
        _downloadFileWeb(csvData, fullFileName, 'text/csv;charset=utf-8');
        return ''; // Web doesn't return a file path
      } else {
        // Mobile/Desktop: Save to app storage (used for share flow)
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fullFileName';
        final file = File(filePath);
        await file.writeAsString(csvData);

        // Android: also save a copy in public Downloads for easy transfer.
        await _saveCopyToDownloads(
          fileName: fullFileName,
          mimeType: 'text/csv;charset=utf-8',
          bytes: Uint8List.fromList(utf8.encode(csvData)),
        );

        return filePath;
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export entries to Excel file
  /// Returns the file path of the generated Excel file (or empty string on web)
  static Future<String> exportEntriesToExcel({
    required List<Entry> entries,
    required String fileName,
  }) async {
    try {
      if (entries.isEmpty) {
        throw Exception('No entries to export');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp$_excelFileExtension';

      // Create Excel data
      final exportData = prepareExportData(entries);
      final excelData = XlsxExporter.export(exportData);

      if (excelData == null || excelData.isEmpty) {
        throw Exception('Generated Excel data is empty');
      }

      if (kIsWeb) {
        // Web: Trigger browser download
        _downloadFileWeb(excelData, fullFileName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        return ''; // Web doesn't return a file path
      } else {
        // Mobile/Desktop: Save to app storage (used for share flow)
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fullFileName';
        final file = File(filePath);
        await file.writeAsBytes(excelData);

        // Android: also save a copy in public Downloads for easy transfer.
        await _saveCopyToDownloads(
          fileName: fullFileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          bytes: Uint8List.fromList(excelData),
        );

        return filePath;
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Generate a descriptive filename based on export parameters
  static String generateFileName({
    DateTime? startDate,
    DateTime? endDate,
    String? customName,
  }) {
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }

    if (startDate != null && endDate != null) {
      final start = DateFormat('yyyyMMdd').format(startDate);
      final end = DateFormat('yyyyMMdd').format(endDate);
      return '${_fileNamePrefix}_${start}_to_$end';
    } else if (startDate != null) {
      final start = DateFormat('yyyyMMdd').format(startDate);
      return '${_fileNamePrefix}_from_$start';
    } else if (endDate != null) {
      final end = DateFormat('yyyyMMdd').format(endDate);
      return '${_fileNamePrefix}_until_$end';
    }

    return _fileNamePrefix;
  }

  /// Clean up temporary export files (only for mobile/desktop)
  static Future<void> cleanupExportFiles() async {
    if (kIsWeb) {
      // Web doesn't need cleanup - files are downloaded directly
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (final file in files) {
        if (file is File &&
            file.path.contains(_fileNamePrefix) &&
            (file.path.endsWith(_csvFileExtension) ||
                file.path.endsWith(_excelFileExtension))) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silently handle cleanup errors
      debugPrint('Cleanup error: $e');
    }
  }

  /// Helper method to trigger browser download on web
  static void _downloadFileWeb(dynamic data, String fileName, String mimeType) {
    if (!kIsWeb) return;

    // Convert data to bytes if it's a String (CSV), otherwise use as-is (Excel Uint8List)
    final bytes = data is String
        ? Uint8List.fromList(utf8.encode(data))
        : data as Uint8List;

    if (bytes.isEmpty) {
      throw Exception('Export data is empty - cannot download empty file');
    }

    // Use conditional import - web_download will be the web implementation on web,
    // or stub on other platforms
    web_download.downloadFileWeb(bytes, fileName, mimeType);
  }

  static Future<void> _saveCopyToDownloads({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await _downloadsChannel.invokeMethod('saveToDownloads', {
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
    } catch (e) {
      // Non-blocking: export should still succeed even if Downloads copy fails.
      debugPrint('ExportService: Failed to save copy to Downloads: $e');
    }
  }
}
