import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../repositories/travel_repository.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';
import '../utils/data_validator.dart';

class ExportService {
  final TravelRepository? _travelRepository;

  ExportService({TravelRepository? travelRepository})
      : _travelRepository = travelRepository;

  /// Export travel entries to CSV format with enhanced options
  Future<String> exportToCSV(
    List<TravelTimeEntry> entries,
    DateTime startDate,
    DateTime endDate, {
    String? customFileName,
    List<CSVColumn> columns = const [
      CSVColumn.date,
      CSVColumn.departure,
      CSVColumn.arrival,
      CSVColumn.duration,
      CSVColumn.info,
      CSVColumn.createdAt,
    ],
    Function(double progress)? onProgress,
  }) async {
    try {
      return await _exportToCSVInternal(
        entries,
        startDate,
        endDate,
        customFileName,
        columns,
        onProgress,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Legacy method for backward compatibility
  Future<String> exportToCSVLegacy({
    required DateTime startDate,
    required DateTime endDate,
    String? customFileName,
  }) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _exportToCSVLegacyInternal(startDate, endDate, customFileName),
        shouldRetry: (error) => false, // Don't retry file operations
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<String> _exportToCSVInternal(
    List<TravelTimeEntry> entries,
    DateTime startDate,
    DateTime endDate,
    String? customFileName,
    List<CSVColumn> columns,
    Function(double progress)? onProgress,
  ) async {
    // Validate date range
    final dateValidationErrors = DataValidator.validateDateRange(startDate, endDate);
    if (dateValidationErrors.isNotEmpty) {
      throw dateValidationErrors.first;
    }

    // Generate filename
    final fileName = customFileName ?? _generateFileName(startDate, endDate, 'csv');
    
    // Validate filename
    final fileNameValidationErrors = DataValidator.validateFileName(fileName);
    if (fileNameValidationErrors.isNotEmpty) {
      throw fileNameValidationErrors.first;
    }

    // Generate CSV content with progress tracking
    final csvContent = await _generateAdvancedCSVContent(entries, columns, onProgress);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent);

    return file.path;
  }

  Future<String> _exportToCSVLegacyInternal(
    DateTime startDate,
    DateTime endDate,
    String? customFileName,
  ) async {
    if (_travelRepository == null) {
      throw ErrorHandler.handleValidationError('Travel repository not available');
    }

    // Validate date range
    final dateValidationErrors = DataValidator.validateDateRange(startDate, endDate);
    if (dateValidationErrors.isNotEmpty) {
      throw dateValidationErrors.first;
    }

    // Get entries in date range
    final entries = await _travelRepository!.getEntriesInDateRange(startDate, endDate);
    
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

  /// Generate advanced CSV content with customizable columns and progress tracking
  Future<String> _generateAdvancedCSVContent(
    List<TravelTimeEntry> entries,
    List<CSVColumn> columns,
    Function(double progress)? onProgress,
  ) async {
    final buffer = StringBuffer();
    
    // Generate header based on selected columns
    final headers = columns.map((column) => _getColumnHeader(column)).toList();
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    
    // Add data rows with progress tracking
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = columns.map((column) => _getColumnValue(entry, column)).toList();
      buffer.writeln(row.map(_escapeCsvField).join(','));
      
      // Report progress
      if (onProgress != null && i % 100 == 0) {
        final progress = (i + 1) / entries.length;
        onProgress(progress);
      }
    }
    
    // Final progress update
    onProgress?.call(1.0);
    
    return buffer.toString();
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

  String _getColumnHeader(CSVColumn column) {
    switch (column) {
      case CSVColumn.date:
        return 'Date';
      case CSVColumn.departure:
        return 'Departure';
      case CSVColumn.arrival:
        return 'Arrival';
      case CSVColumn.duration:
        return 'Duration (minutes)';
      case CSVColumn.durationFormatted:
        return 'Duration (formatted)';
      case CSVColumn.info:
        return 'Additional Info';
      case CSVColumn.createdAt:
        return 'Created At';
      case CSVColumn.updatedAt:
        return 'Updated At';
      case CSVColumn.id:
        return 'ID';
      case CSVColumn.route:
        return 'Route';
      case CSVColumn.dayOfWeek:
        return 'Day of Week';
      case CSVColumn.month:
        return 'Month';
      case CSVColumn.year:
        return 'Year';
    }
  }

  String _getColumnValue(TravelTimeEntry entry, CSVColumn column) {
    switch (column) {
      case CSVColumn.date:
        return DateFormat(AppConstants.dateFormat).format(entry.date);
      case CSVColumn.departure:
        return entry.departure;
      case CSVColumn.arrival:
        return entry.arrival;
      case CSVColumn.duration:
        return entry.minutes.toString();
      case CSVColumn.durationFormatted:
        final hours = entry.minutes ~/ 60;
        final minutes = entry.minutes % 60;
        return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      case CSVColumn.info:
        return entry.info ?? '';
      case CSVColumn.createdAt:
        return DateFormat(AppConstants.dateTimeFormat).format(entry.createdAt);
      case CSVColumn.updatedAt:
        return entry.updatedAt != null 
            ? DateFormat(AppConstants.dateTimeFormat).format(entry.updatedAt!)
            : '';
      case CSVColumn.id:
        return entry.id;
      case CSVColumn.route:
        return '${entry.departure} → ${entry.arrival}';
      case CSVColumn.dayOfWeek:
        return DateFormat('EEEE').format(entry.date);
      case CSVColumn.month:
        return DateFormat('MMMM').format(entry.date);
      case CSVColumn.year:
        return entry.date.year.toString();
    }
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
    final entries = await _travelRepository!.getEntriesInDateRange(startDate, endDate);
    
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
            filePath = await exportToCSVLegacy(
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
    final entries = await _travelRepository!.getEntriesInDateRange(startDate, endDate);
    
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
      final entries = await _travelRepository!.getEntriesInDateRange(startDate, endDate);
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

  /// Export summary to CSV format
  Future<String> exportSummaryToCSV(
    TravelSummary summary,
    DateTime startDate,
    DateTime endDate, {
    String? customFileName,
  }) async {
    try {
      // Generate filename
      final fileName = customFileName ?? _generateFileName(startDate, endDate, 'summary.csv');
      
      // Generate CSV content for summary
      final csvContent = _generateSummaryCSVContent(summary);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);

      return file.path;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  String _generateSummaryCSVContent(TravelSummary summary) {
    final buffer = StringBuffer();
    
    // Add summary header
    buffer.writeln('Travel Summary Report');
    buffer.writeln('Generated on,${DateFormat(AppConstants.dateTimeFormat).format(DateTime.now())}');
    buffer.writeln('Period,${DateFormat(AppConstants.dateFormat).format(summary.startDate)} to ${DateFormat(AppConstants.dateFormat).format(summary.endDate)}');
    buffer.writeln('');
    
    // Add summary statistics
    buffer.writeln('Summary Statistics');
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Trips,${summary.totalEntries}');
    buffer.writeln('Total Time,${summary.formattedDuration}');
    buffer.writeln('Average Trip Duration,${summary.averageMinutesPerTrip.toStringAsFixed(1)} minutes');
    buffer.writeln('Most Frequent Route,${summary.mostFrequentRoute}');
    buffer.writeln('');
    
    // Add route frequency data
    if (summary.locationFrequency.isNotEmpty) {
      buffer.writeln('Route Frequency');
      buffer.writeln('Route,Trip Count');
      
      final sortedRoutes = summary.locationFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedRoutes) {
        buffer.writeln('${_escapeCsvField(entry.key)},${entry.value}');
      }
    }
    
    return buffer.toString();
  }

  /// Share exported file using platform share functionality
  Future<void> shareFile(String filePath, {
    String? customText,
    String? customSubject,
  }) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = file.path.split('/').last;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: customText ?? 'Travel Time Export - $fileName',
          subject: customSubject ?? 'Travel Data Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      } else {
        throw ErrorHandler.handleValidationError('Export file not found');
      }
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Share multiple files at once
  Future<void> shareMultipleFiles(List<String> filePaths, {
    String? customText,
    String? customSubject,
  }) async {
    try {
      final xFiles = <XFile>[];
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          xFiles.add(XFile(filePath));
        }
      }

      if (xFiles.isEmpty) {
        throw ErrorHandler.handleValidationError('No valid export files found');
      }

      await Share.shareXFiles(
        xFiles,
        text: customText ?? 'Travel Time Exports (${xFiles.length} files)',
        subject: customSubject ?? 'Travel Data Exports - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      );
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Get file info for sharing preview
  Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ErrorHandler.handleValidationError('File not found');
      }

      final stat = await file.stat();
      final fileName = file.path.split('/').last;
      
      return {
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': stat.size,
        'fileSizeFormatted': _formatFileSize(stat.size),
        'lastModified': stat.modified,
        'lastModifiedFormatted': DateFormat(AppConstants.dateTimeFormat).format(stat.modified),
        'exists': true,
      };
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Get all export files in the documents directory
  Future<List<Map<String, dynamic>>> getExportFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((entity) => entity is File && 
                 (entity.path.contains('travel_export_') || 
                  entity.path.contains('travel_summary_')))
          .cast<File>()
          .toList();

      final fileInfos = <Map<String, dynamic>>[];
      for (final file in files) {
        try {
          final info = await getFileInfo(file.path);
          fileInfos.add(info);
        } catch (error) {
          // Skip files that can't be read
          continue;
        }
      }

      // Sort by last modified date (newest first)
      fileInfos.sort((a, b) => 
          (b['lastModified'] as DateTime).compareTo(a['lastModified'] as DateTime));

      return fileInfos;
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Delete export file
  Future<bool> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Delete multiple export files
  Future<int> deleteMultipleFiles(List<String> filePaths) async {
    int deletedCount = 0;
    for (final filePath in filePaths) {
      try {
        if (await deleteExportFile(filePath)) {
          deletedCount++;
        }
      } catch (error) {
        // Continue with other files if one fails
        continue;
      }
    }
    return deletedCount;
  }

  /// Copy file to external storage (if available)
  Future<String?> copyToExternalStorage(String filePath, {String? customName}) async {
    try {
      // This would require additional platform-specific implementation
      // For now, we'll return the original path
      return filePath;
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await getExportFiles();
      
      int totalSize = 0;
      int totalFiles = files.length;
      
      for (final fileInfo in files) {
        totalSize += fileInfo['fileSize'] as int;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeFormatted': _formatFileSize(totalSize),
        'directory': directory.path,
        'files': files,
      };
    } catch (error) {
      final appError = ErrorHandler.handleStorageError(error);
      throw appError;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get available CSV columns for customization
  List<CSVColumn> getAvailableColumns() {
    return CSVColumn.values;
  }

  /// Get column display names for UI
  Map<CSVColumn, String> getColumnDisplayNames() {
    return {
      for (final column in CSVColumn.values)
        column: _getColumnHeader(column),
    };
  }

  /// Estimate export file size
  int estimateExportSize(int entryCount, List<CSVColumn> columns) {
    // Base estimate per entry varies by number of columns
    final baseSize = 50; // Base size per entry
    final columnSize = columns.length * 20; // Additional size per column
    const headerSize = 200; // Header and metadata
    
    return (entryCount * (baseSize + columnSize)) + headerSize;
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

enum CSVColumn {
  date,
  departure,
  arrival,
  duration,
  durationFormatted,
  info,
  createdAt,
  updatedAt,
  id,
  route,
  dayOfWeek,
  month,
  year,
}