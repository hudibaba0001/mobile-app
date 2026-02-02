// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/entry.dart';
import '../models/export_data.dart';
import 'csv_exporter.dart';
import 'xlsx_exporter.dart';

// Web-specific imports (conditional)
import 'dart:convert' show utf8;

// Conditional import for web download functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart' as web_download;

class ExportService {
  static const String _fileNamePrefix = 'time_tracker_export';
  static const String _csvFileExtension = '.csv';
  static const String _excelFileExtension = '.xlsx';

  static ExportData prepareExportData(List<Entry> entries) {
    final hasTravel = entries.any((entry) => entry.type == EntryType.travel);
    final hasWork = entries.any((entry) => entry.type == EntryType.work);
    final includeTravelColumns = hasTravel;
    final includeWorkColumns = hasWork;
    final includeAuditColumns = includeWorkColumns; // remove audit columns from travel-only exports

    int totalTravelMinutes = 0;
    double totalTravelDistanceKm = 0.0;
    int totalWorkedMinutes = 0;

    final headers = <String>[
      'Type',
      'Date',
      if (includeTravelColumns) ...[
        'From',
        'To',
        'Travel Minutes',
        'Travel Distance (km)',
      ],
      if (includeWorkColumns) ...[
        'Shift Number',
        'Shift Start',
        'Shift End',
        'Span Minutes',
        'Unpaid Break Minutes',
        'Worked Minutes',
        'Worked Hours',
        'Shift Location',
        'Shift Notes',
      ],
      'Entry Notes',
      if (includeAuditColumns) ...[
        'Created At',
        'Updated At',
        'Holiday Work',
        'Holiday Name',
      ],
    ];

    final rows = <List<dynamic>>[];

    for (final entry in entries) {
      if (entry.type == EntryType.travel) {
        // Travel entry: one row per leg (prefer travelLegs, fallback to legacy)
        if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
          final legs = entry.travelLegs!;
          for (var i = 0; i < legs.length; i++) {
            final leg = legs[i];
            rows.add([
              entry.type.name,
              DateFormat('yyyy-MM-dd').format(entry.date),
              if (includeTravelColumns) ...[
                leg.fromText, // From
                leg.toText, // To
                leg.minutes, // Travel Minutes
                leg.distanceKm ?? 0.0, // Travel Distance (km)
              ],
              if (includeWorkColumns) ...List.filled(9, ''), // Work placeholders
              entry.notes ?? '', // Entry Notes
              if (includeAuditColumns) ...[
                DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt),
                entry.updatedAt != null
                    ? DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(entry.updatedAt!)
                    : '',
                '', // Holiday Work (not applicable for travel)
                '', // Holiday Name
              ],
            ]);
            totalTravelMinutes += leg.minutes;
            totalTravelDistanceKm += (leg.distanceKm ?? 0.0);
          }
        } else {
          // Legacy single travel entry: one row
          rows.add([
            entry.type.name,
            DateFormat('yyyy-MM-dd').format(entry.date),
            if (includeTravelColumns) ...[
              entry.from ?? '',
              entry.to ?? '',
              entry.travelMinutes ?? 0,
              0.0, // Travel Distance (not available for legacy)
            ],
            if (includeWorkColumns) ...List.filled(9, ''), // Work placeholders
            entry.notes ?? '', // Entry Notes
            if (includeAuditColumns) ...[
              DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt),
              entry.updatedAt != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.updatedAt!)
                  : '',
              entry.isHolidayWork ? 'Yes' : 'No',
              entry.holidayName ?? '',
            ],
          ]);
          totalTravelMinutes += entry.travelMinutes ?? 0;
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

          rows.add([
            entry.type.name,
            DateFormat('yyyy-MM-dd').format(entry.date),
            if (includeTravelColumns) ...List.filled(8, ''), // Travel placeholders
            if (includeWorkColumns) ...[
              i + 1, // Shift Number
              DateFormat('HH:mm').format(shift.start), // Shift Start
              DateFormat('HH:mm').format(shift.end), // Shift End
              spanMinutes, // Span Minutes
              breakMinutes, // Unpaid Break Minutes
              workedMinutes, // Worked Minutes
              workedHours.toStringAsFixed(2), // Worked Hours
              shift.location ?? '', // Shift Location
              shift.notes ?? '', // Shift Notes
            ],
            entry.notes ?? '', // Entry Notes (day-level)
            if (includeAuditColumns) ...[
              DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt),
              entry.updatedAt != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.updatedAt!)
                  : '',
              entry.isHolidayWork ? 'Yes' : 'No',
              entry.holidayName ?? '',
            ],
          ]);
          totalWorkedMinutes += workedMinutes;
        }
      } else {
        // Work entry with no shifts: one row with empty shift data
        rows.add([
          entry.type.name,
          DateFormat('yyyy-MM-dd').format(entry.date),
          if (includeTravelColumns) ...List.filled(8, ''), // Travel placeholders
          if (includeWorkColumns) ...List.filled(9, ''), // Work placeholders
          entry.notes ?? '', // Entry Notes
          if (includeAuditColumns) ...[
            DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.createdAt),
            entry.updatedAt != null
                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.updatedAt!)
                : '',
            entry.isHolidayWork ? 'Yes' : 'No',
            entry.holidayName ?? '',
          ],
        ]);
        // Without shifts we can't infer worked minutes; leave total unchanged
      }
    }

    // Append summary row with totals
    final summaryRow = <dynamic>[
      'Totals',
      '',
      if (includeTravelColumns) ...[
        '', // From
        '', // To
        totalTravelMinutes, // Travel Minutes total
        totalTravelDistanceKm, // Travel Distance total
      ],
      if (includeWorkColumns) ...[
        '', // Shift Number
        '', // Shift Start
        '', // Shift End
        '', // Span Minutes
        '', // Unpaid Break Minutes
        totalWorkedMinutes, // Worked Minutes total
        (totalWorkedMinutes / 60).toStringAsFixed(2), // Worked Hours total
        '', // Shift Location
        '', // Shift Notes
      ],
      'Totals',
      if (includeAuditColumns) ...[
        '', // Created At
        '', // Updated At
        '', // Holiday Work
        '', // Holiday Name
      ],
    ];

    rows.add(summaryRow);

    return ExportData(headers: headers, rows: rows);
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
