import 'dart:io';

void main() {
  final testPath = 'test/services/export_service_test.dart';
  var testContent = File(testPath).readAsStringSync();

  // 1. Add import for AppLocalizationsEn
  if (!testContent.contains(
      "import 'package:mobile_flutter/l10n/generated/app_localizations_en.dart';")) {
    testContent = testContent.replaceFirst(
        "import 'package:mobile_flutter/l10n/generated/app_localizations.dart';",
        "import 'package:mobile_flutter/l10n/generated/app_localizations.dart';\nimport 'package:mobile_flutter/l10n/generated/app_localizations_en.dart';");
  }

  // 2. Replace _testReportLabels with _testAppLocalizations
  final testLabelsRegex =
      RegExp(r'ReportExportLabels _testReportLabels\(\) \{[\s\S]*?\}\n');
  testContent = testContent.replaceAll(testLabelsRegex,
      'AppLocalizations _testAppLocalizations() => AppLocalizationsEn();\n');

  // 3. Replaces references
  testContent =
      testContent.replaceAll('_testReportLabels()', '_testAppLocalizations()');
  testContent = testContent.replaceAll('labels: labels,',
      't: labels,'); // We called it labels in local scope, we'll map to t
  testContent = testContent.replaceAll(
      'labels: _testAppLocalizations(),', 't: _testAppLocalizations(),');

  // 4. Update function calls missing t
  testContent = testContent.replaceAll(
      'ExportService.prepareExportData(entries)',
      'ExportService.prepareExportData(entries, t: AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareExportData([workEntry, travelEntry])',
      'ExportService.prepareExportData([workEntry, travelEntry], t: AppLocalizationsEn())');

  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData(entries)',
      'ExportService.prepareTravelMinimalExportData(entries, AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData([entry])',
      'ExportService.prepareTravelMinimalExportData([entry], AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData(<Entry>[])',
      'ExportService.prepareTravelMinimalExportData(<Entry>[], AppLocalizationsEn())');

  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(absences)',
      'ExportService.prepareLeaveMinimalExportData(absences, AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[])',
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[], AppLocalizationsEn())');

  // Fix header strings mismatch in tests:
  // The test expects _entryHeaders[i], where _entryHeaders is a hardcoded list in test.
  // Wait, let's just not touch the actual headers logic unless it fails, in which case we fix it manually. Actually _entryHeaders in test is a const list.
  // "Type", "Date" -> t.exportHeader_type, t.exportHeader_date
  // "Typ", "Datum" in SV. Since it uses AppLocalizationsEn, the english string will match perfectly.

  // Let's also look out for t.exportSummary_totalTrackedExcludes(t.export_summarySheetName)
  // Which replaces "Work/Travel = logged time. ... See Sammanfattning." Wait, the test might assert on this exact payrollNote string.
  // We'll see if a test fails.

  // Let's write the file.
  File(testPath).writeAsStringSync(testContent);
  print('Tests refactored');
}
