import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../repositories/travel_repository.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';
import '../utils/data_validator.dart';

class ExportService {
  final TravelRepository _travelRepository;

  ExportService({required TravelRepository travelRepository})
      : _travelRepository = travelRepository;

  /// Export travel entries to CSV format
  Future<String> exportToCSV({
    required DateTime startDate,
    required DateTime endDate,
    String? customFileName,
  }) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _exportToCSVInternal(startDate, endDate, customFileName),
        shouldRetry: (error) => false, // Don't retry file operations
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<String> _exportToCSVInternal(
    DateTime startDate,
    DateTime endDate,
    String? customFileName,
  ) async {
    // Validate date range
    final dateValidationErrors = DataValidator.validateDateRange(startDate, endDate);
    if (dateValidationErrors.isNotEmpty) {
      throw dateValidationErrors.first;
    }

    // Get entries in date range
    final entries = await _travelRepository.getEntriesInDateRange(startDate, endDate);
    
    // Validate export parameters
    final exportValidationErrors = DataValidator.validateExportParameters(
      startDate: startDate,
      endDate: endDate,
      entries: entries,
    );
    if (exportValidationErrors.isNotEmpty) {
      throw exportValidationErrors.first;
    }

    // Generate filename
    final fileName = customFileName ?? _generateFileName(startDate, endDate, 'csv');
    
    // Validate filename
    final fileNameValidationErrors = DataValidator.validateFileName(fileName);
    if (fileNameValidationErrors.isNotEmpty) {
      throw fileNameValidationErrors.first;
    }

    // Generate CSV content
    final csvContent = _generateCSVContent(entries);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent);

    return file.path;
  }

  String _generateCSVContent(List<TravelTimeEntry> entries) {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln(AppConstants.csvHeader);
    
    // Add data rows
    for (final entry in entries) {
      final row = [
        _escapeCsvField(DateFormat(AppConstants.dateFormat).format(entry.date)),
        _escapeCsvField(entry.departure),
        _escapeCsvField(entry.arrival),
        entry.minutes.toString(),
        _escapeCsvField(entry.info ?? ''),
        _escapeCsvField(DateFormat(AppConstants.dateTimeFormat).format(entry.createdAt)),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Export travel summary to JSON format
  Future<String> exportSummaryToJSON({
    required DateTime startDate,
    required DateTime endDate,
    String? customFileName,
  }) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _exportSummaryToJSONInternal(startDate, endDate, customFileName),
        shouldRetry: (error) => false,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<String> _exportSummaryToJSONInternal(
    DateTime startDate,
    DateTime endDate,
    String? customFileName,
  ) async {
    // Validate date range
    final dateValidationErrors = DataValidator.validateDateRange(startDate, endDate);
    if (dateValidationErrors.isNotEmpty) {
      throw dateValidationErrors.first;
    }

    // Get entries and generate summary
    final entries = await _travelRepository.getEntriesInDateRange(startDate, endDate);
    
    if (entries.isEmpty) {
      throw ErrorHandler.handleValidationError('No travel entries found for the selected date range');
    }

    final summary = TravelSummary(
      totalEntries: entries.length,
      totalMinutes: entries.fold(0, (sum, entry) => sum + entry.minutes),
      startDate: startDate,
      endDate: endDate,
      locationFrequency: _calculateLocationFrequency(entries),
    );

    // Generate filename
    final fileName = customFileName ?? _generateFileName(startDate, endDate, 'json');
    
    // Validate filename
    final fileNameValidationErrors = DataValidator.validateFileName(fileName);
    if (fileNameValidationErrors.isNotEmpty) {
      throw fileNameValidationErrors.first;
    }

    // Generate JSON content
    final jsonContent = _generateSummaryJSON(summary, entries);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonContent);

    return file.path;
  }

  Map<String, int> _calculateLocationFrequency(List<TravelTimeEntry> entries) {
    final frequency = <String, int>{};
    
    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      frequency[route] = (frequency[route] ?? 0) + 1;
    }
    
    return frequency;
  }

  String _generateSummaryJSON(TravelSummary summary, List<TravelTimeEntry> entries) {
    final data = {
      'summary': {
        'totalEntries': summary.totalEntries,
        'totalMinutes': summary.totalMinutes,
        'totalHours': summary.totalHours,
        'averageMinutesPerTrip': summary.averageMinutesPerTrip,
        'formattedDuration': summary.formattedDuration,
        'mostFrequentRoute': summary.mostFrequentRoute,
        'startDate': summary.startDate.toIso8601String(),
        'endDate': summary.endDate.toIso8601String(),
        'locationFrequency': summary.locationFrequency,
      },
      'entries': entries.map((entry) => {
        'id': entry.id,
        'date': entry.date.toIso8601String(),
        'departure': entry.departure,
        'arrival': entry.arrival,
        'minutes': entry.minutes,
        'info': entry.info,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt?.toIso8601String(),
      }).toList(),
      'exportInfo': {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'format': 'travel_summary_json',
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export entries in multiple formats
  Future<Map<String, String>> exportMultipleFormats({
    required DateTime startDate,
    required DateTime endDate,
    List<ExportFormat> formats = const [ExportFormat.csv, ExportFormat.json],
    String? baseFileName,
  }) async {
    final results = <String, String>{};
    
    for (final format in formats) {
      try {
        String filePath;
        switch (format) {
          case ExportFormat.csv:
            filePath = await exportToCSV(
              startDate: startDate,
              endDate: endDate,
              customFileName: baseFileName != null ? '$baseFileName.csv' : null,
            );
            results['csv'] = filePath;
            break;
          case ExportFormat.json:
            filePath = await exportSummaryToJSON(
              startDate: startDate,
              endDate: endDate,
              customFileName: baseFileName != null ? '$baseFileName.json' : null,
            );
            results['json'] = filePath;
            break;
        }
      } catch (error) {
        // Log error but continue with other formats
        final appError = ErrorHandler.handleStorageError(error);
        ErrorHandler.handleError(appError);
      }
    }
    
    return results;
  }

  /// Get export preview (first few rows)
  Future<Map<String, dynamic>> getExportPreview({
    required DateTime startDate,
    required DateTime endDate,
    int previewRows = 5,
  }) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getExportPreviewInternal(startDate, endDate, previewRows),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<Map<String, dynamic>> _getExportPreviewInternal(
    DateTime startDate,
    DateTime endDate,
    int previewRows,
  ) async {
    final entries = await _travelRepository.getEntriesInDateRange(startDate, endDate);
    
    final previewEntries = entries.take(previewRows).toList();
    final csvPreview = _generateCSVContent(previewEntries);
    
    return {
      'totalEntries': entries.length,
      'previewEntries': previewEntries.length,
      'csvPreview': csvPreview,
      'estimatedFileSize': _estimateFileSize(entries.length),
      'dateRange': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
    };
  }

  int _estimateFileSize(int entryCount) {
    // Rough estimate: ~150 bytes per entry (including headers and formatting)
    const bytesPerEntry = 150;
    const headerSize = 100;
    return (entryCount * bytesPerEntry) + headerSize;
  }

  String _generateFileName(DateTime startDate, DateTime endDate, String extension) {
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    
    return 'travel_export_${startStr}_to_${endStr}_$timestamp.$extension';
  }

  /// Get available export formats
  List<ExportFormat> getAvailableFormats() {
    return ExportFormat.values;
  }

  /// Validate export request
  Future<List<AppError>> validateExportRequest({
    required DateTime startDate,
    required DateTime endDate,
    String? fileName,
  }) async {
    final errors = <AppError>[];
    
    // Validate date range
    errors.addAll(DataValidator.validateDateRange(startDate, endDate));
    
    // Validate filename if provided
    if (fileName != null) {
      errors.addAll(DataValidator.validateFileName(fileName));
    }
    
    // Check if there are entries in the date range
    try {
      final entries = await _travelRepository.getEntriesInDateRange(startDate, endDate);
      if (entries.isEmpty) {
        errors.add(ErrorHandler.handleValidationError(
          'No travel entries found for the selected date range'
        ));
      }
    } catch (error) {
      errors.add(ErrorHandler.handleStorageError(error));
    }
    
    return errors;
  }

  /// Clean up old export files
  Future<void> cleanupOldExports({int maxAgeInDays = 30}) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _cleanupOldExportsInternal(maxAgeInDays),
        shouldRetry: (error) => false,
      );
    } catch (error) {
      // Cleanup failures should not crash the app
      final appError = ErrorHandler.handleStorageError(error);
      ErrorHandler.handleError(appError);
    }
  }

  Future<void> _cleanupOldExportsInternal(int maxAgeInDays) async {
    final directory = await getApplicationDocumentsDirectory();
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
    
    final files = directory.listSync()
        .where((entity) => entity is File && entity.path.contains('travel_export_'))
        .cast<File>()
        .toList();

    for (final file in files) {
      final lastModified = await file.lastModified();
      if (lastModified.isBefore(cutoffDate)) {
        try {
          await file.delete();
        } catch (error) {
          // Continue with other files if one fails
        }
      }
    }
  }
}

enum ExportFormat {
  csv,
  json,
}