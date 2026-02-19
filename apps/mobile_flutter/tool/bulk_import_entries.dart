import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const _chunkSize = 200;

Future<void> main(List<String> args) async {
  try {
    final config = _parseArgs(args);
    final rows = await _readRows(config.csvPath);
    final prepared = _preparePayload(rows, config.userId);

    stdout.writeln('Parsed ${prepared.totalRows} rows from ${config.csvPath}.');
    stdout.writeln('Entries: ${prepared.entries.length}');
    stdout.writeln('Work shifts: ${prepared.workShifts.length}');
    stdout.writeln('Travel segments: ${prepared.travelSegments.length}');

    if (config.dryRun) {
      stdout.writeln('Dry run enabled. No rows were inserted.');
      return;
    }

    await _insertRows(
      supabaseUrl: config.supabaseUrl,
      serviceRoleKey: config.serviceRoleKey,
      table: 'entries',
      rows: prepared.entries,
    );

    await _insertRows(
      supabaseUrl: config.supabaseUrl,
      serviceRoleKey: config.serviceRoleKey,
      table: 'work_shifts',
      rows: prepared.workShifts,
    );

    await _insertRows(
      supabaseUrl: config.supabaseUrl,
      serviceRoleKey: config.serviceRoleKey,
      table: 'travel_segments',
      rows: prepared.travelSegments,
    );

    stdout.writeln('Bulk import complete.');
  } on _CliException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printUsage();
    exitCode = 1;
  } catch (e, stackTrace) {
    stderr.writeln('Unexpected error: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

class _Config {
  final String csvPath;
  final String userId;
  final String supabaseUrl;
  final String serviceRoleKey;
  final bool dryRun;

  _Config({
    required this.csvPath,
    required this.userId,
    required this.supabaseUrl,
    required this.serviceRoleKey,
    required this.dryRun,
  });
}

class _PreparedPayload {
  final int totalRows;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> workShifts;
  final List<Map<String, dynamic>> travelSegments;

  _PreparedPayload({
    required this.totalRows,
    required this.entries,
    required this.workShifts,
    required this.travelSegments,
  });
}

class _CliException implements Exception {
  final String message;
  _CliException(this.message);
}

_Config _parseArgs(List<String> args) {
  final values = <String, String>{};
  var dryRun = false;

  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }

    if (!arg.startsWith('--') || !arg.contains('=')) {
      throw _CliException('Invalid argument "$arg".');
    }

    final idx = arg.indexOf('=');
    final key = arg.substring(2, idx).trim();
    final value = arg.substring(idx + 1).trim();
    values[key] = value;
  }

  final csvPath = values['csv'];
  final userId = values['user-id'];

  final supabaseUrl =
      values['supabase-url'] ?? Platform.environment['SUPABASE_URL'];
  final serviceRoleKey = values['service-role-key'] ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (csvPath == null || csvPath.isEmpty) {
    throw _CliException('Missing --csv=<path>.');
  }
  if (userId == null || userId.isEmpty) {
    throw _CliException('Missing --user-id=<uuid>.');
  }
  if ((supabaseUrl == null || supabaseUrl.isEmpty) && !dryRun) {
    throw _CliException(
      'Missing Supabase URL. Use --supabase-url=... or set SUPABASE_URL.',
    );
  }
  if ((serviceRoleKey == null || serviceRoleKey.isEmpty) && !dryRun) {
    throw _CliException(
      'Missing service role key. Use --service-role-key=... or set SUPABASE_SERVICE_ROLE_KEY.',
    );
  }

  final rawUrl = supabaseUrl ?? '';
  final normalizedUrl =
      rawUrl.endsWith('/') ? rawUrl.substring(0, rawUrl.length - 1) : rawUrl;

  return _Config(
    csvPath: csvPath,
    userId: userId,
    supabaseUrl: normalizedUrl,
    serviceRoleKey: serviceRoleKey ?? '',
    dryRun: dryRun,
  );
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/bulk_import_entries.dart \\
    --csv=tool/templates/bulk_entries_template.csv \\
    --user-id=<target-user-uuid> \\
    --supabase-url=https://<project-ref>.supabase.co \\
    --service-role-key=<service-role-key> \\
    [--dry-run]

CSV columns:
  type,date,start_time,end_time,unpaid_break_minutes,location,from_location,to_location,travel_minutes,notes

Rules:
  - type must be work or travel
  - date must be YYYY-MM-DD
  - work rows require start_time and end_time (HH:mm or ISO datetime)
  - travel rows require from_location, to_location, and travel_minutes
''');
}

Future<List<_RawCsvRow>> _readRows(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw _CliException('CSV file not found: $path');
  }

  final raw = await file.readAsString();
  final csv = raw.replaceFirst('\uFEFF', '');

  final delimiter = _detectDelimiter(csv);
  var parsed = CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(
    csv,
    fieldDelimiter: delimiter,
  );

  if (parsed.length <= 1) {
    parsed = CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\r\n',
    ).convert(
      csv,
      fieldDelimiter: delimiter,
    );
  }

  if (parsed.length <= 1) {
    parsed = CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\r',
    ).convert(
      csv,
      fieldDelimiter: delimiter,
    );
  }

  if (parsed.isEmpty) {
    throw _CliException('CSV is empty.');
  }

  final header = parsed.first
      .map((value) => value.toString().trim().toLowerCase())
      .toList();

  final rows = <_RawCsvRow>[];
  for (var i = 1; i < parsed.length; i++) {
    final row = parsed[i];
    final rowNumber = i + 1;

    final isBlank = row.every((cell) => cell.toString().trim().isEmpty);
    if (isBlank) {
      continue;
    }

    final values = <String, String>{};
    for (var j = 0; j < header.length; j++) {
      final key = header[j];
      final value = j < row.length ? row[j].toString().trim() : '';
      values[key] = value;
    }

    rows.add(_RawCsvRow(rowNumber: rowNumber, values: values));
  }

  if (rows.isEmpty) {
    throw _CliException('CSV has no data rows.');
  }

  return rows;
}

String _detectDelimiter(String csv) {
  final lines = const LineSplitter().convert(csv);
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final commas = ','.allMatches(trimmed).length;
    final semicolons = ';'.allMatches(trimmed).length;
    return semicolons > commas ? ';' : ',';
  }
  return ',';
}

class _RawCsvRow {
  final int rowNumber;
  final Map<String, String> values;

  _RawCsvRow({required this.rowNumber, required this.values});
}

_PreparedPayload _preparePayload(List<_RawCsvRow> rawRows, String userId) {
  final entries = <Map<String, dynamic>>[];
  final workShifts = <Map<String, dynamic>>[];
  final travelSegments = <Map<String, dynamic>>[];

  for (final row in rawRows) {
    final type = _value(row, 'type')?.toLowerCase();
    if (type != 'work' && type != 'travel') {
      throw _CliException(
        'Row ${row.rowNumber}: type must be "work" or "travel".',
      );
    }

    final date = _parseDate(_value(row, 'date'), row.rowNumber);
    final notes = _value(row, 'notes') ?? _value(row, 'note');

    final entryId = _uuid.v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    entries.add({
      'id': entryId,
      'user_id': userId,
      'type': type,
      'date': date,
      'notes': notes,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    if (type == 'work') {
      final start = _parseWorkDateTime(
        _value(row, 'start_time'),
        date,
        row.rowNumber,
        fieldName: 'start_time',
      );
      var end = _parseWorkDateTime(
        _value(row, 'end_time'),
        date,
        row.rowNumber,
        fieldName: 'end_time',
      );

      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      final breakMinutes =
          _parseInt(_value(row, 'unpaid_break_minutes') ?? '0', row.rowNumber,
              fieldName: 'unpaid_break_minutes');

      final location = _value(row, 'location') ?? _value(row, 'shift_location');

      workShifts.add({
        'id': _uuid.v4(),
        'entry_id': entryId,
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end.toUtc().toIso8601String(),
        'location': location,
        'unpaid_break_minutes': breakMinutes,
        'notes': notes,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
      continue;
    }

    final from = _value(row, 'from_location') ?? _value(row, 'from');
    final to = _value(row, 'to_location') ?? _value(row, 'to');
    final minutesRaw = _value(row, 'travel_minutes') ?? _value(row, 'minutes');

    if (from == null || from.isEmpty) {
      throw _CliException(
        'Row ${row.rowNumber}: travel row requires from_location.',
      );
    }
    if (to == null || to.isEmpty) {
      throw _CliException(
        'Row ${row.rowNumber}: travel row requires to_location.',
      );
    }

    final minutes =
        _parseInt(minutesRaw, row.rowNumber, fieldName: 'travel_minutes');

    travelSegments.add({
      'id': _uuid.v4(),
      'entry_id': entryId,
      'from_location': from,
      'to_location': to,
      'travel_minutes': minutes,
      'segment_order': 1,
      'total_segments': 1,
      'created_at': nowIso,
      'updated_at': nowIso,
    });
  }

  return _PreparedPayload(
    totalRows: rawRows.length,
    entries: entries,
    workShifts: workShifts,
    travelSegments: travelSegments,
  );
}

String _parseDate(String? value, int rowNumber) {
  if (value == null || value.isEmpty) {
    throw _CliException('Row $rowNumber: missing date.');
  }

  final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!pattern.hasMatch(value)) {
    throw _CliException('Row $rowNumber: date must be YYYY-MM-DD.');
  }

  return value;
}

DateTime _parseWorkDateTime(
  String? raw,
  String date,
  int rowNumber, {
  required String fieldName,
}) {
  if (raw == null || raw.isEmpty) {
    throw _CliException('Row $rowNumber: missing $fieldName.');
  }

  final hhmm = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
  if (hhmm.hasMatch(raw)) {
    final normalized = raw.length == 5 ? '$raw:00' : raw;
    return DateTime.parse('${date}T$normalized');
  }

  try {
    final parsed = DateTime.parse(raw);
    return parsed.isUtc ? parsed.toLocal() : parsed;
  } catch (_) {
    throw _CliException(
      'Row $rowNumber: invalid $fieldName "$raw". Use HH:mm or ISO datetime.',
    );
  }
}

int _parseInt(String? raw, int rowNumber, {required String fieldName}) {
  if (raw == null || raw.isEmpty) {
    throw _CliException('Row $rowNumber: missing $fieldName.');
  }

  final parsed = int.tryParse(raw);
  if (parsed == null) {
    throw _CliException('Row $rowNumber: $fieldName must be an integer.');
  }
  return parsed;
}

String? _value(_RawCsvRow row, String key) {
  final value = row.values[key.toLowerCase()];
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

Future<void> _insertRows({
  required String supabaseUrl,
  required String serviceRoleKey,
  required String table,
  required List<Map<String, dynamic>> rows,
}) async {
  if (rows.isEmpty) {
    return;
  }

  final endpoint = Uri.parse('$supabaseUrl/rest/v1/$table');
  final client = http.Client();

  try {
    for (var i = 0; i < rows.length; i += _chunkSize) {
      final end = math.min(i + _chunkSize, rows.length);
      final chunk = rows.sublist(i, end);

      final response = await client.post(
        endpoint,
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(chunk),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _CliException(
          'Insert into "$table" failed (${response.statusCode}): ${response.body}',
        );
      }

      stdout.writeln('Inserted ${chunk.length} rows into $table.');
    }
  } finally {
    client.close();
  }
}
