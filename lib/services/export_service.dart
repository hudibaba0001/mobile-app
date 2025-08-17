import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';

class ExportService {
  static const String _fileNamePrefix = 'time_tracker_export';
  static const String _fileExtension = '.csv';

  /// Export entries to CSV file
  /// Returns the file path of the generated CSV
  static Future<String> exportEntriesToCSV({
    required List<Entry> entries,
    required String fileName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp$_fileExtension';
      final filePath = '${directory.path}/$fullFileName';

      // Create CSV data
      final csvData = convertEntriesToCSV(entries, startDate, endDate);

      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
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
    if (startDate == null)
      return 'Until ${DateFormat('yyyy-MM-dd').format(endDate!)}';
    if (endDate == null)
      return 'From ${DateFormat('yyyy-MM-dd').format(startDate)}';
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

  /// Clean up temporary export files
  static Future<void> cleanupExportFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (final file in files) {
        if (file is File &&
            file.path.contains(_fileNamePrefix) &&
            file.path.endsWith(_fileExtension)) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silently handle cleanup errors
      print('Cleanup error: $e');
    }
  }
}
