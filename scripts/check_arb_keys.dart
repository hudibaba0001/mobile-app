// ignore_for_file: avoid_print
/// Script to check that all keys from app_en.arb exist in app_sv.arb
/// Run with: dart run scripts/check_arb_keys.dart
library;


import 'dart:convert';
import 'dart:io';

bool _setsEqual(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final svFile = File('lib/l10n/app_sv.arb');

  if (!enFile.existsSync()) {
    print('❌ Error: app_en.arb not found');
    exit(1);
  }
  if (!svFile.existsSync()) {
    print('❌ Error: app_sv.arb not found');
    exit(1);
  }

  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final svJson = jsonDecode(svFile.readAsStringSync()) as Map<String, dynamic>;

  // Extract user-defined keys (exclude metadata starting with @@)
  final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
  final svKeys = svJson.keys.where((k) => !k.startsWith('@')).toSet();

  final missingInSv = enKeys.difference(svKeys);
  final extraInSv = svKeys.difference(enKeys);

  var hasErrors = false;

  if (missingInSv.isNotEmpty) {
    print('❌ Missing in app_sv.arb (${missingInSv.length} keys):');
    for (final key in missingInSv) {
      print('   - $key');
    }
    hasErrors = true;
  }

  if (extraInSv.isNotEmpty) {
    print('⚠️  Extra keys in app_sv.arb (not in English):');
    for (final key in extraInSv) {
      print('   - $key');
    }
    // Extra keys are warnings, not errors
  }

  // Check for placeholder mismatches
  print('\n🔍 Checking placeholder consistency...');
  var placeholderErrors = 0;
  
  for (final key in enKeys.intersection(svKeys)) {
    final enValue = enJson[key] as String?;
    final svValue = svJson[key] as String?;
    
    if (enValue == null || svValue == null) continue;
    
    // Extract placeholders like {name}, {count}, etc.
    // Exclude ICU plural/select syntax placeholders
    final enPlaceholders = RegExp(r'\{(\w+)\}').allMatches(enValue).map((m) => m.group(1)!).toSet();
    final svPlaceholders = RegExp(r'\{(\w+)\}').allMatches(svValue).map((m) => m.group(1)!).toSet();
    
    // Skip if both are empty (no placeholders)
    if (enPlaceholders.isEmpty && svPlaceholders.isEmpty) continue;
    
    if (!_setsEqual(enPlaceholders, svPlaceholders)) {
      print('   ❌ Placeholder mismatch in "$key":');
      print('      EN: $enPlaceholders');
      print('      SV: $svPlaceholders');
      placeholderErrors++;
    }
  }

  if (placeholderErrors == 0) {
    print('   ✅ All placeholders match');
  } else {
    hasErrors = true;
  }

  // Summary
  print('\n📊 Summary:');
  print('   English keys: ${enKeys.length}');
  print('   Swedish keys: ${svKeys.length}');
  
  if (!hasErrors) {
    print('\n✅ All localization keys are in sync!');
    exit(0);
  } else {
    print('\n❌ Localization errors found. Please fix before merging.');
    exit(1);
  }
}
