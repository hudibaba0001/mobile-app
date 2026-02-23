import 'dart:io';

void main() {
  // Update overview_tab.dart
  final overviewPath = 'lib/screens/reports/overview_tab.dart';
  var overview = File(overviewPath).readAsStringSync();

  // Remove _reportExportLabels method
  final relMethodRegex = RegExp(
      r'ReportExportLabels _reportExportLabels\(AppLocalizations t\) \{[\s\S]*?\}\n\n');
  overview = overview.replaceAll(relMethodRegex, '');

  // Replace references
  overview = overview.replaceAll('final labels = _reportExportLabels(t);', '');
  overview = overview.replaceAll('labels: labels,', 't: t,');

  File(overviewPath).writeAsStringSync(overview);

  // Update reports_screen.dart
  final reportsPath = 'lib/screens/reports_screen.dart';
  var reports = File(reportsPath).readAsStringSync();

  // Remove import if exists
  reports = reports.replaceAll("import '../services/export_service.dart';",
      "import '../services/export_service.dart';\nimport '../l10n/generated/app_localizations.dart';"); // Just in case, it might have it already

  reports = reports.replaceAll(
      'await ExportService.exportTravelMinimalToExcel(\n                    entries: entries, fileName: fileName)',
      'await ExportService.exportTravelMinimalToExcel(\n                    entries: entries, fileName: fileName, t: t)');
  reports = reports.replaceAll(
      'await ExportService.exportTravelMinimalToCSV(\n                    entries: entries, fileName: fileName)',
      'await ExportService.exportTravelMinimalToCSV(\n                    entries: entries, fileName: fileName, t: t)');
  reports = reports.replaceAll(
      'await ExportService.exportLeaveMinimalToExcel(\n                    absences: absences, fileName: fileName)',
      'await ExportService.exportLeaveMinimalToExcel(\n                    absences: absences, fileName: fileName, t: t)');
  reports = reports.replaceAll(
      'await ExportService.exportLeaveMinimalToCSV(\n                    absences: absences, fileName: fileName)',
      'await ExportService.exportLeaveMinimalToCSV(\n                    absences: absences, fileName: fileName, t: t)');
  reports = reports.replaceAll(
      'await ExportService.exportEntriesToExcel(\n                    entries: entries, fileName: fileName)',
      'await ExportService.exportEntriesToExcel(\n                    entries: entries, fileName: fileName, t: t)');
  reports = reports.replaceAll(
      'await ExportService.exportEntriesToCSV(\n                    entries: entries, fileName: fileName)',
      'await ExportService.exportEntriesToCSV(\n                    entries: entries, fileName: fileName, t: t)');

  File(reportsPath).writeAsStringSync(reports);
  print('Callers refactored');
}
