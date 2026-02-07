import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class ImportService {
  final EntryProvider _entryProvider;

  ImportService({required EntryProvider entryProvider})
      : _entryProvider = entryProvider;

  /// Import travel entries from CSV file
  Future<ImportResult> importFromCSV(String filePath) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _importFromCSVInternal(filePath),
        shouldRetry: (error) => false, // Don't retry file operations
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<ImportResult> _importFromCSVInternal(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ErrorHandler.handleValidationError('Import file not found');
    }

    final content = await file.readAsString();
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      throw ErrorHandler.handleValidationError('Import file is empty');
    }

    // Validate header
    final header = lines.first.toLowerCase();
    if (!_isValidCSVHeader(header)) {
      throw ErrorHandler.handleValidationError(
          'Invalid CSV format. Expected header: ${AppConstants.csvHeader}');
    }

    final result = ImportResult();
    final dataLines = lines.skip(1).toList();
    final entriesToSave = <Entry>[];
    final seenKeys = <String>{};

    for (int i = 0; i < dataLines.length; i++) {
      try {
        final entry = _parseCSVLine(
            dataLines[i], i + 2); // +2 for header and 0-based index

        if (!entry.isValidTravel) {
          result.addError(i + 2, 'Invalid travel entry data');
          continue;
        }

        final atomicEntry =
            entry.travelLegs != null && entry.travelLegs!.isNotEmpty
                ? entry
                : Entry.makeTravelAtomicFromLeg(
                    userId: entry.userId,
                    date: entry.date,
                    from: entry.from ?? '',
                    to: entry.to ?? '',
                    minutes: entry.travelMinutes ?? 0,
                    dayNotes: entry.notes,
                  );

        final dedupeKey =
            '${atomicEntry.userId}-${atomicEntry.date.toIso8601String()}-${atomicEntry.from}-${atomicEntry.to}-${atomicEntry.travelMinutes}-${atomicEntry.notes}';
        if (seenKeys.add(dedupeKey)) {
          entriesToSave.add(atomicEntry);
          result.successCount++;
        }
      } catch (error) {
        result.addError(i + 2, error.toString());
      }
    }

    if (entriesToSave.isNotEmpty) {
      await _entryProvider.addEntries(entriesToSave);
    }

    result.totalProcessed = dataLines.length;
    return result;
  }

  bool _isValidCSVHeader(String header) {
    final actualFields = header.split(',').map((f) => f.trim()).toList();

    // Check if all required fields are present (order doesn't matter)
    final requiredFields = ['date', 'departure', 'arrival', 'minutes'];
    return requiredFields
        .every((field) => actualFields.any((actual) => actual.contains(field)));
  }

  Entry _parseCSVLine(String line, int lineNumber) {
    final fields = _parseCSVFields(line);

    if (fields.length < 4) {
      throw Exception('Invalid CSV format: insufficient fields');
    }

    try {
      final date = _parseDate(fields[0]);
      final departure = fields[1].trim();
      final arrival = fields[2].trim();
      final minutes = int.tryParse(fields[3].trim()) ?? 0;
      final info = fields.length > 4 && fields[4].trim().isNotEmpty
          ? fields[4].trim()
          : null;

      return Entry(
        userId: 'imported_user', // TODO: Get from auth service
        type: EntryType.travel,
        date: date,
        from: departure,
        to: arrival,
        travelMinutes: minutes,
        notes: info,
      );
    } catch (error) {
      throw Exception('Error parsing line $lineNumber: $error');
    }
  }

  List<String> _parseCSVFields(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    fields.add(buffer.toString());

    return fields;
  }

  DateTime _parseDate(String dateStr) {
    final cleanDateStr = dateStr.trim();

    // Try different date formats
    final formats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(cleanDateStr);
      } catch (e) {
        // Try next format
      }
    }

    throw Exception('Unable to parse date: $cleanDateStr');
  }

  /// Import from JSON backup file
  Future<ImportResult> importFromJSON(String filePath) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _importFromJSONInternal(filePath),
        shouldRetry: (error) => false,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<ImportResult> _importFromJSONInternal(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ErrorHandler.handleValidationError('Import file not found');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    // Validate JSON structure
    if (!data.containsKey('entries')) {
      throw ErrorHandler.handleValidationError(
          'Invalid JSON format: missing entries');
    }

    final result = ImportResult();
    final entries = data['entries'] as List<dynamic>;
    final toSave = <Entry>[];
    final seenKeys = <String>{};

    for (int i = 0; i < entries.length; i++) {
      try {
        final entryData = entries[i] as Map<String, dynamic>;
        final entry = _parseJSONEntry(entryData);

        if (!entry.isValidTravel) {
          result.addError(i + 1, 'Invalid travel entry data');
          continue;
        }

        final atomicEntry =
            entry.travelLegs != null && entry.travelLegs!.isNotEmpty
                ? entry
                : Entry.makeTravelAtomicFromLeg(
                    userId: entry.userId,
                    date: entry.date,
                    from: entry.from ?? '',
                    to: entry.to ?? '',
                    minutes: entry.travelMinutes ?? 0,
                    dayNotes: entry.notes,
                  );

        final dedupeKey =
            '${atomicEntry.userId}-${atomicEntry.date.toIso8601String()}-${atomicEntry.from}-${atomicEntry.to}-${atomicEntry.travelMinutes}-${atomicEntry.notes}';
        if (seenKeys.add(dedupeKey)) {
          toSave.add(atomicEntry);
          result.successCount++;
        }
      } catch (error) {
        result.addError(i + 1, error.toString());
      }
    }

    if (toSave.isNotEmpty) {
      await _entryProvider.addEntries(toSave);
    }

    result.totalProcessed = entries.length;
    return result;
  }

  Entry _parseJSONEntry(Map<String, dynamic> data) {
    return Entry(
      id: data['id'] as String?,
      userId: data['userId'] as String? ?? 'imported_user',
      type: EntryType.travel,
      date: DateTime.parse(data['date'] as String),
      from: data['departure'] as String? ?? data['from'] as String?,
      to: data['arrival'] as String? ?? data['to'] as String?,
      travelMinutes:
          (data['minutes'] as int?) ?? (data['travelMinutes'] as int?) ?? 0,
      notes: data['info'] as String? ?? data['notes'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  /// Validate import file before processing
  Future<ImportValidationResult> validateImportFile(String filePath) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _validateImportFileInternal(filePath),
        shouldRetry: (error) => false,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<ImportValidationResult> _validateImportFileInternal(
      String filePath) async {
    final file = File(filePath);
    final result = ImportValidationResult();

    if (!await file.exists()) {
      result.isValid = false;
      result.errors.add('File not found');
      return result;
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      result.isValid = false;
      result.errors.add('File is empty');
      return result;
    }

    if (fileSize > 10 * 1024 * 1024) {
      // 10MB limit
      result.isValid = false;
      result.errors.add('File is too large (maximum 10MB)');
      return result;
    }

    final extension = filePath.toLowerCase().split('.').last;

    try {
      if (extension == 'csv') {
        await _validateCSVFile(file, result);
      } else if (extension == 'json') {
        await _validateJSONFile(file, result);
      } else {
        result.isValid = false;
        result.errors
            .add('Unsupported file format. Only CSV and JSON are supported.');
      }
    } catch (error) {
      result.isValid = false;
      result.errors.add('Error reading file: $error');
    }

    return result;
  }

  Future<void> _validateCSVFile(
      File file, ImportValidationResult result) async {
    final content = await file.readAsString();
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      result.errors.add('CSV file is empty');
      return;
    }

    // Validate header
    if (!_isValidCSVHeader(lines.first)) {
      result.errors
          .add('Invalid CSV header. Expected: ${AppConstants.csvHeader}');
    }

    result.estimatedRecords = lines.length - 1; // Exclude header

    // Sample validation (check first few rows)
    final sampleSize = lines.length > 6 ? 5 : lines.length - 1;
    for (int i = 1; i <= sampleSize; i++) {
      try {
        _parseCSVLine(lines[i], i + 1);
      } catch (error) {
        result.warnings.add('Potential issue in line ${i + 1}: $error');
      }
    }

    result.isValid = result.errors.isEmpty;
  }

  Future<void> _validateJSONFile(
      File file, ImportValidationResult result) async {
    final content = await file.readAsString();

    try {
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!data.containsKey('entries')) {
        result.errors.add('JSON file missing required "entries" field');
        return;
      }

      final entries = data['entries'] as List<dynamic>;
      result.estimatedRecords = entries.length;

      // Sample validation
      final sampleSize = entries.length > 5 ? 5 : entries.length;
      for (int i = 0; i < sampleSize; i++) {
        try {
          _parseJSONEntry(entries[i] as Map<String, dynamic>);
        } catch (error) {
          result.warnings.add('Potential issue in entry ${i + 1}: $error');
        }
      }

      result.isValid = result.errors.isEmpty;
    } catch (error) {
      result.errors.add('Invalid JSON format: $error');
    }
  }

  /// Get import preview
  Future<ImportPreview> getImportPreview(String filePath,
      {int maxRows = 5}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getImportPreviewInternal(filePath, maxRows),
        shouldRetry: (error) => false,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<ImportPreview> _getImportPreviewInternal(
      String filePath, int maxRows) async {
    final file = File(filePath);
    final preview = ImportPreview();

    if (!await file.exists()) {
      throw ErrorHandler.handleValidationError('File not found');
    }

    final extension = filePath.toLowerCase().split('.').last;

    if (extension == 'csv') {
      await _generateCSVPreview(file, preview, maxRows);
    } else if (extension == 'json') {
      await _generateJSONPreview(file, preview, maxRows);
    } else {
      throw ErrorHandler.handleValidationError('Unsupported file format');
    }

    return preview;
  }

  Future<void> _generateCSVPreview(
      File file, ImportPreview preview, int maxRows) async {
    final content = await file.readAsString();
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) return;

    preview.headers = _parseCSVFields(lines.first);
    preview.totalRows = lines.length - 1;

    final dataLines = lines.skip(1).take(maxRows).toList();
    for (final line in dataLines) {
      preview.sampleRows.add(_parseCSVFields(line));
    }
  }

  Future<void> _generateJSONPreview(
      File file, ImportPreview preview, int maxRows) async {
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (!data.containsKey('entries')) return;

    final entries = data['entries'] as List<dynamic>;
    preview.totalRows = entries.length;

    if (entries.isNotEmpty) {
      final firstEntry = entries.first as Map<String, dynamic>;
      preview.headers = firstEntry.keys.toList();

      final sampleEntries = entries.take(maxRows).toList();
      for (final entry in sampleEntries) {
        final entryMap = entry as Map<String, dynamic>;
        preview.sampleRows.add(preview.headers
            .map((key) => entryMap[key]?.toString() ?? '')
            .toList());
      }
    }
  }
}

class ImportResult {
  int totalProcessed = 0;
  int successCount = 0;
  final List<ImportError> errors = [];

  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errorCount == 0 && successCount > 0;

  void addError(int lineNumber, String message) {
    errors.add(ImportError(lineNumber: lineNumber, message: message));
  }

  @override
  String toString() {
    return 'ImportResult(processed: $totalProcessed, success: $successCount, errors: $errorCount)';
  }
}

class ImportError {
  final int lineNumber;
  final String message;

  ImportError({required this.lineNumber, required this.message});

  @override
  String toString() => 'Line $lineNumber: $message';
}

class ImportValidationResult {
  bool isValid = true;
  int estimatedRecords = 0;
  final List<String> errors = [];
  final List<String> warnings = [];

  bool get hasWarnings => warnings.isNotEmpty;
}

class ImportPreview {
  List<String> headers = [];
  List<List<String>> sampleRows = [];
  int totalRows = 0;
}
