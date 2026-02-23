import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/l10n/app_sv.arb');
  final content = file.readAsStringSync();

  // Custom simple parser to find duplicate keys with different values
  final map = <String, String>{};

  // Fast and dirty duplicate elimination by jsonDecode
  try {
    final Map<String, dynamic> data = json.decode(content);
    final encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(data);
    file.writeAsStringSync(formatted + '\n');
    print('Cleaned app_sv.arb successfully.');
  } catch (e) {
    print('Error decoding JSON: $e');
  }
}
