// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/email_settings.dart';

/// Repository for syncing email settings to Supabase
class SupabaseEmailSettingsRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'email_settings';

  SupabaseEmailSettingsRepository(this._supabase);

  /// Get email settings for a user
  Future<EmailSettings?> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return EmailSettings(
        managerEmail: (response['manager_email'] as String?) ?? '',
        senderEmail: (response['sender_email'] as String?) ?? '',
        senderPassword: (response['sender_password'] as String?) ?? '',
        senderName: (response['sender_name'] as String?) ?? '',
        autoSendEnabled: (response['auto_send_enabled'] as bool?) ?? false,
        autoSendFrequency: (response['auto_send_frequency'] as String?) ?? 'weekly',
        autoSendDay: (response['auto_send_day'] as int?) ?? 1,
        defaultReportFormat: (response['default_report_format'] as String?) ?? 'excel',
        defaultReportPeriod: (response['default_report_period'] as String?) ?? 'lastWeek',
        customSubjectTemplate: (response['custom_subject_template'] as String?) ?? '',
        customMessageTemplate: (response['custom_message_template'] as String?) ?? '',
        includeCharts: (response['include_charts'] as bool?) ?? true,
        includeSummary: (response['include_summary'] as bool?) ?? true,
        includeDetailedEntries: (response['include_detailed_entries'] as bool?) ?? true,
        lastSentDate: response['last_sent_date'] != null
            ? DateTime.parse(response['last_sent_date'] as String)
            : null,
        smtpServer: (response['smtp_server'] as String?) ?? 'smtp.gmail.com',
        smtpPort: (response['smtp_port'] as int?) ?? 587,
        useSSL: (response['use_ssl'] as bool?) ?? true,
      );
    } catch (e) {
      debugPrint('SupabaseEmailSettingsRepository: Error fetching settings: $e');
      rethrow;
    }
  }

  /// Save (upsert) email settings for a user
  Future<void> saveSettings(String userId, EmailSettings settings) async {
    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'manager_email': settings.managerEmail,
        'sender_email': settings.senderEmail,
        'sender_password': settings.senderPassword,
        'sender_name': settings.senderName,
        'auto_send_enabled': settings.autoSendEnabled,
        'auto_send_frequency': settings.autoSendFrequency,
        'auto_send_day': settings.autoSendDay,
        'default_report_format': settings.defaultReportFormat,
        'default_report_period': settings.defaultReportPeriod,
        'custom_subject_template': settings.customSubjectTemplate,
        'custom_message_template': settings.customMessageTemplate,
        'include_charts': settings.includeCharts,
        'include_summary': settings.includeSummary,
        'include_detailed_entries': settings.includeDetailedEntries,
        'last_sent_date': settings.lastSentDate?.toIso8601String(),
        'smtp_server': settings.smtpServer,
        'smtp_port': settings.smtpPort,
        'use_ssl': settings.useSSL,
      }, onConflict: 'user_id');

      debugPrint('SupabaseEmailSettingsRepository: Saved settings for $userId');
    } catch (e) {
      debugPrint('SupabaseEmailSettingsRepository: Error saving settings: $e');
    }
  }
}
