import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../providers/settings_provider.dart';

/// Local daily reminder scheduling service.
///
/// Schedules one recurring daily notification at the user-selected time.
class ReminderService {
  static const int _dailyReminderNotificationId = 1001;
  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily reminders';
  static const String _channelDescription =
      'User-configured daily reminders to log time';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supportsNotifications => !kIsWeb;

  Future<void> initialize() async {
    if (_initialized || !_supportsNotifications) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('ReminderService: Failed to set local timezone: $e');
      // Keep default timezone if lookup fails.
    }
  }

  Future<bool> requestPermissions() async {
    if (!_supportsNotifications) return true;
    await initialize();

    bool granted = true;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted == false) {
      granted = false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    if (iosGranted == false) {
      granted = false;
    }

    final macos = _notifications.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final macGranted =
        await macos?.requestPermissions(alert: true, badge: true, sound: true);
    if (macGranted == false) {
      granted = false;
    }

    return granted;
  }

  Future<void> applySettings(SettingsProvider settings) async {
    if (!_supportsNotifications) return;
    await initialize();

    if (!settings.isDailyReminderEnabled) {
      await cancelDailyReminder();
      return;
    }

    final text = settings.dailyReminderText.trim().isEmpty
        ? 'Time to log your hours'
        : settings.dailyReminderText.trim();

    await scheduleDailyReminder(
      hour: settings.dailyReminderHour,
      minute: settings.dailyReminderMinute,
      message: text,
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    if (!_supportsNotifications) return;
    await initialize();
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.zonedSchedule(
      _dailyReminderNotificationId,
      'KvikTime',
      message,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancelDailyReminder() async {
    if (!_supportsNotifications) return;
    await initialize();
    await _notifications.cancel(_dailyReminderNotificationId);
  }
}
