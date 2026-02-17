import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class CrashReportingService {
  static bool _initialized = false;
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static Future<void> initialize({required String entrypoint}) async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const collectInDebug =
        bool.fromEnvironment('CRASHLYTICS_IN_DEBUG', defaultValue: false);
    _enabled = kReleaseMode || collectInDebug;

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(_enabled);
    await FirebaseCrashlytics.instance
        .setCustomKey('flutter_entrypoint', entrypoint);
    await FirebaseCrashlytics.instance.log('startup:entrypoint=$entrypoint');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (_enabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      if (_enabled) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'platform_dispatcher_uncaught',
        );
      }
      return true;
    };

    _initialized = true;
  }

  static Future<void> log(String message) async {
    if (!_enabled || kIsWeb) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_enabled || kIsWeb) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: false,
      reason: reason,
    );
  }

  static Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_enabled || kIsWeb) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: true,
      reason: reason,
    );
  }

  static Future<void> sendTestNonFatal() async {
    await recordNonFatal(
      StateError('Crashlytics test non-fatal'),
      StackTrace.current,
      reason: 'manual_non_fatal_test',
    );
  }

  static void crashForTest() {
    if (!_enabled || kIsWeb) return;
    FirebaseCrashlytics.instance.crash();
  }
}
