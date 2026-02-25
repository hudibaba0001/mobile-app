import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/calendar/sweden_holidays.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/user_red_day.dart';
import 'package:myapp/providers/absence_provider.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/providers/time_provider.dart';
import 'package:myapp/repositories/user_red_day_repository.dart';
import 'package:myapp/services/holiday_service.dart';
import 'package:myapp/services/supabase_absence_service.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/utils/target_hours_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthService extends Mock
    with ChangeNotifier
    implements SupabaseAuthService {
  User? user;

  @override
  User? get currentUser => user;
}

class _EmptyAbsenceService implements SupabaseAbsenceService {
  @override
  Future<List<AbsenceEntry>> fetchAbsencesForYear(
      String userId, int year) async {
    return const [];
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

class _InMemoryUserRedDayRepository extends UserRedDayRepository {
  final Map<String, UserRedDay> _store = <String, UserRedDay>{};

  _InMemoryUserRedDayRepository({required SupabaseClient supabase})
      : super(supabase: supabase);

  DateTime _d(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dateString(DateTime date) {
    final normalized = _d(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _key(String userId, DateTime date) => '$userId:${_dateString(date)}';

  @override
  Future<List<UserRedDay>> getForYear({
    required String userId,
    required int year,
  }) async {
    final result = _store.values
        .where((day) => day.userId == userId && day.date.year == year)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Future<UserRedDay> upsert(UserRedDay redDay) async {
    final normalized = _d(redDay.date);
    final key = _key(redDay.userId, normalized);
    final existing = _store[key];
    final now = DateTime.now().toUtc();

    final saved = redDay.copyWith(
      id: existing?.id ?? 'rd-${redDay.userId}-${_dateString(normalized)}',
      date: normalized,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    _store[key] = saved;
    return saved;
  }

  @override
  Future<void> deleteForDate({
    required String userId,
    required DateTime date,
  }) async {
    _store.remove(_key(userId, _d(date)));
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

int _scheduledMinutesForDateViaHolidayService({
  required DateTime date,
  required int weeklyTargetMinutes,
  required HolidayService holidayService,
}) {
  final redDayInfo = holidayService.getRedDayInfo(date);
  if (redDayInfo.isRedDay) {
    return TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
      date: date,
      weeklyTargetMinutes: weeklyTargetMinutes,
      isFullRedDay: redDayInfo.isFullDay,
      isHalfRedDay: redDayInfo.halfDay != null,
    );
  }

  return TargetHoursCalculator.scheduledMinutesForDate(
    date: date,
    weeklyTargetMinutes: weeklyTargetMinutes,
    holidays: SwedenHolidayCalendar(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  });

  test('custom red day makes planned=0 and lifts over/under by +480', () async {
    const weeklyTargetMinutes = 2400; // 100% contract
    final trackingStartDate = DateTime(2026, 2, 2); // Monday
    final customRedDate = DateTime(2026, 2, 3); // Tuesday
    const year = 2026;
    const month = 2;

    final trackingStart =
        '${trackingStartDate.year}-${trackingStartDate.month.toString().padLeft(2, '0')}-${trackingStartDate.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'contract_percent': 100,
      'full_time_hours': 40,
      'tracking_start_date': trackingStart,
      'opening_flex_minutes': 0,
      'employer_mode': 'standard',
    });

    final authService = _StubAuthService()..user = _user('user-1');
    final contractProvider = ContractProvider();
    await contractProvider.init();

    final entryProvider = EntryProvider(authService); // no work entries
    final absenceProvider =
        AbsenceProvider(authService, _EmptyAbsenceService());
    final redDayRepository = _InMemoryUserRedDayRepository(
      supabase: Supabase.instance.client,
    );
    final holidayService = HolidayService()
      ..initialize(repository: redDayRepository, userId: 'user-1');

    final timeProvider = TimeProvider(
      entryProvider,
      contractProvider,
      absenceProvider,
      null,
      holidayService,
    );

    await timeProvider.calculateBalances(year: year);

    final baselineTarget = timeProvider.monthTargetMinutesToDate(year, month);
    final baselineActual = timeProvider.monthActualMinutesToDate(year, month);
    final baselineCredit = timeProvider.monthCreditMinutesToDate(year, month);
    final baselineDelta = (baselineActual + baselineCredit) - baselineTarget;
    final baselineScheduledOnRedDate =
        _scheduledMinutesForDateViaHolidayService(
      date: customRedDate,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidayService: holidayService,
    );

    expect(baselineScheduledOnRedDate, 480);
    expect(baselineActual, 0);
    expect(baselineCredit, 0);

    await holidayService.upsertPersonalRedDay(
      UserRedDay(
        userId: 'user-1',
        date: customRedDate,
        kind: RedDayKind.full,
        reason: 'Trust regression test red day',
      ),
    );

    await timeProvider.calculateBalances(year: year);

    final redScheduledOnDate = _scheduledMinutesForDateViaHolidayService(
      date: customRedDate,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidayService: holidayService,
    );
    final redTarget = timeProvider.monthTargetMinutesToDate(year, month);
    final redActual = timeProvider.monthActualMinutesToDate(year, month);
    final redCredit = timeProvider.monthCreditMinutesToDate(year, month);
    final redDelta = (redActual + redCredit) - redTarget;

    // 1) scheduledMinutesForThatDate == 0
    expect(redScheduledOnDate, 0);

    // 2) month planned (to-date) drops by exactly one workday (8h / 480m)
    expect(baselineTarget - redTarget, 480);

    // 3) Over/under increases by +480 when planned drops by 480 and actual/credit stay unchanged
    expect(redDelta - baselineDelta, 480);

    // 4) No "holiday credit" added; only planned changes
    expect(redActual, 0);
    expect(redCredit, 0);
  });
}
