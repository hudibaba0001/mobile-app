import 'dart:io';

void replaceInFile(String path, Map<Pattern, String> replacements) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  replacements.forEach((pattern, replacement) {
    content = content.replaceAll(pattern, replacement);
  });

  file.writeAsStringSync(content);
}

void main() {
  final servicePath = 'lib/services/export_service.dart';
  var serviceContent = File(servicePath).readAsStringSync();

  // 1. Remove ReportExportLabels class definition
  final relRegex = RegExp(r'class ReportExportLabels \{[\s\S]*?\}\s*');
  serviceContent = serviceContent.replaceAll(relRegex, '');

  // 2. Add AppLocalizations import to export_service.dart
  if (!serviceContent
      .contains('import \'../l10n/generated/app_localizations.dart\';')) {
    serviceContent = serviceContent.replaceFirst("import 'xlsx_exporter.dart';",
        "import 'xlsx_exporter.dart';\nimport '../l10n/generated/app_localizations.dart';");
  }

  // 3. Replace _entryExportHeaders
  serviceContent = serviceContent.replaceAll(
      RegExp(r'static const List<String> _entryExportHeaders = \[[^\]]*\];'),
      '''static List<String> _entryExportHeaders(AppLocalizations t) => [
    t.exportHeader_type,
    t.exportHeader_date,
    t.exportHeader_from,
    t.exportHeader_to,
    t.exportHeader_travelMinutes,
    t.exportHeader_travelDistance,
    t.exportHeader_shiftNumber,
    t.exportHeader_shiftStart,
    t.exportHeader_shiftEnd,
    t.exportHeader_spanMinutes,
    t.exportHeader_unpaidBreakMinutes,
    t.exportHeader_workedMinutes,
    t.exportHeader_workedHours,
    t.exportHeader_shiftLocation,
    t.exportHeader_shiftNotes,
    t.exportHeader_entryNotes,
    t.exportHeader_createdAt,
    t.exportHeader_updatedAt,
    t.exportHeader_holidayWork,
    t.exportHeader_holidayName,
  ];''');

  // 4. Update references to _entryExportHeaders
  serviceContent = serviceContent.replaceAll(
      '_entryExportHeaders.length', '_entryExportHeaders(t).length');
  serviceContent = serviceContent.replaceAll(
      'List<String>.from(_entryExportHeaders)', '_entryExportHeaders(t)');
  serviceContent = serviceContent.replaceAll(
      'row.length == _entryExportHeaders',
      'row.length == _entryExportHeaders(t)');
  serviceContent = serviceContent.replaceAll('row.length < _entryExportHeaders',
      'row.length < _entryExportHeaders(t)');

  // 5. Update signatures requiring AppLocalizations
  serviceContent = serviceContent.replaceAllMapped(
      RegExp(
          r'static ExportData prepareExportData\(\s*List<Entry> entries,\s*\{\s*ReportSummary\? summary,\s*\}\)'),
      (m) =>
          'static ExportData prepareExportData(List<Entry> entries, {ReportSummary? summary, required AppLocalizations t})');

  // Add `t` to all internal method calls to prepareExportData
  serviceContent = serviceContent.replaceAll(
      'prepareExportData(\n      summary.filteredEntries,\n      summary: summary,\n    );',
      'prepareExportData(summary.filteredEntries, summary: summary, t: t);');

  // Change _leaveTypeForExport signature
  serviceContent = serviceContent.replaceAll(
      'static String _leaveTypeForExport(AbsenceType type)',
      'static String _leaveTypeForExport(AbsenceType type, AppLocalizations t)');
  serviceContent = serviceContent.replaceAll(
      '_leaveTypeForExport(absence.type)',
      '_leaveTypeForExport(absence.type, t)');
  serviceContent = serviceContent.replaceAll(
      '_leaveTypeForExport(leave.type)', '_leaveTypeForExport(leave.type, t)');

  // Strings in _leaveTypeForExport
  serviceContent =
      serviceContent.replaceAll("'Leave (Sick)'", "t.export_leaveSick");
  serviceContent = serviceContent.replaceAll("'VAB'", "t.export_leaveVab");
  serviceContent = serviceContent.replaceAll(
      "'Leave (Paid Vacation)'", "t.export_leavePaidVacation");
  serviceContent =
      serviceContent.replaceAll("'Obetald frånvaro'", "t.export_leaveUnpaid");
  serviceContent =
      serviceContent.replaceAll("'Leave (Unknown)'", "t.export_leaveUnknown");

  // _newEntryExportRow
  serviceContent = serviceContent.replaceAll(
      'static List<dynamic> _newEntryExportRow(Entry entry)',
      'static List<dynamic> _newEntryExportRow(Entry entry, AppLocalizations t)');
  serviceContent = serviceContent.replaceAll(
      '_newEntryExportRow(entry)', '_newEntryExportRow(entry, t)');

  // _normalizeEntryExportRow
  serviceContent = serviceContent.replaceAll(
      'static List<dynamic> _normalizeEntryExportRow(List<dynamic> row)',
      'static List<dynamic> _normalizeEntryExportRow(List<dynamic> row, AppLocalizations t)');
  serviceContent = serviceContent.replaceAll(
      '_normalizeEntryExportRow(row)', '_normalizeEntryExportRow(row, t)');
  serviceContent = serviceContent.replaceAll(
      '_normalizeEntryExportRow(_newEntryExportRow(entry, t), t)',
      '_normalizeEntryExportRow(_newEntryExportRow(entry, t), t)');
  serviceContent = serviceContent.replaceAll(
      '_normalizeEntryExportRow(summaryRow)',
      '_normalizeEntryExportRow(summaryRow, t)');
  serviceContent = serviceContent.replaceAll(
      '_normalizeEntryExportRow(totalsRow)',
      '_normalizeEntryExportRow(totalsRow, t)');

  // 'Yes' / 'No' / 'Paid' / 'Unpaid'
  serviceContent = serviceContent.replaceAll(
      "entry.isHolidayWork ? 'Yes' : 'No'",
      "entry.isHolidayWork ? t.export_yes : t.export_no");
  serviceContent = serviceContent.replaceAll(
      "absence.isPaid ? 'Paid' : 'Unpaid'",
      "absence.isPaid ? t.export_paid : t.export_unpaid");

  // prepareTravelMinimalExportData
  serviceContent = serviceContent.replaceAll(
      'static ExportData prepareTravelMinimalExportData(List<Entry> entries) {',
      'static ExportData prepareTravelMinimalExportData(List<Entry> entries, AppLocalizations t) {');
  // _travelMinimalHeaders
  serviceContent = serviceContent.replaceAll(
      RegExp(r'static const List<String> _travelMinimalHeaders = \[[^\]]*\];'),
      "static List<String> _travelMinimalHeaders(AppLocalizations t) => [t.exportHeader_date, t.exportHeader_from, t.exportHeader_to, t.exportHeader_minutes, t.exportHeader_notes];");
  serviceContent = serviceContent.replaceAll(
      'List<String>.from(_travelMinimalHeaders)', '_travelMinimalHeaders(t)');

  // prepareLeaveMinimalExportData
  serviceContent = serviceContent.replaceAll(
      'static ExportData prepareLeaveMinimalExportData(List<AbsenceEntry> absences) {',
      'static ExportData prepareLeaveMinimalExportData(List<AbsenceEntry> absences, AppLocalizations t) {');
  serviceContent = serviceContent.replaceAll(
      RegExp(r'static const List<String> _leaveMinimalHeaders = \[[^\]]*\];'),
      "static List<String> _leaveMinimalHeaders(AppLocalizations t) => [t.exportHeader_date, t.exportHeader_type, t.exportHeader_minutes, t.exportHeader_paidUnpaid];");
  serviceContent = serviceContent.replaceAll(
      'List<String>.from(_leaveMinimalHeaders)', '_leaveMinimalHeaders(t)');

  // TOTAL
  serviceContent = serviceContent.replaceAll("['TOTAL',", "[t.export_total,");
  serviceContent = serviceContent.replaceAll(
      "row[_colType] = 'TOTAL';", "row[_colType] = t.export_total;");
  serviceContent = serviceContent.replaceAll(
      "'TOTAL (tracked only)'", "t.exportSummary_totalTrackedOnly");
  serviceContent = serviceContent.replaceAll("summaryRow[_colType] = 'TOTAL'",
      "summaryRow[_colType] = t.export_total");
  serviceContent = serviceContent.replaceAll(
      "summaryRow[_colEntryNotes] = 'TOTAL'",
      "summaryRow[_colEntryNotes] = t.export_total");
  serviceContent = serviceContent.replaceAll(
      "row[_colHolidayWork] = 'No'", "row[_colHolidayWork] = t.export_no");

  // _prepareReportEntriesExportData
  serviceContent = serviceContent.replaceAll(
      'static ExportData _prepareReportEntriesExportData({',
      'static ExportData _prepareReportEntriesExportData({\n    required AppLocalizations t,');

  // Paid leave credit
  serviceContent = serviceContent.replaceAll(
      "'Paid leave credit: \${_formatUnsignedHours(leaveMinutes)}h (not worked)'",
      "t.exportSummary_paidLeaveCreditNote(_formatUnsignedHours(leaveMinutes))");

  // _prepareSummarySheet
  serviceContent = serviceContent.replaceAll(
      'static ExportData _prepareSummarySheet({',
      'static ExportData _prepareSummarySheet({\n    required AppLocalizations t,');
  serviceContent =
      serviceContent.replaceAll('required ReportExportLabels labels,', '');
  serviceContent = serviceContent.replaceAll(
      "'Generated at'", "t.exportSummary_generatedAt");
  serviceContent = serviceContent.replaceAll(
      "'Tracked work'", "t.exportSummary_trackedWork");
  serviceContent = serviceContent.replaceAll(
      "'Tracked travel'", "t.exportSummary_trackedTravel");
  serviceContent = serviceContent.replaceAll(
      "'Balance offsets'", "t.exportSummary_balanceOffsets");
  serviceContent = serviceContent.replaceAll(
      "'Manual adjustments'", "t.exportSummary_manualAdjustments");
  serviceContent = serviceContent.replaceAll(
      "'Contract settings'", "t.exportSummary_contractSettings");

  // Report period in _prepareSummarySheet - this wasn't in arb but keeping it as is or hardcoded is fine for now, wait I'll just change labels to t
  serviceContent = serviceContent.replaceAll('labels.', 't.');
  // mapped properties missing from AppLocalizations: labels.summarySheetName and labels.balanceEventsSheetName
  serviceContent = serviceContent.replaceAll(
      't.summarySheetName', 't.export_summarySheetName');
  serviceContent = serviceContent.replaceAll(
      't.balanceEventsSheetName', 't.export_balanceEventsSheetName');
  serviceContent = serviceContent.replaceAll(
      't.openingBalanceRow', 't.exportSummary_carryOver');
  serviceContent = serviceContent.replaceAll(
      't.timeAdjustmentRow', 't.exportSummary_manualCorrections');
  serviceContent = serviceContent.replaceAll(
      't.timeAdjustmentsTotalRow', 't.exportSummary_manualAdjustments');
  serviceContent = serviceContent.replaceAll(
      't.periodStartBalanceRow', 't.exportSummary_balanceAtStart');
  serviceContent = serviceContent.replaceAll(
      't.periodEndBalanceRow', 't.exportSummary_balanceAfterThis');
  serviceContent =
      serviceContent.replaceAll('t.metricHeader', "t.exportHeader_type");
  serviceContent =
      serviceContent.replaceAll('t.minutesHeader', "t.exportHeader_minutes");
  serviceContent =
      serviceContent.replaceAll('t.hoursHeader', "t.exportHeader_workedHours");
  serviceContent = serviceContent.replaceAll('t.periodRow', "'Period'");
  serviceContent = serviceContent.replaceAll('t.quickReadRow', "'Quick Read'");
  serviceContent = serviceContent.replaceAll(
      't.totalLoggedTimeRow', "t.exportSummary_totalTrackedOnly");
  serviceContent = serviceContent.replaceAll(
      't.paidLeaveRow', "t.exportSummary_paidLeaveCredit");
  serviceContent =
      serviceContent.replaceAll('t.accountedTimeRow', "'Accounted'");
  serviceContent = serviceContent.replaceAll('t.plannedTimeRow', "'Planned'");
  serviceContent =
      serviceContent.replaceAll('t.differenceVsPlanRow', "'Difference'");
  serviceContent = serviceContent.replaceAll(
      't.balanceAfterPeriodRow', "t.exportSummary_balanceAfterThis");
  serviceContent =
      serviceContent.replaceAll('t.colType', "t.exportHeader_type");
  serviceContent =
      serviceContent.replaceAll('t.colDate', "t.exportHeader_date");
  serviceContent =
      serviceContent.replaceAll('t.colMinutes', "t.exportHeader_minutes");
  serviceContent =
      serviceContent.replaceAll('t.colHours', "t.exportHeader_workedHours");
  serviceContent =
      serviceContent.replaceAll('t.colNote', "t.exportHeader_notes");

  // _prepareBalanceEventsSheet
  serviceContent = serviceContent.replaceAll(
      'static ExportData _prepareBalanceEventsSheet({',
      'static ExportData _prepareBalanceEventsSheet({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "fillFriendlyNotes ? 'Carry-over from earlier' : ''",
      "fillFriendlyNotes ? t.exportSummary_carryOver : ''");
  serviceContent = serviceContent.replaceAll(
      "fillFriendlyNotes ? 'Manual corrections in this period' : ''",
      "fillFriendlyNotes ? t.exportSummary_manualCorrections : ''");
  serviceContent = serviceContent.replaceAll(
      "fillFriendlyNotes ? 'Balance at start of selected period' : ''",
      "fillFriendlyNotes ? t.exportSummary_balanceAtStart : ''");
  serviceContent = serviceContent.replaceAll(
      "fillFriendlyNotes ? 'Balance after this period' : ''",
      "fillFriendlyNotes ? t.exportSummary_balanceAfterThis : ''");

  // prepareReportExportData (the aggregator)
  serviceContent = serviceContent.replaceAll(
      'static List<ExportData> prepareReportExportData({',
      'static List<ExportData> prepareReportExportData({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "final entriesSheetName =\n        forXlsxPresentation ? 'Report' : labels.entriesSheetName;",
      "final entriesSheetName =\n        forXlsxPresentation ? 'Report' : 'Entries';");
  serviceContent = serviceContent.replaceAll(
      "final summarySheetName =\n        forXlsxPresentation ? 'Sammanfattning' : labels.summarySheetName;",
      "final summarySheetName =\n        forXlsxPresentation ? t.export_summarySheetName : 'Summary';");
  serviceContent = serviceContent.replaceAll(
      "final balanceEventsSheetName =\n        forXlsxPresentation ? 'Balance Events' : labels.balanceEventsSheetName;",
      "final balanceEventsSheetName =\n        forXlsxPresentation ? t.export_balanceEventsSheetName : 'Events';");

  serviceContent = serviceContent.replaceAll("sheetName: entriesSheetName,",
      "sheetName: entriesSheetName,\n      t: t,");
  serviceContent = serviceContent.replaceAll(
      "sheetNameOverride: summarySheetName,",
      "sheetNameOverride: summarySheetName,\n      t: t,");
  serviceContent = serviceContent.replaceAll(
      "sheetNameOverride: balanceEventsSheetName,",
      "sheetNameOverride: balanceEventsSheetName,\n      t: t,");

  // buildReportSummaryWorkbookBytes
  serviceContent = serviceContent.replaceAll(
      'static List<int>? buildReportSummaryWorkbookBytes({',
      'static List<int>? buildReportSummaryWorkbookBytes({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "forXlsxPresentation: true,", "forXlsxPresentation: true,\n      t: t,");
  serviceContent = serviceContent.replaceAll(
      "_buildStyledReportWorkbook(\n      sections: sections,\n      labels: labels,",
      "_buildStyledReportWorkbook(\n      t: t,\n      sections: sections,");

  // _buildStyledReportWorkbook
  serviceContent = serviceContent.replaceAll(
      'static List<int>? _buildStyledReportWorkbook({',
      'static List<int>? _buildStyledReportWorkbook({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "final normalizedSummaryName =\n          labels.summarySheetName.trim().toLowerCase();",
      "final normalizedSummaryName =\n          t.export_summarySheetName.trim().toLowerCase();");
  serviceContent = serviceContent.replaceAll(
      "final normalizedBalanceName =\n          labels.balanceEventsSheetName.trim().toLowerCase();",
      "final normalizedBalanceName =\n          t.export_balanceEventsSheetName.trim().toLowerCase();");

  serviceContent = serviceContent.replaceAll(
      "section: section,\n          labels: labels,",
      "section: section,\n          t: t,");

  // _writeStyledSummarySheet
  serviceContent = serviceContent.replaceAll(
      'static void _writeStyledSummarySheet({',
      'static void _writeStyledSummarySheet({\n    required AppLocalizations t,');

  // _writeStyledReportSheet payrollNote
  serviceContent = serviceContent.replaceAll(
      "final payrollNote =\n        'Work/Travel = logged time. Leave rows = credited leave (not worked). '\n        'TOTAL (tracked only) excludes Leave and Balance events. See Sammanfattning.';",
      "final payrollNote = t.exportSummary_totalTrackedExcludes(t.export_summarySheetName);");

  // EXPORT FUNCTIONS (the wrappers)
  // exportEntriesToCSV
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportEntriesToCSV({',
      'static Future<String> exportEntriesToCSV({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "prepareExportData(entries)", "prepareExportData(entries, t: t)");

  // exportTravelMinimalToCSV
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportTravelMinimalToCSV({',
      'static Future<String> exportTravelMinimalToCSV({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "prepareTravelMinimalExportData(entries)",
      "prepareTravelMinimalExportData(entries, t)");

  // exportLeaveMinimalToCSV
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportLeaveMinimalToCSV({',
      'static Future<String> exportLeaveMinimalToCSV({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "prepareLeaveMinimalExportData(absences)",
      "prepareLeaveMinimalExportData(absences, t)");

  // exportReportSummaryToCSV
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportReportSummaryToCSV({',
      'static Future<String> exportReportSummaryToCSV({\n    required AppLocalizations t,');
  serviceContent = serviceContent.replaceAll(
      "rangeEnd: rangeEnd,\n      labels: labels,",
      "rangeEnd: rangeEnd,\n      t: t,");

  // exportEntriesToExcel
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportEntriesToExcel({',
      'static Future<String> exportEntriesToExcel({\n    required AppLocalizations t,');

  // exportTravelMinimalToExcel
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportTravelMinimalToExcel({',
      'static Future<String> exportTravelMinimalToExcel({\n    required AppLocalizations t,');

  // exportLeaveMinimalToExcel
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportLeaveMinimalToExcel({',
      'static Future<String> exportLeaveMinimalToExcel({\n    required AppLocalizations t,');

  // exportReportSummaryToExcel
  serviceContent = serviceContent.replaceAll(
      'static Future<String> exportReportSummaryToExcel({',
      'static Future<String> exportReportSummaryToExcel({\n    required AppLocalizations t,');

  // Replace exceptions
  serviceContent = serviceContent.replaceAll(
      "Exception('Generated Excel data is empty')",
      "Exception(t.export_errorEmptyData)");
  serviceContent = serviceContent.replaceAll("Exception('Unsupported format')",
      "Exception(t.export_errorUnsupportedFormat)");
  serviceContent = serviceContent.replaceAll(
      "Exception('Generated CSV data is empty')",
      "Exception(t.export_errorEmptyData)");

  File(servicePath).writeAsStringSync(serviceContent);
  print('export_service refactored!');
}
