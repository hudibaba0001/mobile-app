import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _reportsFolderName = 'task_reports';

Future<void> main(List<String> args) async {
  final root = _resolveProjectRoot();
  final reportsDir =
      Directory('${root.path}${Platform.pathSeparator}$_reportsFolderName');
  if (!reportsDir.existsSync()) {
    reportsDir.createSync(recursive: true);
  }

  final nextNumber = _nextReportNumber(reportsDir);
  final title = _argValue(args, '--title') ?? 'Task $nextNumber';
  final detailsArg = _argValue(args, '--details');
  final detailsFromStdin = await _readDetailsFromStdin();
  final details = _normalizeDetails(detailsArg ?? detailsFromStdin);

  final reportPath =
      '${reportsDir.path}${Platform.pathSeparator}$nextNumber.md';
  final reportFile = File(reportPath);
  final timestamp = DateTime.now().toIso8601String();

  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('- Number: $nextNumber')
    ..writeln('- Created: $timestamp')
    ..writeln('- File: `$nextNumber.md`')
    ..writeln()
    ..writeln('## Details')
    ..writeln()
    ..writeln(details);

  reportFile.writeAsStringSync(buffer.toString());
  stdout.writeln(reportFile.path);
}

Directory _resolveProjectRoot() {
  var current = Directory.current.absolute;

  if (_looksLikeProjectRoot(current)) {
    return current;
  }

  while (true) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not find Flutter project root. Run from apps/mobile_flutter or inside it.',
      );
    }
    if (_looksLikeProjectRoot(parent)) {
      return parent;
    }
    current = parent;
  }
}

bool _looksLikeProjectRoot(Directory directory) {
  final pubspec =
      File('${directory.path}${Platform.pathSeparator}pubspec.yaml');
  return pubspec.existsSync();
}

int _nextReportNumber(Directory reportsDir) {
  final numberPattern = RegExp(r'^\d+$');
  final numbers = reportsDir
      .listSync()
      .whereType<File>()
      .map((file) => _fileNameWithoutExtension(file.path))
      .where((name) => numberPattern.hasMatch(name))
      .map(int.parse)
      .toList();

  if (numbers.isEmpty) {
    return 1;
  }
  return numbers.reduce(max) + 1;
}

String _fileNameWithoutExtension(String path) {
  final separator = Platform.pathSeparator;
  final name = path.split(separator).last;
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0) {
    return name;
  }
  return name.substring(0, dotIndex);
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1) {
    return null;
  }
  final valueIndex = index + 1;
  if (valueIndex >= args.length) {
    return null;
  }
  return args[valueIndex];
}

Future<String?> _readDetailsFromStdin() async {
  if (stdin.hasTerminal) {
    return null;
  }
  final content = await stdin.transform(utf8.decoder).join();
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _normalizeDetails(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '_No details provided._';
  }
  return value.trim();
}
