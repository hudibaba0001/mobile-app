import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/email_settings.dart';
import '../repositories/supabase_email_settings_repository.dart';
import '../services/supabase_auth_service.dart';
import '../utils/error_handler.dart';

class EmailSettingsProvider extends ChangeNotifier {
  EmailSettings _settings = EmailSettings();
  Box<EmailSettings>? _settingsBox;
  bool _isLoading = false;
  AppError? _lastError;
  SupabaseEmailSettingsRepository? _supabaseRepo;
  SupabaseAuthService? _authService;

  // Getters
  EmailSettings get settings => _settings;
  bool get isLoading => _isLoading;
  AppError? get lastError => _lastError;
  bool get isConfigured => _settings.isConfigured;

  /// Set Supabase dependencies for cloud sync
  void setSupabaseDeps(SupabaseEmailSettingsRepository repo, SupabaseAuthService auth) {
    _supabaseRepo = repo;
    _authService = auth;
    // Sync current settings to cloud
    _syncToCloud();
  }

  String? get _userId => _authService?.currentUser?.id;

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      _settingsBox = await Hive.openBox<EmailSettings>('email_settings');
      await _loadSettings();
    } catch (error) {
      _handleError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      if (_settingsBox != null && _settingsBox!.isNotEmpty) {
        _settings = _settingsBox!.getAt(0) ?? EmailSettings();
      } else {
        _settings = EmailSettings();
        await _saveSettings();
      }
      _clearError();
    } catch (error) {
      _handleError(error);
    }
  }

  /// Load settings from Supabase and merge with local
  Future<void> loadFromCloud() async {
    final userId = _userId;
    if (userId == null || _supabaseRepo == null) return;

    try {
      final cloudSettings = await _supabaseRepo!.getSettings(userId);
      if (cloudSettings != null && cloudSettings.isConfigured) {
        _settings = cloudSettings;
        await _saveSettings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('EmailSettingsProvider: Error loading from cloud: $e');
    }
  }

  /// Fire-and-forget sync to cloud
  void _syncToCloud() {
    final userId = _userId;
    if (userId == null || _supabaseRepo == null) return;
    _supabaseRepo!.saveSettings(userId, _settings);
  }

  /// Save settings to storage
  Future<bool> _saveSettings() async {
    try {
      if (_settingsBox != null) {
        if (_settingsBox!.isEmpty) {
          await _settingsBox!.add(_settings);
        } else {
          await _settingsBox!.putAt(0, _settings);
        }
        _clearError();
        return true;
      }
      return false;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  /// Update email settings
  Future<bool> updateSettings(EmailSettings newSettings) async {
    try {
      // Validate settings
      final validationErrors = newSettings.validate();
      if (validationErrors.isNotEmpty) {
        _handleError(
            ErrorHandler.handleValidationError(validationErrors.first));
        return false;
      }

      _settings = newSettings;
      final success = await _saveSettings();

      if (success) {
        _syncToCloud();
        notifyListeners();
      }

      return success;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  /// Update manager email
  Future<bool> updateManagerEmail(String email) async {
    final updatedSettings = _settings.copyWith(managerEmail: email);
    return await updateSettings(updatedSettings);
  }

  /// Update sender credentials
  Future<bool> updateSenderCredentials({
    required String email,
    required String password,
    String? name,
  }) async {
    final updatedSettings = _settings.copyWith(
      senderEmail: email,
      senderPassword: password,
      senderName: name ?? _settings.senderName,
    );
    return await updateSettings(updatedSettings);
  }

  /// Update SMTP settings
  Future<bool> updateSMTPSettings({
    required String server,
    required int port,
    required bool useSSL,
  }) async {
    final updatedSettings = _settings.copyWith(
      smtpServer: server,
      smtpPort: port,
      useSSL: useSSL,
    );
    return await updateSettings(updatedSettings);
  }

  /// Update auto-send settings
  Future<bool> updateAutoSendSettings({
    required bool enabled,
    required String frequency,
    required int day,
  }) async {
    final updatedSettings = _settings.copyWith(
      autoSendEnabled: enabled,
      autoSendFrequency: frequency,
      autoSendDay: day,
    );
    return await updateSettings(updatedSettings);
  }

  /// Update report preferences
  Future<bool> updateReportPreferences({
    required String format,
    required String period,
    required bool includeCharts,
    required bool includeSummary,
    required bool includeDetailedEntries,
  }) async {
    final updatedSettings = _settings.copyWith(
      defaultReportFormat: format,
      defaultReportPeriod: period,
      includeCharts: includeCharts,
      includeSummary: includeSummary,
      includeDetailedEntries: includeDetailedEntries,
    );
    return await updateSettings(updatedSettings);
  }

  /// Update custom templates
  Future<bool> updateCustomTemplates({
    required String subjectTemplate,
    required String messageTemplate,
  }) async {
    final updatedSettings = _settings.copyWith(
      customSubjectTemplate: subjectTemplate,
      customMessageTemplate: messageTemplate,
    );
    return await updateSettings(updatedSettings);
  }

  /// Test email configuration
  Future<bool> testEmailConfiguration() async {
    try {
      if (!_settings.isConfigured) {
        _handleError(ErrorHandler.handleValidationError(
            'Email settings are not configured'));
        return false;
      }

      // Validate the settings
      final validationErrors = _settings.validate();
      if (validationErrors.isNotEmpty) {
        _handleError(
            ErrorHandler.handleValidationError(validationErrors.first));
        return false;
      }

      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  /// Get available report formats
  List<String> getAvailableFormats() {
    return ['excel', 'pdf', 'csv'];
  }

  /// Get available report periods
  List<String> getAvailablePeriods() {
    return ['last5Days', 'lastWeek', 'last2Weeks', 'last3Weeks', 'lastMonth'];
  }

  /// Get available auto-send frequencies
  List<String> getAvailableFrequencies() {
    return ['weekly', 'biweekly', 'monthly'];
  }

  /// Get display name for format
  String getFormatDisplayName(String format) {
    switch (format) {
      case 'excel':
        return 'Excel (.xlsx)';
      case 'pdf':
        return 'PDF (.pdf)';
      case 'csv':
        return 'CSV (.csv)';
      default:
        return format;
    }
  }

  /// Get display name for period
  String getPeriodDisplayName(String period) {
    switch (period) {
      case 'last5Days':
        return 'Last 5 Days';
      case 'lastWeek':
        return 'Last Week';
      case 'last2Weeks':
        return 'Last 2 Weeks';
      case 'last3Weeks':
        return 'Last 3 Weeks';
      case 'lastMonth':
        return 'Last Month';
      default:
        return period;
    }
  }

  /// Get display name for frequency
  String getFrequencyDisplayName(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  /// Check if auto-send is due
  bool isAutoSendDue() {
    if (!_settings.autoSendEnabled || _settings.lastSentDate == null) {
      return _settings.autoSendEnabled; // Send immediately if never sent
    }

    final now = DateTime.now();
    final lastSent = _settings.lastSentDate!;

    switch (_settings.autoSendFrequency) {
      case 'weekly':
        return now.difference(lastSent).inDays >= 7;
      case 'biweekly':
        return now.difference(lastSent).inDays >= 14;
      case 'monthly':
        return now.difference(lastSent).inDays >= 30;
      default:
        return false;
    }
  }

  /// Mark auto-send as completed
  Future<void> markAutoSendCompleted() async {
    final updatedSettings = _settings.copyWith(lastSentDate: DateTime.now());
    await updateSettings(updatedSettings);
  }

  /// Reset settings to default
  Future<bool> resetToDefaults() async {
    _settings = EmailSettings();
    final success = await _saveSettings();

    if (success) {
      _syncToCloud();
      notifyListeners();
    }

    return success;
  }

  /// Clear all settings
  Future<bool> clearSettings() async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.clear();
        _settings = EmailSettings();
        _syncToCloud();
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      _handleError(error);
      return false;
    }
  }

  /// Handle errors
  void _handleError(dynamic error) {
    if (error is AppError) {
      _lastError = error;
    } else {
      _lastError = ErrorHandler.handleUnknownError(error);
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsBox?.close();
    super.dispose();
  }
}
