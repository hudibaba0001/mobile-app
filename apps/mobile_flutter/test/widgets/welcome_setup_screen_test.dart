import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/providers/settings_provider.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/screens/welcome_setup_screen.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/services/profile_service.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestSettingsProvider extends SettingsProvider {
  bool _timeBalanceEnabled = true;
  bool _travelLoggingEnabled = true;
  bool _paidLeaveTrackingEnabled = true;
  bool _setupCompleted = false;
  DateTime? _baselineDate;

  @override
  bool get isTimeBalanceEnabled => _timeBalanceEnabled;

  @override
  bool get isTravelLoggingEnabled => _travelLoggingEnabled;

  @override
  bool get isPaidLeaveTrackingEnabled => _paidLeaveTrackingEnabled;

  @override
  bool get isSetupCompleted => _setupCompleted;

  @override
  DateTime? get baselineDate => _baselineDate;

  @override
  Future<void> setTimeBalanceEnabled(bool value) async {
    _timeBalanceEnabled = value;
    notifyListeners();
  }

  @override
  Future<void> setTravelLoggingEnabled(bool value) async {
    _travelLoggingEnabled = value;
    notifyListeners();
  }

  @override
  Future<void> setPaidLeaveTrackingEnabled(bool value) async {
    _paidLeaveTrackingEnabled = value;
    notifyListeners();
  }

  @override
  Future<void> setSetupCompleted(bool value) async {
    _setupCompleted = value;
    notifyListeners();
  }

  @override
  Future<void> setBaselineDate(DateTime? date) async {
    _baselineDate = date;
    notifyListeners();
  }
}

class _TestContractProvider extends ContractProvider {
  int _contractPercent;
  int _fullTimeHours;
  DateTime _trackingStartDate;
  int _openingFlexMinutes;

  _TestContractProvider({
    required int contractPercent,
    required int fullTimeHours,
    required DateTime trackingStartDate,
    required int openingMinutes,
  })  : _contractPercent = contractPercent,
        _fullTimeHours = fullTimeHours,
        _trackingStartDate = trackingStartDate,
        _openingFlexMinutes = openingMinutes;

  @override
  int get contractPercent => _contractPercent;

  @override
  int get fullTimeHours => _fullTimeHours;

  @override
  DateTime get trackingStartDate => _trackingStartDate;

  @override
  int get openingFlexMinutes => _openingFlexMinutes;

  @override
  Future<void> updateContractSettings(int percent, int hours) async {
    _contractPercent = percent;
    _fullTimeHours = hours;
    notifyListeners();
  }

  @override
  Future<void> setTrackingStartDate(DateTime date) async {
    _trackingStartDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  @override
  Future<void> setOpeningFlexMinutes(int minutes) async {
    _openingFlexMinutes = minutes;
    notifyListeners();
  }
}

class _TestAuthService extends SupabaseAuthService {
  _TestAuthService(this._userId);
  final String _userId;

  @override
  String? get currentUserId => _userId;
}

class _TestProfileService extends ProfileService {
  Map<String, dynamic>? lastUpdatePayload;
  String? localCompletedUserId;
  bool localCompletedValue = false;

  @override
  Future<UserProfile?> updateProfileFields(Map<String, dynamic> updates) async {
    lastUpdatePayload = Map<String, dynamic>.from(updates);
    return null;
  }

  @override
  Future<void> setLocalSetupCompleted({
    required String userId,
    required bool completed,
  }) async {
    localCompletedUserId = userId;
    localCompletedValue = completed;
  }
}

Widget _wrap({
  required SettingsProvider settingsProvider,
  required ContractProvider contractProvider,
  required SupabaseAuthService authService,
  required ProfileService profileService,
  required VoidCallback onCompleted,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
      ChangeNotifierProvider<SupabaseAuthService>.value(value: authService),
    ],
    child: MaterialApp(
      locale: const Locale('sv'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WelcomeSetupScreen(
        onCompleted: onCompleted,
        profileService: profileService,
      ),
    ),
  );
}

Widget _wrapWithLocale({
  required SettingsProvider settingsProvider,
  required ContractProvider contractProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
    ],
    child: Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const WelcomeSetupScreen(),
        );
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = null;
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  });

  testWidgets(
      '"Bara logga tid" persists today baseline, opening=0 and setup completion',
      (tester) async {
    final settings = _TestSettingsProvider();
    final contract = _TestContractProvider(
      contractPercent: 80,
      fullTimeHours: 35,
      trackingStartDate: DateTime(2020, 1, 1),
      openingMinutes: 300,
    );
    final profileService = _TestProfileService();
    final authService = _TestAuthService('user-123');
    var completed = false;

    await tester.pumpWidget(
      _wrap(
        settingsProvider: settings,
        contractProvider: contract,
        authService: authService,
        profileService: profileService,
        onCompleted: () {
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('Bara logga tid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fortsätt'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    expect(completed, isTrue);
    expect(settings.isSetupCompleted, isTrue);
    expect(settings.isTimeBalanceEnabled, isFalse);
    expect(contract.trackingStartDate, todayDateOnly);
    expect(contract.openingFlexMinutes, 0);

    expect(profileService.lastUpdatePayload, isNotNull);
    expect(profileService.lastUpdatePayload!['tracking_start_date'],
        todayDateOnly);
    expect(profileService.lastUpdatePayload!['opening_flex_minutes'], 0);
    expect(profileService.lastUpdatePayload!['setup_completed_at'], isNotNull);
    expect(profileService.localCompletedUserId, 'user-123');
    expect(profileService.localCompletedValue, isTrue);
  });

  testWidgets('Welcome setup reacts to locale changes', (tester) async {
    final settings = _TestSettingsProvider();
    final contract = _TestContractProvider(
      contractPercent: 100,
      fullTimeHours: 40,
      trackingStartDate: DateTime(2020, 1, 1),
      openingMinutes: 0,
    );

    await settings.setLocale(const Locale('sv'));
    await tester.pumpWidget(
      _wrapWithLocale(
        settingsProvider: settings,
        contractProvider: contract,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Välkommen'), findsOneWidget);

    await settings.setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });
}
