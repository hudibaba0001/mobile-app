import 'package:hive/hive.dart';

part 'email_settings.g.dart';

@HiveType(typeId: 3)
class EmailSettings extends HiveObject {
  @HiveField(0)
  String managerEmail;

  @HiveField(1)
  String senderEmail;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  bool autoSendEnabled;

  @HiveField(5)
  String autoSendFrequency; // 'weekly', 'biweekly', 'monthly'

  @HiveField(6)
  int autoSendDay; // Day of week (1-7) or day of month (1-31)

  @HiveField(7)
  String defaultReportFormat; // 'excel', 'pdf', 'csv'

  @HiveField(8)
  String defaultReportPeriod; // 'last5Days', 'lastWeek', etc.

  @HiveField(9)
  String customSubjectTemplate;

  @HiveField(10)
  String customMessageTemplate;

  @HiveField(11)
  bool includeCharts;

  @HiveField(12)
  bool includeSummary;

  @HiveField(13)
  bool includeDetailedEntries;

  @HiveField(14)
  DateTime? lastSentDate;

  @HiveField(15)
  String smtpServer;

  @HiveField(16)
  int smtpPort;

  @HiveField(17)
  bool useSSL;

  EmailSettings({
    this.managerEmail = '',
    this.senderEmail = '',
    this.senderName = '',
    this.autoSendEnabled = false,
    this.autoSendFrequency = 'weekly',
    this.autoSendDay = 1, // Monday
    this.defaultReportFormat = 'excel',
    this.defaultReportPeriod = 'lastWeek',
    this.customSubjectTemplate = '',
    this.customMessageTemplate = '',
    this.includeCharts = true,
    this.includeSummary = true,
    this.includeDetailedEntries = true,
    this.lastSentDate,
    this.smtpServer = 'smtp.gmail.com',
    this.smtpPort = 587,
    this.useSSL = true,
  });

  // Convenience getters
  bool get isConfigured =>
      managerEmail.isNotEmpty && senderEmail.isNotEmpty;

  String get displayName => senderName.isNotEmpty ? senderName : senderEmail;

  // Copy with method for updates
  EmailSettings copyWith({
    String? managerEmail,
    String? senderEmail,
    String? senderName,
    bool? autoSendEnabled,
    String? autoSendFrequency,
    int? autoSendDay,
    String? defaultReportFormat,
    String? defaultReportPeriod,
    String? customSubjectTemplate,
    String? customMessageTemplate,
    bool? includeCharts,
    bool? includeSummary,
    bool? includeDetailedEntries,
    DateTime? lastSentDate,
    String? smtpServer,
    int? smtpPort,
    bool? useSSL,
  }) {
    return EmailSettings(
      managerEmail: managerEmail ?? this.managerEmail,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      autoSendEnabled: autoSendEnabled ?? this.autoSendEnabled,
      autoSendFrequency: autoSendFrequency ?? this.autoSendFrequency,
      autoSendDay: autoSendDay ?? this.autoSendDay,
      defaultReportFormat: defaultReportFormat ?? this.defaultReportFormat,
      defaultReportPeriod: defaultReportPeriod ?? this.defaultReportPeriod,
      customSubjectTemplate:
          customSubjectTemplate ?? this.customSubjectTemplate,
      customMessageTemplate:
          customMessageTemplate ?? this.customMessageTemplate,
      includeCharts: includeCharts ?? this.includeCharts,
      includeSummary: includeSummary ?? this.includeSummary,
      includeDetailedEntries:
          includeDetailedEntries ?? this.includeDetailedEntries,
      lastSentDate: lastSentDate ?? this.lastSentDate,
      smtpServer: smtpServer ?? this.smtpServer,
      smtpPort: smtpPort ?? this.smtpPort,
      useSSL: useSSL ?? this.useSSL,
    );
  }

  // Validation methods
  List<String> validate() {
    final errors = <String>[];

    if (managerEmail.isEmpty) {
      errors.add('Manager email is required');
    } else if (!_isValidEmail(managerEmail)) {
      errors.add('Manager email is not valid');
    }

    if (senderEmail.isEmpty) {
      errors.add('Sender email is required');
    } else if (!_isValidEmail(senderEmail)) {
      errors.add('Sender email is not valid');
    }

    if (smtpServer.isEmpty) {
      errors.add('SMTP server is required');
    }

    if (smtpPort <= 0 || smtpPort > 65535) {
      errors.add('SMTP port must be between 1 and 65535');
    }

    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get default subject template
  String getSubjectTemplate() {
    if (customSubjectTemplate.isNotEmpty) {
      return customSubjectTemplate;
    }
    return 'Travel Time Report - {period} ({date})';
  }

  // Get default message template
  String getMessageTemplate() {
    if (customMessageTemplate.isNotEmpty) {
      return customMessageTemplate;
    }
    return '''Dear Manager,

Please find attached my travel time report for {period}.

Summary:
• Total Trips: {totalTrips}
• Total Travel Time: {totalTime}
• Average Trip Duration: {averageTime}
• Most Frequent Route: {frequentRoute}

The detailed report is attached in {format} format.

Best regards,
{senderName}''';
  }

  @override
  String toString() {
    return 'EmailSettings(managerEmail: $managerEmail, senderEmail: $senderEmail, autoSendEnabled: $autoSendEnabled)';
  }
}
