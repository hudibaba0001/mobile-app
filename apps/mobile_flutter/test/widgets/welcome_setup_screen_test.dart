import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/providers/settings_provider.dart';
import 'package:myapp/screens/welcome_setup_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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
  _TestContractProvider({
    required int contractPercent,
    required int fullTimeHours,
    required this.initialTrackingStartDate,
    required this.initialOpeningMinutes,
  })  : _contractPercent = contractPercent,
        _fullTimeHours = fullTimeHours;

  final int _contractPercent;
  final int _fullTimeHours;
  final DateTime initialTrackingStartDate;
  final int initialOpeningMinutes;

  DateTime? savedTrackingStartDate;
  int? savedOpeningMinutes;

  @override
  int get contractPercent => _contractPercent;

  @override
  int get fullTimeHours => _fullTimeHours;

  @override
  DateTime get trackingStartDate =>
      savedTrackingStartDate ?? initialTrackingStartDate;

  @override
  int get openingFlexMinutes => savedOpeningMinutes ?? initialOpeningMinutes;

  @override
  Future<void> setTrackingStartDate(DateTime date) async {
    savedTrackingStartDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  @override
  Future<void> setOpeningFlexMinutes(int minutes) async {
    savedOpeningMinutes = minutes;
    notifyListeners();
  }
}

Widget _wrap({
  required SettingsProvider settingsProvider,
  required ContractProvider contractProvider,
  required VoidCallback onCompleted,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
    ],
    child: MaterialApp(
      home: WelcomeSetupScreen(onCompleted: onCompleted),
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

  testWidgets('Employee mode requires contract before continue',
      (tester) async {
    final settings = _TestSettingsProvider();
    final contract = _TestContractProvider(
      contractPercent: 0,
      fullTimeHours: 0,
      initialTrackingStartDate: DateTime(2026, 2, 19),
      initialOpeningMinutes: 0,
    );
    var completed = false;

    await tester.pumpWidget(
      _wrap(
        settingsProvider: settings,
        contractProvider: contract,
        onCompleted: () {
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please configure contract settings before continuing.'),
      findsOneWidget,
    );
    expect(completed, isFalse);
    expect(settings.isSetupCompleted, isFalse);
  });

  testWidgets('Freelancer mode can continue without contract', (tester) async {
    final settings = _TestSettingsProvider();
    final contract = _TestContractProvider(
      contractPercent: 0,
      fullTimeHours: 0,
      initialTrackingStartDate: DateTime(2026, 2, 19),
      initialOpeningMinutes: 0,
    );
    var completed = false;

    await tester.pumpWidget(
      _wrap(
        settingsProvider: settings,
        contractProvider: contract,
        onCompleted: () {
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('Freelancer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(settings.isSetupCompleted, isTrue);
    expect(settings.isTimeBalanceEnabled, isFalse);
  });
}
