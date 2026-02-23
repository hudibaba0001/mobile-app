import 'dart:io';

void main() {
  final testPath = 'test/services/export_service_test.dart';
  var testContent = File(testPath).readAsStringSync();

  // Add the imports at the top
  if (!testContent.contains(
      "import 'package:myapp/l10n/generated/app_localizations_en.dart';")) {
    testContent = testContent.replaceFirst(
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:flutter_test/flutter_test.dart';\nimport 'package:myapp/l10n/generated/app_localizations.dart';\nimport 'package:myapp/l10n/generated/app_localizations_en.dart';");
  }

  // Also fix any syntax issue the analyzer was complaining about
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData(entries, AppLocalizationsEn())',
      'ExportService.prepareTravelMinimalExportData(entries, t: AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData([entry], AppLocalizationsEn())',
      'ExportService.prepareTravelMinimalExportData([entry], t: AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData(<Entry>[], AppLocalizationsEn())',
      'ExportService.prepareTravelMinimalExportData(<Entry>[], t: AppLocalizationsEn())');

  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(absences, AppLocalizationsEn())',
      'ExportService.prepareLeaveMinimalExportData(absences, t: AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[], AppLocalizationsEn())',
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[], t: AppLocalizationsEn())');

  File(testPath).writeAsStringSync(testContent);
  print('Tests imports fixed');
}
