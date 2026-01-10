import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/entry.dart';

// Web-specific imports (conditional)
import 'dart:convert' show utf8;

// Conditional import for web download functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart' as web_download;

class ExportService {
  static const String _fileNamePrefix = 'time_tracker_export';
  static const String _csvFileExtension = '.csv';
  static const String _excelFileExtension = '.xlsx';

  /// Export entries to CSV file
  /// Returns the file path of the generated CSV (or empty string on web)
  static Future<String> exportEntriesToCSV({
    required List<Entry> entries,
    required String fileName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (entries.isEmpty) {
        throw Exception('No entries to export');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp$_csvFileExtension';

      // Create CSV data
      final csvData = convertEntriesToCSV(entries, startDate, endDate);
      
      if (csvData.isEmpty) {
        throw Exception('Generated CSV data is empty');
      }

      if (kIsWeb) {
        // Web: Trigger browser download
        _downloadFileWeb(csvData, fullFileName, 'text/csv;charset=utf-8');
        return ''; // Web doesn't return a file path
      } else {
        // Mobile/Desktop: Save to file system
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fullFileName';
        final file = File(filePath);
        await file.writeAsString(csvData);
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
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (entries.isEmpty) {
        throw Exception('No entries to export');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp$_excelFileExtension';

      // Create Excel data
      final excelData = await generateExcelReport(entries, startDate, endDate);

      if (excelData.isEmpty) {
        throw Exception('Generated Excel data is empty');
      }

      if (kIsWeb) {
        // Web: Trigger browser download
        _downloadFileWeb(excelData, fullFileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        return ''; // Web doesn't return a file path
      } else {
        // Mobile/Desktop: Save to file system
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fullFileName';
        final file = File(filePath);
        await file.writeAsBytes(excelData);
        return filePath;
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Generate Excel report from entries
  static Future<Uint8List> generateExcelReport(
    List<Entry> entries,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Create a new Excel document
    final excel = Excel.createExcel();
    final sheet = excel['Time Tracker Report'];

    // Define headers
    final headers = [
      'Entry ID',
      'Type',
      'Date',
      'From',
      'To',
      'Duration (Hours)',
      'Duration (Minutes)',
      'Notes',
      'Created At',
      'Updated At',
      'Journey ID',
      'Segment Order',
      'Total Segments',
      'Work Hours',
      'Shifts Count',
      'Shift Details',
    ];

    // Write headers
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = headers[i]
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: '#E0E0E0',
        );
    }

    // Write data rows
    for (int rowIndex = 0; rowIndex < entries.length; rowIndex++) {
      final entry = entries[rowIndex];
      final row = rowIndex + 1; // +1 because row 0 is headers

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = entry.id;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = entry.type.name;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        .value = DateFormat('yyyy-MM-dd').format(entry.date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        .value = entry.from ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = entry.to ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        .value = entry.totalDuration.inHours;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
        .value = entry.totalDuration.inMinutes;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
        .value = entry.notes ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
        .value = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
        .value = entry.updatedAt != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.updatedAt!)
            : '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
        .value = entry.journeyId ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
        .value = entry.segmentOrder?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
        .value = entry.totalSegments?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
        .value = entry.workHours;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
        .value = entry.shifts?.length.toString() ?? '0';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row))
        .value = _formatShiftsForExcel(entry.shifts);
    }

    // Add summary section
    final summaryRow = entries.length + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
      ..value = 'Export Summary'
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        backgroundColorHex: '#F0F0F0',
      );

    final summaryDataRow = summaryRow + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryDataRow))
      .value = 'Total Entries: ${entries.length}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryDataRow))
      .value = 'Travel Entries: ${entries.where((e) => e.type == EntryType.travel).length}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryDataRow))
      .value = 'Work Entries: ${entries.where((e) => e.type == EntryType.work).length}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryDataRow))
      .value = 'Total Hours: ${_calculateTotalHours(entries).toStringAsFixed(2)}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryDataRow))
      .value = 'Date Range: ${_formatDateRange(startDate, endDate)}';

    // Save the Excel file
    return Uint8List.fromList(excel.save()!);
  }

  /// Format shifts for Excel export
  static String _formatShiftsForExcel(List<Shift>? shifts) {
    if (shifts == null || shifts.isEmpty) return '';

    return shifts.map((shift) {
      final start = DateFormat('HH:mm').format(shift.start);
      final end = DateFormat('HH:mm').format(shift.end);
      final duration = shift.duration.inMinutes;
      final location = shift.location ?? '';
      final description = shift.description ?? '';

      return '$start-$end (${duration}m) $location $description'.trim();
    }).join('; ');
  }

  /// Convert entries to CSV format
  static String convertEntriesToCSV(
    List<Entry> entries,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Define CSV headers
    final headers = [
      'Entry ID',
      'Type',
      'Date',
      'From',
      'To',
      'Duration (Hours)',
      'Duration (Minutes)',
      'Notes',
      'Created At',
      'Updated At',
      'Journey ID',
      'Segment Order',
      'Total Segments',
      'Work Hours',
      'Shifts Count',
      'Shift Details',
    ];

    // Convert entries to CSV rows
    final rows = entries.map((entry) {
      return [
        entry.id,
        entry.type.name,
        DateFormat('yyyy-MM-dd').format(entry.date),
        entry.from ?? '',
        entry.to ?? '',
        entry.totalDuration.inHours.toString(),
        entry.totalDuration.inMinutes.toString(),
        entry.notes ?? '',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt),
        entry.updatedAt != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.updatedAt!)
            : '',
        entry.journeyId ?? '',
        entry.segmentOrder?.toString() ?? '',
        entry.totalSegments?.toString() ?? '',
        entry.workHours.toStringAsFixed(2),
        entry.shifts?.length.toString() ?? '0',
        _formatShiftsForCSV(entry.shifts),
      ];
    }).toList();

    // Add metadata row
    final metadataRow = [
      'Export Summary',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ];

    final summaryRow = [
      'Total Entries: ${entries.length}',
      'Travel Entries: ${entries.where((e) => e.type == EntryType.travel).length}',
      'Work Entries: ${entries.where((e) => e.type == EntryType.work).length}',
      'Total Hours: ${_calculateTotalHours(entries).toStringAsFixed(2)}',
      'Date Range: ${_formatDateRange(startDate, endDate)}',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ];

    // Combine all data
    final allData = [
      headers,
      ...rows,
      metadataRow,
      summaryRow,
    ];

    // Convert to CSV string
    return const ListToCsvConverter().convert(allData);
  }

  /// Format shifts for CSV export
  static String _formatShiftsForCSV(List<Shift>? shifts) {
    if (shifts == null || shifts.isEmpty) return '';

    return shifts.map((shift) {
      final start = DateFormat('HH:mm').format(shift.start);
      final end = DateFormat('HH:mm').format(shift.end);
      final duration = shift.duration.inMinutes;
      final location = shift.location ?? '';
      final description = shift.description ?? '';

      return '$start-$end (${duration}m) $location $description'.trim();
    }).join('; ');
  }

  /// Calculate total hours from entries
  static double _calculateTotalHours(List<Entry> entries) {
    return entries.fold<double>(
      0.0,
      (total, entry) => total + entry.totalDuration.inMinutes / 60.0,
    );
  }

  /// Format date range for CSV
  static String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return 'All time';
    if (startDate == null) {
      return 'Until ${DateFormat('yyyy-MM-dd').format(endDate!)}';
    }
    if (endDate == null) {
      return 'From ${DateFormat('yyyy-MM-dd').format(startDate)}';
    }
    return '${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}';
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
            (file.path.endsWith(_csvFileExtension) || file.path.endsWith(_excelFileExtension))) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silently handle cleanup errors
      print('Cleanup error: $e');
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
}
