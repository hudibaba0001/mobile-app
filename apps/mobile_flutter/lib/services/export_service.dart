import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/entry.dart';
import '../models/export_data.dart';
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
  final String adjustmentsSheetName;
  final String openingBalanceRow;
  final String timeAdjustmentRow;
  final String timeAdjustmentsTotalRow;
  final String periodStartBalanceRow;
  final String periodEndBalanceRow;
  final String colType;
  final String colDate;
  final String colMinutes;
  final String colHours;
  final String colNote;

  const ReportExportLabels({
    required this.entriesSheetName,
    required this.adjustmentsSheetName,
    required this.openingBalanceRow,
    required this.timeAdjustmentRow,
    required this.timeAdjustmentsTotalRow,
    required this.periodStartBalanceRow,
    required this.periodEndBalanceRow,
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

  static List<ExportData> prepareReportExportData({
    required ReportSummary summary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ReportExportLabels labels,
  }) {
    final entriesSheet = prepareExportData(
      summary.filteredEntries,
      summary: summary,
    );
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

    final adjustmentsTotal = summary.balanceAdjustmentMinutesInRange;
    adjustmentRows.add([
      labels.timeAdjustmentsTotalRow,
      '',
      adjustmentsTotal,
      _formatSignedHours(adjustmentsTotal),
      '',
    ]);

    adjustmentRows.add([
      labels.periodStartBalanceRow,
      dateFormat.format(rangeStart),
      summary.startingBalanceMinutes,
      _formatSignedHours(summary.startingBalanceMinutes),
      '',
    ]);
    adjustmentRows.add([
      labels.periodEndBalanceRow,
      dateFormat.format(rangeEnd),
      summary.closingBalanceMinutes,
      _formatSignedHours(summary.closingBalanceMinutes),
      '',
    ]);

    final adjustmentsSheet = ExportData(
      sheetName: labels.adjustmentsSheetName,
      headers: [
        labels.colType,
        labels.colDate,
        labels.colMinutes,
        labels.colHours,
        labels.colNote,
      ],
      rows: adjustmentRows,
    );

    return [entriesSheet, adjustmentsSheet];
  }

  static String _formatSignedHours(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final hours = minutes.abs() / 60.0;
    return '$sign${hours.toStringAsFixed(2)}';
  }

  static Future<String> exportReportSummaryToCSV({
    required ReportSummary summary,
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
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: labels,
      );
      sections[0] = ExportData(
        sheetName: labels.entriesSheetName,
        headers: sections[0].headers,
        rows: sections[0].rows,
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
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        labels: labels,
      );
      sections[0] = ExportData(
        sheetName: labels.entriesSheetName,
        headers: sections[0].headers,
        rows: sections[0].rows,
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
