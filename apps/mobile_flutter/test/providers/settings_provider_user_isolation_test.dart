import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/providers/settings_provider.dart';
import 'package:myapp/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_provider_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(AppConstants.appSettingsBox)) {
      await Hive.box(AppConstants.appSettingsBox).close();
    }
    await Hive.deleteBoxFromDisk(AppConstants.appSettingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SettingsProvider user isolation', () {
    late SettingsProvider provider;

    setUp(() async {
      provider = SettingsProvider();
      await provider.init();
    });

    test('keeps settings scoped per user across account switches', () async {
      await provider.handleAuthUserChanged('user_a');
      await provider.setDarkMode(true);
      await provider.setTravelLoggingEnabled(false);
      await provider.setTimeBalanceEnabled(false);

      await provider.handleAuthUserChanged('user_b');
      expect(provider.isDarkMode, isFalse);
      expect(provider.isTravelLoggingEnabled, isTrue);
      expect(provider.isTimeBalanceEnabled, isTrue);

      await provider.handleAuthUserChanged('user_a');
      expect(provider.isDarkMode, isTrue);
      expect(provider.isTravelLoggingEnabled, isFalse);
      expect(provider.isTimeBalanceEnabled, isFalse);
    });

    test('resets to defaults on logout', () async {
      await provider.handleAuthUserChanged('user_a');
      await provider.setDarkMode(true);
      await provider.setTravelLoggingEnabled(false);
      await provider.setTimeBalanceEnabled(false);

      await provider.handleAuthUserChanged(null);

      expect(provider.isDarkMode, isFalse);
      expect(provider.isTravelLoggingEnabled, isTrue);
      expect(provider.isTimeBalanceEnabled, isTrue);
    });
  });
}
