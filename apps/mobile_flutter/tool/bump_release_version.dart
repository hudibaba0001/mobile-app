import 'dart:io';

const String _pubspecPath = 'pubspec.yaml';
final RegExp _versionLinePattern =
    RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$');

void main(List<String> args) {
  final bool showOnly = args.contains('--show');
  final int? setBuild = _readIntArg(args, '--set-build');
  final bool bump = args.contains('--bump') || (!showOnly && setBuild == null);

  if (showOnly && (setBuild != null || args.contains('--bump'))) {
    stderr.writeln('Use --show alone.');
    exitCode = 2;
    return;
  }
  if (setBuild != null && args.contains('--bump')) {
    stderr.writeln('Use either --set-build <N> or --bump.');
    exitCode = 2;
    return;
  }

  final file = File(_pubspecPath);
  if (!file.existsSync()) {
    stderr
        .writeln('Could not find $_pubspecPath. Run from apps/mobile_flutter.');
    exitCode = 2;
    return;
  }

  final original = file.readAsStringSync();
  final lines = original.split('\n');
  int versionIndex = -1;
  String buildName = '';
  int buildNumber = -1;

  for (int i = 0; i < lines.length; i++) {
    final match = _versionLinePattern.firstMatch(lines[i].trim());
    if (match == null) continue;
    versionIndex = i;
    buildName = match.group(1)!;
    buildNumber = int.parse(match.group(2)!);
    break;
  }

  if (versionIndex == -1) {
    stderr.writeln('Could not parse version line in $_pubspecPath.');
    exitCode = 2;
    return;
  }

  if (showOnly) {
    stdout.writeln('Current version: $buildName+$buildNumber');
    return;
  }

  final int nextBuild = setBuild ?? (bump ? buildNumber + 1 : buildNumber);
  if (nextBuild <= buildNumber && setBuild == null) {
    stderr.writeln('Next build number must be greater than current.');
    exitCode = 2;
    return;
  }
  if (nextBuild < 1) {
    stderr.writeln('Build number must be >= 1.');
    exitCode = 2;
    return;
  }

  lines[versionIndex] = 'version: $buildName+$nextBuild';
  file.writeAsStringSync(lines.join('\n'));

  stdout.writeln(
      'Updated version: $buildName+$buildNumber -> $buildName+$nextBuild');
  stdout.writeln(
      'Android versionCode now: $nextBuild (Play Console requires unique increasing value).');
}

int? _readIntArg(List<String> args, String key) {
  final int index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) {
    stderr.writeln('Missing value for $key');
    exitCode = 2;
    return null;
  }
  final parsed = int.tryParse(args[index + 1]);
  if (parsed == null) {
    stderr.writeln('Invalid integer for $key: ${args[index + 1]}');
    exitCode = 2;
  }
  return parsed;
}
