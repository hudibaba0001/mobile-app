import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final svFile = File('lib/l10n/app_sv.arb');

  final enData = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final svData = json.decode(svFile.readAsStringSync()) as Map<String, dynamic>;

  final enKeys = enData.keys.where((k) => !k.startsWith('@')).toSet();
  final svKeys = svData.keys.where((k) => !k.startsWith('@')).toSet();

  final missingInSv = enKeys.difference(svKeys);
  print('Missing in SV:');
  for (final key in missingInSv) {
    print('- $key: ${enData[key]}');
  }

  final missingInEn = svKeys.difference(enKeys);
  print('\nMissing in EN:');
  for (final key in missingInEn) {
    print('- $key: ${svData[key]}');
  }
}
