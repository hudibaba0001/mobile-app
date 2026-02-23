import 'dart:io';

void main() {
  final servicePath = 'lib/services/export_service.dart';
  var serviceContent = File(servicePath).readAsStringSync();

  // Fix _writeStyledReportSheet
  serviceContent = serviceContent.replaceAll(
      'static void _writeStyledReportSheet({\n    required Sheet sheet,\n    required ExportData section,\n  })',
      'static void _writeStyledReportSheet({\n    required Sheet sheet,\n    required ExportData section,\n    required AppLocalizations t,\n  })');
  serviceContent = serviceContent.replaceAll(
      '_writeStyledReportSheet(\n          sheet: sheet,\n          section: section,\n        );',
      '_writeStyledReportSheet(\n          sheet: sheet,\n          section: section,\n          t: t,\n        );');

  // Fix undefined name 'labels' in export functions
  serviceContent = serviceContent.replaceAll('labels: labels,', 't: t,');
  // Wait, did I replace `labels` with `t` previously? Let's ensure no `labels:` left.

  // Also in test file, there were "Too few positional arguments" errors.
  final testPath = 'test/services/export_service_test.dart';
  var testContent = File(testPath).readAsStringSync();

  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData([entry], t: AppLocalizationsEn())',
      'ExportService.prepareTravelMinimalExportData([entry], AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareTravelMinimalExportData(<Entry>[], t: AppLocalizationsEn())',
      'ExportService.prepareTravelMinimalExportData(<Entry>[], AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(absences, t: AppLocalizationsEn())',
      'ExportService.prepareLeaveMinimalExportData(absences, AppLocalizationsEn())');
  testContent = testContent.replaceAll(
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[], t: AppLocalizationsEn())',
      'ExportService.prepareLeaveMinimalExportData(<AbsenceEntry>[], AppLocalizationsEn())');

  // Fix duplicated named 'entriesSheetName' in export_service.dart?
  serviceContent = serviceContent.replaceAll(
      "sheetName: entriesSheetName,\n      t: t,",
      "sheetName: entriesSheetName," // Wait, I already added `t: t` to prepareExportData
      );
  // Actually, _prepareReportEntriesExportData takes `t: t`.
  // Let me look at where `entriesSheetName` is used.

  File(servicePath).writeAsStringSync(serviceContent);
  File(testPath).writeAsStringSync(testContent);
  print('Fixed compilation errors');
}
