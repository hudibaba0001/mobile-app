import 'dart:io';

void main() {
  final testPath = 'test/services/export_service_test.dart';
  var testContent = File(testPath).readAsStringSync();

  // Test 1: replace the dictionary map keys
  testContent = testContent.replaceAll(
      "summaryByMetric['Total logged time']?[1]",
      "summaryByMetric[labels.exportSummary_totalTrackedOnly]?[1]");
  testContent = testContent.replaceAll("summaryByMetric['Paid leave']?[1]",
      "summaryByMetric[labels.exportSummary_paidLeaveCredit]?[1]");
  testContent = testContent.replaceAll("summaryByMetric['Accounted time']?[1]",
      "summaryByMetric['Accounted']?[1]" // In export_service, it's just 'Accounted'
      );
  testContent = testContent.replaceAll("summaryByMetric['Planned time']?[1]",
      "summaryByMetric['Planned']?[1]" // In export_service, it's just 'Planned'
      );
  testContent = testContent.replaceAll(
      "summaryByMetric['Difference vs plan']?[1]",
      "summaryByMetric['Difference']?[1]" // In export_service, it's 'Difference'
      );
  testContent = testContent.replaceAll(
      "summaryByMetric['Your balance after this period']?[1]",
      "summaryByMetric[labels.exportSummary_balanceAfterThis]?[1]");

  // Make sure labels is defined in Test 1
  testContent = testContent.replaceAll(
      "final sections = ExportService.prepareReportExportData(",
      "final labels = _testAppLocalizations();\n      final sections = ExportService.prepareReportExportData(");
  testContent =
      testContent.replaceAll("t: _testAppLocalizations(),", "t: labels,");

  // Test 2 & 3:
  testContent = testContent.replaceAll(
      "findRowByFirstColumn(summarySheet, 'Total logged time');",
      "findRowByFirstColumn(summarySheet, labels.exportSummary_totalTrackedOnly);");
  testContent = testContent.replaceAll(
      "findRowByFirstColumn(summarySheet, 'Difference vs plan');",
      "findRowByFirstColumn(summarySheet, 'Difference');");
  testContent = testContent.replaceAll(
      "findRowByFirstColumn(balanceSheet, 'Balance at period end');",
      "findRowByFirstColumn(balanceSheet, labels.exportSummary_balanceAfterThis);");

  File(testPath).writeAsStringSync(testContent);
  print('Fixed test assertions');
}
