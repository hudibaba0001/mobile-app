import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/entry_service.dart';
import '../models/entry.dart';
import '../repositories/hive_location_repository.dart';

/// Provider for managing app settings and preferences
///
/// Handles user preferences like theme colors, language, notifications,
/// and provides functionality for data export. All settings are persisted
/// to SharedPreferences for consistency across app sessions.
class SettingsProvider extends ChangeNotifier {
  // Private fields
  Color _accentColor = const Color(0xFF6750A4); // Default purple
  String _language = 'en'; // Default English
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  ); // 6 PM default
  bool _weeklySummaryEnabled = false;

  // SharedPreferences keys
  static const String _accentColorKey = 'accent_color';
  static const String _languageKey = 'language';
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const String _dailyReminderHourKey = 'daily_reminder_hour';
  static const String _dailyReminderMinuteKey = 'daily_reminder_minute';
  static const String _weeklySummaryEnabledKey = 'weekly_summary_enabled';

  // Getters

  /// Current accent color for the app theme
  Color get accentColor => _accentColor;

  /// Current language setting ('en' for English, 'sv' for Swedish)
  String get language => _language;

  /// Whether daily reminders are enabled
  bool get dailyReminderEnabled => _dailyReminderEnabled;

  /// Time of day for daily reminders
  TimeOfDay get dailyReminderTime => _dailyReminderTime;

  /// Whether weekly summary notifications are enabled
  bool get weeklySummaryEnabled => _weeklySummaryEnabled;

  // Setters with persistence

  /// Set the accent color and persist to SharedPreferences
  ///
  /// [color] The new accent color to apply
  Future<void> setAccentColor(Color color) async {
    if (_accentColor != color) {
      _accentColor = color;
      await _saveAccentColor();
      notifyListeners();
    }
  }

  /// Set the language and persist to SharedPreferences
  ///
  /// [lang] Language code ('en' or 'sv')
  Future<void> setLanguage(String lang) async {
    if (_language != lang && (lang == 'en' || lang == 'sv')) {
      _language = lang;
      await _saveLanguage();
      notifyListeners();
    }
  }

  /// Enable or disable daily reminders and persist to SharedPreferences
  ///
  /// [enabled] Whether daily reminders should be enabled
  Future<void> setDailyReminderEnabled(bool enabled) async {
    if (_dailyReminderEnabled != enabled) {
      _dailyReminderEnabled = enabled;
      await _saveDailyReminderEnabled();
      notifyListeners();
    }
  }

  /// Set the time for daily reminders and persist to SharedPreferences
  ///
  /// [time] The time of day for daily reminders
  Future<void> setDailyReminderTime(TimeOfDay time) async {
    if (_dailyReminderTime != time) {
      _dailyReminderTime = time;
      await _saveDailyReminderTime();
      notifyListeners();
    }
  }

  /// Enable or disable weekly summary notifications and persist to SharedPreferences
  ///
  /// [enabled] Whether weekly summaries should be enabled
  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    if (_weeklySummaryEnabled != enabled) {
      _weeklySummaryEnabled = enabled;
      await _saveWeeklySummaryEnabled();
      notifyListeners();
    }
  }

  // Initialization and persistence methods

  /// Initialize the provider by loading all settings from SharedPreferences
  ///
  /// Should be called once when the provider is created
  Future<void> init() async {
    await _loadAllSettings();
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load accent color
    final colorValue = prefs.getInt(_accentColorKey);
    if (colorValue != null) {
      _accentColor = Color(colorValue);
    }

    // Load language
    _language = prefs.getString(_languageKey) ?? 'en';

    // Load daily reminder settings
    _dailyReminderEnabled = prefs.getBool(_dailyReminderEnabledKey) ?? false;
    final hour = prefs.getInt(_dailyReminderHourKey) ?? 18;
    final minute = prefs.getInt(_dailyReminderMinuteKey) ?? 0;
    _dailyReminderTime = TimeOfDay(hour: hour, minute: minute);

    // Load weekly summary setting
    _weeklySummaryEnabled = prefs.getBool(_weeklySummaryEnabledKey) ?? false;

    notifyListeners();
  }

  /// Save accent color to SharedPreferences
  Future<void> _saveAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, _accentColor.value);
  }

  /// Save language to SharedPreferences
  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
  }

  /// Save daily reminder enabled state to SharedPreferences
  Future<void> _saveDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, _dailyReminderEnabled);
  }

  /// Save daily reminder time to SharedPreferences
  Future<void> _saveDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyReminderHourKey, _dailyReminderTime.hour);
    await prefs.setInt(_dailyReminderMinuteKey, _dailyReminderTime.minute);
  }

  /// Save weekly summary enabled state to SharedPreferences
  Future<void> _saveWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklySummaryEnabledKey, _weeklySummaryEnabled);
  }

  // Export functionality

  /// Export all entries to CSV format and save to device storage
  ///
  /// Uses EntryService to get all entries, converts them to CSV format,
  /// and saves the file to the device's documents directory.
  ///
  /// Returns the file path where the CSV was saved, or null if export failed.
  Future<String?> exportCsv() async {
    try {
      // Get EntryService instance with location repository
      final locationRepository = HiveLocationRepository();
      final entryService = EntryService(locationRepository: locationRepository);

      // Get all entries from the service
      final entries = await entryService.getAllTravelEntries();

      if (entries.isEmpty) {
        return null; // No data to export
      }

      // Convert entries to CSV format
      final csvContent = _convertEntriesToCsv(entries);

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'travel_entries_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      // Write CSV content to file
      final file = File(filePath);
      await file.writeAsString(csvContent);

      return filePath;
    } catch (e) {
      // Log error and return null to indicate failure
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }

  /// Convert a list of entries to CSV format string
  ///
  /// [entries] List of Entry objects to convert
  /// Returns a CSV formatted string with headers and data rows
  String _convertEntriesToCsv(List<Entry> entries) {
    final buffer = StringBuffer();

    // Add CSV headers
    buffer.writeln(
      'Date,Type,From,To,Travel Minutes,Work Hours,Notes,Journey ID,Segment Order,Created At,Updated At',
    );

    // Add data rows
    for (final entry in entries) {
      final row = [
        _formatDateForCsv(entry.date),
        entry.type.name,
        _escapeCsvField(entry.from ?? ''),
        _escapeCsvField(entry.to ?? ''),
        entry.travelMinutes?.toString() ?? '',
        entry.workHours.toString() ?? '',
        _escapeCsvField(entry.notes ?? ''),
        _escapeCsvField(entry.journeyId ?? ''),
        entry.segmentOrder?.toString() ?? '',
        _formatDateTimeForCsv(entry.createdAt),
        entry.updatedAt != null ? _formatDateTimeForCsv(entry.updatedAt!) : '',
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Format a DateTime for CSV export
  ///
  /// [date] DateTime to format
  /// Returns formatted date string (YYYY-MM-DD)
  String _formatDateForCsv(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format a DateTime with time for CSV export
  ///
  /// [dateTime] DateTime to format
  /// Returns formatted datetime string (YYYY-MM-DD HH:MM:SS)
  String _formatDateTimeForCsv(DateTime dateTime) {
    return '${_formatDateForCsv(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Escape a field for CSV format by wrapping in quotes if it contains special characters
  ///
  /// [field] String field to escape
  /// Returns escaped field safe for CSV format
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Escape quotes by doubling them and wrap the whole field in quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Utility methods

  /// Get display name for current language
  String get languageDisplayName {
    switch (_language) {
      case 'sv':
        return 'Svenska';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Get formatted time string for daily reminder
  String getDailyReminderTimeString(BuildContext context) {
    return _dailyReminderTime.format(context);
  }

  /// Reset all settings to default values
  Future<void> resetToDefaults() async {
    _accentColor = const Color(0xFF6750A4);
    _language = 'en';
    _dailyReminderEnabled = false;
    _dailyReminderTime = const TimeOfDay(hour: 18, minute: 0);
    _weeklySummaryEnabled = false;

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accentColorKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_dailyReminderEnabledKey);
    await prefs.remove(_dailyReminderHourKey);
    await prefs.remove(_dailyReminderMinuteKey);
    await prefs.remove(_weeklySummaryEnabledKey);

    notifyListeners();
  }
}
