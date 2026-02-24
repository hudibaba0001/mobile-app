import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/providers/absence_provider.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/providers/time_provider.dart';
import 'package:myapp/services/supabase_absence_service.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthService extends Mock
    with ChangeNotifier
    implements SupabaseAuthService {
  User? user;

  @override
  User? get currentUser => user;
}

class _FakeAbsenceService implements SupabaseAbsenceService {
  final Map<int, List<AbsenceEntry>> _byYear;

  _FakeAbsenceService(this._byYear);

  @override
  Future<List<AbsenceEntry>> fetchAbsencesForYear(
      String userId, int year) async {
    return _byYear[year] ?? const [];
  }

  @override
  Future<String> addAbsence(String userId, AbsenceEntry absence) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAbsence(
    String userId,
    String absenceId,
    AbsenceEntry absence,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAbsence(String userId, String absenceId) {
    throw UnimplementedError();
  }
}

User _user(String id) {
  return User(
    id: id,
    email: '$id@example.com',
    appMetadata: const {},
    userMetadata: const {},
    createdAt: DateTime(2026, 1, 1).toIso8601String(),
    aud: '',
  );
}

final DateTime _weekdayNoRedDay = DateTime(2026, 2, 27); // Friday, non-red day

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int fullTimeWeeklyMinutes = 40 * 60;
  const int case75WeeklyMinutes = 30 * 60;
  const int case100WeeklyMinutes = 40 * 60;

  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  });

  Future<TimeProvider> _buildProviderForWeeklyTarget({
    required int weeklyTargetMinutes,
    required DateTime leaveDate,
  }) async {
    final contractPercent =
        ((weeklyTargetMinutes / fullTimeWeeklyMinutes) * 100).round();
    final trackingStart =
        '${leaveDate.year}-${leaveDate.month.toString().padLeft(2, '0')}-${leaveDate.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'contract_percent': contractPercent,
      'full_time_hours': 40,
      'tracking_start_date': trackingStart,
      'opening_flex_minutes': 0,
      'employer_mode': 'standard',
    });

    final authService = _StubAuthService()..user = _user('user-1');
    final absenceService = _FakeAbsenceService({
      leaveDate.year: [
        AbsenceEntry(
          id: 'leave-${leaveDate.year}-${leaveDate.month}-${leaveDate.day}',
          date: leaveDate,
          minutes: 0, // full-day leave
          type: AbsenceType.vacationPaid,
        ),
      ],
    });

    final contractProvider = ContractProvider();
    await contractProvider.init();

    final entryProvider = EntryProvider(authService); // no entries needed
    final absenceProvider = AbsenceProvider(authService, absenceService);
    final timeProvider = TimeProvider(
      entryProvider,
      contractProvider,
      absenceProvider,
    );

    await timeProvider.calculateBalances(year: leaveDate.year);
    return timeProvider;
  }

  Map<String, dynamic> _monthVarianceRow(TimeProvider provider, DateTime date) {
    final detailed = provider.getDetailedBalance();
    final rows =
        (detailed['monthlyVariances'] as List).cast<Map<String, dynamic>>();
    return rows.firstWhere(
      (row) => row['year'] == date.year && row['month'] == 'February',
    );
  }

  group('Credited leave contract-aware regression', () {
    test('A) 75% full-day leave credits 360 minutes (never 480)', () async {
      final provider = await _buildProviderForWeeklyTarget(
        weeklyTargetMinutes: case75WeeklyMinutes,
        leaveDate: _weekdayNoRedDay,
      );

      final creditedMinutes =
          (provider.monthlyCreditHours(year: 2026, month: 2) * 60).round();

      expect(
        creditedMinutes,
        360,
        reason: '75% contract full-day leave must credit 6h (360m).',
      );
      expect(
        creditedMinutes,
        isNot(480),
        reason:
            'Regression guard: part-time full-day leave must not default to 8h (480m).',
      );

      final feb = _monthVarianceRow(provider, _weekdayNoRedDay);
      final plannedMinutes =
          ((feb['targetHours'] as num).toDouble() * 60).round();
      final overUnderMinutes =
          ((feb['variance'] as num).toDouble() * 60).round();

      expect(
        plannedMinutes,
        360,
        reason:
            'With tracking start on 2026-02-27, February planned time should be one scheduled workday (6h).',
      );
      expect(
        overUnderMinutes,
        0,
        reason:
            'Over/under plan must use the same 360 credited leave against 360 planned.',
      );
    });

    test('B) 100% full-day leave credits 480 minutes', () async {
      final provider = await _buildProviderForWeeklyTarget(
        weeklyTargetMinutes: case100WeeklyMinutes,
        leaveDate: _weekdayNoRedDay,
      );

      final creditedMinutes =
          (provider.monthlyCreditHours(year: 2026, month: 2) * 60).round();

      expect(
        creditedMinutes,
        480,
        reason: '100% contract full-day leave must credit 8h (480m).',
      );

      final feb = _monthVarianceRow(provider, _weekdayNoRedDay);
      final plannedMinutes =
          ((feb['targetHours'] as num).toDouble() * 60).round();
      final overUnderMinutes =
          ((feb['variance'] as num).toDouble() * 60).round();

      expect(plannedMinutes, 480);
      expect(overUnderMinutes, 0);
    });
  });
}
