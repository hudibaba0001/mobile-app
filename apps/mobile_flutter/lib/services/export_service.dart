import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/absence.dart';
import '../models/entry.dart';
import '../models/export_data.dart';
import '../reporting/leave_minutes.dart';
import '../reporting/period_summary.dart';
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

  static ExportData _prepareReportEntriesExportData({
    required ReportSummary summary,
    required String sheetName,
    required String trackedTotalsNote,
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

    final noteRow = List<dynamic>.filled(_entryExportHeaders.length, '');
    noteRow[_colType] = 'NOTE';
    noteRow[_colEntryNotes] = trackedTotalsNote;
    rows.insert(0, _normalizeEntryExportRow(noteRow));

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
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final summaryRows = <List<dynamic>>[
      [
        labels.quickReadRow,
        '${dateFormat.format(rangeStart)} - ${dateFormat.format(rangeEnd)}',
        '',
      ],
      [
        labels.periodRow,
        '${dateFormat.format(rangeStart)} - ${dateFormat.format(rangeEnd)}',
        '',
      ],
      [
        labels.totalLoggedTimeRow,
        periodSummary.trackedTotalMinutes,
        _formatUnsignedHours(periodSummary.trackedTotalMinutes),
      ],
      [
        labels.paidLeaveRow,
        periodSummary.paidLeaveMinutes,
        _formatUnsignedHours(periodSummary.paidLeaveMinutes),
      ],
      [
        labels.accountedTimeRow,
        periodSummary.accountedMinutes,
        _formatUnsignedHours(periodSummary.accountedMinutes),
      ],
      [
        labels.plannedTimeRow,
        periodSummary.targetMinutes,
        _formatUnsignedHours(periodSummary.targetMinutes),
      ],
      [
        labels.differenceVsPlanRow,
        periodSummary.differenceMinutes,
        _formatSignedHours(periodSummary.differenceMinutes),
      ],
      [
        labels.balanceAfterPeriodRow,
        periodSummary.endBalanceMinutes,
        _formatSignedHours(periodSummary.endBalanceMinutes),
      ],
    ];

    return ExportData(
      sheetName: labels.summarySheetName,
      headers: [
        labels.metricHeader,
        labels.minutesHeader,
        labels.hoursHeader,
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
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final adjustmentRows = <List<dynamic>>[];
    final opening = summary.balanceOffsets.openingEvent;
    if (opening != null) {
      adjustmentRows.add([
        labels.openingBalanceRow,
        dateFormat.format(opening.effectiveDate),
        opening.minutes,
        _formatSignedHours(opening.minutes),
        '',
      ]);
    }

    for (final adjustment in summary.balanceOffsets.adjustmentsInRange) {
      adjustmentRows.add([
        labels.timeAdjustmentRow,
        dateFormat.format(adjustment.effectiveDate),
        adjustment.minutes,
        _formatSignedHours(adjustment.minutes),
        adjustment.note ?? '',
      ]);
    }

    adjustmentRows.add([
      labels.timeAdjustmentsTotalRow,
      '',
      periodSummary.manualAdjustmentMinutes,
      _formatSignedHours(periodSummary.manualAdjustmentMinutes),
      '',
    ]);
    adjustmentRows.add([
      labels.periodStartBalanceRow,
      dateFormat.format(rangeStart),
      periodSummary.startBalanceMinutes,
      _formatSignedHours(periodSummary.startBalanceMinutes),
      '',
    ]);
    adjustmentRows.add([
      labels.periodEndBalanceRow,
      dateFormat.format(rangeEnd),
      periodSummary.endBalanceMinutes,
      _formatSignedHours(periodSummary.endBalanceMinutes),
      '',
    ]);

    return ExportData(
      sheetName: labels.balanceEventsSheetName,
      headers: [
        labels.colType,
        labels.colDate,
        labels.colMinutes,
        labels.colHours,
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
  }) {
    final entriesSheet = _prepareReportEntriesExportData(
      summary: summary,
      sheetName: labels.entriesSheetName,
      trackedTotalsNote: labels.trackedTotalsNote,
    );
    final summarySheet = _prepareSummarySheet(
      periodSummary: periodSummary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      labels: labels,
    );
    final balanceEventsSheet = _prepareBalanceEventsSheet(
      summary: summary,
      periodSummary: periodSummary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      labels: labels,
    );

    return [entriesSheet, summarySheet, balanceEventsSheet];
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

      final sections = prepareReportExportData(
        summary: summary,
        periodSummary: periodSummary,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: labels,
      );
      final excelData = XlsxExporter.exportMultiple(sections);

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
