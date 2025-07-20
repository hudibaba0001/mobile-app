import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';

class EmailExportService {
  /// Send travel report via email
  Future<bool> sendTravelReport({
    required List<TravelTimeEntry> entries,
    required TravelSummary summary,
    required String recipientEmail,
    required String senderEmail,
    required String senderPassword,
    required EmailReportFormat format,
    required EmailReportPeriod period,
    String? customSubject,
    String? customMessage,
  }) async {
    try {
      // Generate the report file
      String filePath;
      String fileName;
      
      switch (format) {
        case EmailReportFormat.excel:
          filePath = await _generateExcelReport(entries, summary, period);
          fileName = _getFileName(period, 'xlsx');
          break;
        case EmailReportFormat.pdf:
          filePath = await _generatePDFReport(entries, summary, period);
          fileName = _getFileName(period, 'pdf');
          break;
        case EmailReportFormat.csv:
          filePath = await _generateCSVReport(entries, summary, period);
          fileName = _getFileName(period, 'csv');
          break;
      }

      // Send email with attachment
      await _sendEmailWithAttachment(
        recipientEmail: recipientEmail,
        senderEmail: senderEmail,
        senderPassword: senderPassword,
        filePath: filePath,
        fileName: fileName,
        subject: customSubject ?? _getDefaultSubject(period),
        message: customMessage ?? _getDefaultMessage(summary, period),
      );

      // Clean up temporary file
      await File(filePath).delete();
      
      return true;
    } catch (error) {
      throw ErrorHandler.handleEmailError(error);
    }
  }

  /// Generate Excel report
  Future<String> _generateExcelReport(
    List<TravelTimeEntry> entries,
    TravelSummary summary,
    EmailReportPeriod period,
  ) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet and create custom sheets
    excel.delete('Sheet1');
    
    // Create Summary sheet
    final summarySheet = excel['Summary'];
    _addSummaryToExcel(summarySheet, summary, period);
    
    // Create Entries sheet
    final entriesSheet = excel['Travel Entries'];
    _addEntriesToExcel(entriesSheet, entries);
    
    // Create Charts sheet (basic data for charts)
    final chartsSheet = excel['Analytics'];
    _addAnalyticsToExcel(chartsSheet, entries, summary);
    
    // Save to file
    final directory = await getTemporaryDirectory();
    final fileName = _getFileName(period, 'xlsx');
    final file = File('${directory.path}/$fileName');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file.path;
  }

  void _addSummaryToExcel(Sheet sheet, TravelSummary summary, EmailReportPeriod period) {
    // Header
    sheet.cell(CellIndex.indexByString('A1')).value = 'Travel Time Report - ${_getPeriodDisplayName(period)}';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
    );
    
    // Report period
    sheet.cell(CellIndex.indexByString('A3')).value = 'Report Period:';
    sheet.cell(CellIndex.indexByString('B3')).value = 
        '${DateFormat('MMM dd, yyyy').format(summary.startDate)} - ${DateFormat('MMM dd, yyyy').format(summary.endDate)}';
    
    // Summary statistics
    int row = 5;
    final stats = [
      ['Total Trips', summary.totalEntries.toString()],
      ['Total Travel Time', summary.formattedDuration],
      ['Average Trip Duration', '${summary.averageMinutesPerTrip.toStringAsFixed(1)} minutes'],
      ['Most Frequent Route', summary.mostFrequentRoute],
      ['Total Hours', '${summary.totalHours} hours'],
    ];
    
    sheet.cell(CellIndex.indexByString('A$row')).value = 'Summary Statistics';
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true);
    row += 2;
    
    for (final stat in stats) {
      sheet.cell(CellIndex.indexByString('A$row')).value = stat[0];
      sheet.cell(CellIndex.indexByString('B$row')).value = stat[1];
      row++;
    }
    
    // Route frequency
    if (summary.locationFrequency.isNotEmpty) {
      row += 2;
      sheet.cell(CellIndex.indexByString('A$row')).value = 'Most Frequent Routes';
      sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true);
      row++;
      
      sheet.cell(CellIndex.indexByString('A$row')).value = 'Route';
      sheet.cell(CellIndex.indexByString('B$row')).value = 'Trip Count';
      sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByString('B$row')).cellStyle = CellStyle(bold: true);
      row++;
      
      final sortedRoutes = summary.locationFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final route in sortedRoutes.take(10)) {
        sheet.cell(CellIndex.indexByString('A$row')).value = route.key;
        sheet.cell(CellIndex.indexByString('B$row')).value = route.value;
        row++;
      }
    }
  }

  void _addEntriesToExcel(Sheet sheet, List<TravelTimeEntry> entries) {
    // Headers
    final headers = ['Date', 'Departure', 'Arrival', 'Duration (min)', 'Duration (formatted)', 'Additional Info', 'Day of Week'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(bold: true);
    }
    
    // Data rows
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          DateFormat('yyyy-MM-dd').format(entry.date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = entry.departure;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = entry.arrival;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = entry.minutes;
      
      final hours = entry.minutes ~/ 60;
      final minutes = entry.minutes % 60;
      final formattedDuration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = formattedDuration;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = entry.info ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = 
          DateFormat('EEEE').format(entry.date);
    }
  }

  void _addAnalyticsToExcel(Sheet sheet, List<TravelTimeEntry> entries, TravelSummary summary) {
    // Daily totals for chart data
    sheet.cell(CellIndex.indexByString('A1')).value = 'Daily Travel Time Analysis';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(bold: true);
    
    sheet.cell(CellIndex.indexByString('A3')).value = 'Date';
    sheet.cell(CellIndex.indexByString('B3')).value = 'Total Minutes';
    sheet.cell(CellIndex.indexByString('C3')).value = 'Trip Count';
    
    // Calculate daily totals
    final dailyData = <String, Map<String, int>>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
      dailyData[dateKey] ??= {'minutes': 0, 'count': 0};
      dailyData[dateKey]!['minutes'] = dailyData[dateKey]!['minutes']! + entry.minutes;
      dailyData[dateKey]!['count'] = dailyData[dateKey]!['count']! + 1;
    }
    
    int row = 4;
    final sortedDates = dailyData.keys.toList()..sort();
    for (final date in sortedDates) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1)).value = date;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1)).value = dailyData[date]!['minutes'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1)).value = dailyData[date]!['count'];
      row++;
    }
  }

  /// Generate PDF report
  Future<String> _generatePDFReport(
    List<TravelTimeEntry> entries,
    TravelSummary summary,
    EmailReportPeriod period,
  ) async {
    final pdf = pw.Document();
    
    // Add summary page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPDFHeader(summary, period),
            pw.SizedBox(height: 20),
            _buildPDFSummaryStats(summary),
            pw.SizedBox(height: 20),
            _buildPDFRouteFrequency(summary),
          ];
        },
      ),
    );
    
    // Add entries page
    if (entries.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Travel Entries', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              _buildPDFEntriesTable(entries),
            ];
          },
        ),
      );
    }
    
    // Save to file
    final directory = await getTemporaryDirectory();
    final fileName = _getFileName(period, 'pdf');
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildPDFHeader(TravelSummary summary, EmailReportPeriod period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Travel Time Report - ${_getPeriodDisplayName(period)}',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Report Period: ${DateFormat('MMM dd, yyyy').format(summary.startDate)} - ${DateFormat('MMM dd, yyyy').format(summary.endDate)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildPDFSummaryStats(TravelSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            _buildPDFTableRow('Total Trips', summary.totalEntries.toString(), isHeader: true),
            _buildPDFTableRow('Total Travel Time', summary.formattedDuration),
            _buildPDFTableRow('Average Trip Duration', '${summary.averageMinutesPerTrip.toStringAsFixed(1)} minutes'),
            _buildPDFTableRow('Most Frequent Route', summary.mostFrequentRoute),
            _buildPDFTableRow('Total Hours', '${summary.totalHours} hours'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFRouteFrequency(TravelSummary summary) {
    if (summary.locationFrequency.isEmpty) {
      return pw.SizedBox();
    }

    final sortedRoutes = summary.locationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Most Frequent Routes', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Route', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Trip Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...sortedRoutes.take(10).map((route) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(route.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(route.value.toString()),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.TableRow _buildPDFTableRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  pw.Widget _buildPDFEntriesTable(List<TravelTimeEntry> entries) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('From', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Duration', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          ],
        ),
        // Data rows
        ...entries.map((entry) {
          final hours = entry.minutes ~/ 60;
          final minutes = entry.minutes % 60;
          final formattedDuration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
          
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('MM/dd').format(entry.date), style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(entry.departure, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(entry.arrival, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(formattedDuration, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(entry.info ?? '', style: const pw.TextStyle(fontSize: 9))),
            ],
          );
        }),
      ],
    );
  }

  /// Generate CSV report
  Future<String> _generateCSVReport(
    List<TravelTimeEntry> entries,
    TravelSummary summary,
    EmailReportPeriod period,
  ) async {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('Travel Time Report - ${_getPeriodDisplayName(period)}');
    buffer.writeln('Generated on,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Period,${DateFormat('yyyy-MM-dd').format(summary.startDate)} to ${DateFormat('yyyy-MM-dd').format(summary.endDate)}');
    buffer.writeln('');
    
    // Add summary
    buffer.writeln('Summary Statistics');
    buffer.writeln('Total Trips,${summary.totalEntries}');
    buffer.writeln('Total Time,${summary.formattedDuration}');
    buffer.writeln('Average Trip,${summary.averageMinutesPerTrip.toStringAsFixed(1)} minutes');
    buffer.writeln('Most Frequent Route,${summary.mostFrequentRoute}');
    buffer.writeln('');
    
    // Add entries
    buffer.writeln('Travel Entries');
    buffer.writeln('Date,Departure,Arrival,Duration (min),Duration (formatted),Additional Info,Day of Week');
    
    for (final entry in entries) {
      final hours = entry.minutes ~/ 60;
      final minutes = entry.minutes % 60;
      final formattedDuration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      
      buffer.writeln([
        DateFormat('yyyy-MM-dd').format(entry.date),
        _escapeCsvField(entry.departure),
        _escapeCsvField(entry.arrival),
        entry.minutes.toString(),
        formattedDuration,
        _escapeCsvField(entry.info ?? ''),
        DateFormat('EEEE').format(entry.date),
      ].join(','));
    }
    
    // Save to file
    final directory = await getTemporaryDirectory();
    final fileName = _getFileName(period, 'csv');
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Send email with attachment
  Future<void> _sendEmailWithAttachment({
    required String recipientEmail,
    required String senderEmail,
    required String senderPassword,
    required String filePath,
    required String fileName,
    required String subject,
    required String message,
  }) async {
    // Configure SMTP server (Gmail example)
    final smtpServer = gmail(senderEmail, senderPassword);
    
    // Create message
    final emailMessage = Message()
      ..from = Address(senderEmail)
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..text = message
      ..attachments = [
        FileAttachment(File(filePath))
          ..location = Location.attachment
          ..cid = fileName
      ];

    try {
      final sendReport = await send(emailMessage, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } on MailerException catch (e) {
      throw ErrorHandler.handleEmailError('Failed to send email: ${e.message}');
    }
  }

  String _getFileName(EmailReportPeriod period, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final periodName = _getPeriodDisplayName(period).replaceAll(' ', '_').toLowerCase();
    return 'travel_report_${periodName}_$timestamp.$extension';
  }

  String _getPeriodDisplayName(EmailReportPeriod period) {
    switch (period) {
      case EmailReportPeriod.last5Days:
        return 'Last 5 Days';
      case EmailReportPeriod.lastWeek:
        return 'Last Week';
      case EmailReportPeriod.last2Weeks:
        return 'Last 2 Weeks';
      case EmailReportPeriod.last3Weeks:
        return 'Last 3 Weeks';
      case EmailReportPeriod.lastMonth:
        return 'Last Month';
      case EmailReportPeriod.custom:
        return 'Custom Period';
    }
  }

  String _getDefaultSubject(EmailReportPeriod period) {
    return 'Travel Time Report - ${_getPeriodDisplayName(period)} (${DateFormat('MMM dd, yyyy').format(DateTime.now())})';
  }

  String _getDefaultMessage(TravelSummary summary, EmailReportPeriod period) {
    return '''
Dear Manager,

Please find attached my travel time report for ${_getPeriodDisplayName(period).toLowerCase()}.

Summary:
• Total Trips: ${summary.totalEntries}
• Total Travel Time: ${summary.formattedDuration}
• Average Trip Duration: ${summary.averageMinutesPerTrip.toStringAsFixed(1)} minutes
• Most Frequent Route: ${summary.mostFrequentRoute}

The detailed report is attached in the requested format.

Best regards,
Travel Time Tracker App
''';
  }

  /// Get date range for period
  static DateTimeRange getDateRangeForPeriod(EmailReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case EmailReportPeriod.last5Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 5)),
          end: today,
        );
      case EmailReportPeriod.lastWeek:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today,
        );
      case EmailReportPeriod.last2Weeks:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 14)),
          end: today,
        );
      case EmailReportPeriod.last3Weeks:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 21)),
          end: today,
        );
      case EmailReportPeriod.lastMonth:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
      case EmailReportPeriod.custom:
        return DateTimeRange(start: today, end: today);
    }
  }
}

enum EmailReportFormat {
  excel,
  pdf,
  csv,
}

enum EmailReportPeriod {
  last5Days,
  lastWeek,
  last2Weeks,
  last3Weeks,
  lastMonth,
  custom,
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  
  DateTimeRange({required this.start, required this.end});
}