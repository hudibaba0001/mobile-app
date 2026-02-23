import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/l10n/app_sv.arb');
  final lines = file.readAsLinesSync();
  final seenKeys = <String>{};
  final uniqueLines = <String>[];

  // We process line by line. We assume simple formatting like:
  // "key": "value",
  // We'll keep the first occurrence.
  final keyRegex = RegExp(r'^\s*"([^"]+)"\s*:');

  for (final line in lines) {
    final match = keyRegex.firstMatch(line);
    if (match != null) {
      final key = match.group(1)!;
      if (seenKeys.contains(key)) {
        print('Removing duplicate key: $key');
        // skip this line, and if it's the start of an @ placeholder, we should skip until }
        // Wait, regular regex is risky. Let's just use jsonDecode.
      } else {
        seenKeys.add(key);
      }
    }
  }
}
