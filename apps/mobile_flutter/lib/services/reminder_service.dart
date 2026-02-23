import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const int _testNotificationId = 1002;

  // v2 channel with high importance (old 'daily_reminders' channel was default importance)
  static const String _channelId = 'daily_reminders_v2';
  static const String _channelName = 'Daily reminders';
  static const String _channelDescription =
      'User-configured daily reminders to log time';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supportsNotifications => !kIsWeb;
  static const String _typeTokenCrashHint =
      'TypeToken must be created with a type argument';

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

    // Explicitly create the notification channel with high importance
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('ReminderService: Failed to set local timezone: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_supportsNotifications) return true;
    await initialize();

    bool granted = true;

    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final androidGranted = await android.requestNotificationsPermission();
        if (androidGranted == false) {
          granted = false;
        }
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
      final macGranted = await macos?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (macGranted == false) {
        granted = false;
      }
    } catch (e) {
      debugPrint('ReminderService: Failed requesting permissions: $e');
      return false;
    }

    return granted;
  }

  /// Send an immediate test notification to verify the notification system works.
  Future<void> showTestNotification() async {
    if (!_supportsNotifications) return;
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notifications.show(
        _testNotificationId,
        'KvikTime',
        'Reminders are working! You will be notified daily.',
        details,
        payload: 'test_reminder',
      );
      debugPrint('ReminderService: Test notification sent');
    } catch (e) {
      debugPrint('ReminderService: Failed to show test notification: $e');
      rethrow;
    }
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
    await _cancelDailyReminderInternal();

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
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
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
      debugPrint(
        'ReminderService: Scheduled daily reminder at $hour:${minute.toString().padLeft(2, '0')} '
        '(next fire: $scheduled)',
      );
    } on PlatformException catch (e) {
      if (e.message?.contains(_typeTokenCrashHint) == true) {
        debugPrint(
          'ReminderService: TypeToken crash during schedule – skipping.',
        );
        return;
      }
      debugPrint('ReminderService: Failed to schedule reminder: $e');
      rethrow;
    } catch (e) {
      debugPrint('ReminderService: Failed to schedule reminder: $e');
      rethrow;
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_supportsNotifications) return;
    await initialize();
    await _cancelDailyReminderInternal();
  }

  Future<void> _cancelDailyReminderInternal() async {
    try {
      await _notifications.cancel(_dailyReminderNotificationId);
    } on PlatformException catch (e) {
      if (e.message?.contains(_typeTokenCrashHint) == true) {
        debugPrint(
          'ReminderService: Ignoring known TypeToken cancel crash. '
          'Ensure R8 keeps generic signatures for flutter_local_notifications.',
        );
        return;
      }
      debugPrint('ReminderService: Failed to cancel reminder: $e');
    } catch (e) {
      debugPrint('ReminderService: Failed to cancel reminder: $e');
    }
  }
}
