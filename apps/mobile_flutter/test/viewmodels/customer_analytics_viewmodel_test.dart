import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/features/reports/analytics_models.dart';
import 'package:myapp/models/entry.dart';

import 'package:myapp/services/analytics_api.dart';
import 'package:myapp/viewmodels/customer_analytics_viewmodel.dart';

import 'customer_analytics_viewmodel_test.mocks.dart';

Entry _workEntry({
  required String id,
  required DateTime date,
  required int workedMinutes,
}) {
  final shiftStart = DateTime(date.year, date.month, date.day, 9, 0);
  final shiftEnd = shiftStart.add(Duration(minutes: workedMinutes));
  return Entry(
    id: id,
    userId: 'user_1',
    type: EntryType.work,
    date: date,
    shifts: [
      Shift(
        start: shiftStart,
        end: shiftEnd,
      ),
    ],
    createdAt: DateTime(2026, 1, 1),
  );
}

Entry _travelEntry({
  required String id,
  required DateTime date,
  required int travelMinutes,
}) {
  return Entry(
    id: id,
    userId: 'user_1',
    type: EntryType.travel,
    date: date,
    from: 'A',
    to: 'B',
    travelMinutes: travelMinutes,
    createdAt: DateTime(2026, 1, 1),
  );
}

int _sumWeeklyMinutes(Map<String, dynamic> trendsData) {
  final weekly = trendsData['weeklyMinutes'] as List<int>? ?? const <int>[];
  return weekly.fold<int>(0, (sum, minutes) => sum + minutes);
}

int _sumMonthlyTotalMinutes(List<MonthlyBreakdown> months) {
  return months.fold<int>(0, (sum, month) => sum + month.totalMinutes);
}

MonthlyBreakdown _monthBreakdownFor(
  List<MonthlyBreakdown> months, {
  required int year,
  required int month,
}) {
  return months.firstWhere(
    (value) => value.month.year == year && value.month.month == month,
  );
}

@GenerateMocks([AnalyticsApi])
void main() {
  group('CustomerAnalyticsViewModel', () {
    late CustomerAnalyticsViewModel viewModel;
    late MockAnalyticsApi mockAnalyticsApi;
    late List<Entry> entries;

    setUp(() {
      mockAnalyticsApi = MockAnalyticsApi();
      entries = [];

      viewModel = CustomerAnalyticsViewModel(analyticsApi: mockAnalyticsApi);
    });

    tearDown(() {
      AppConfig.setApiBase(''); // Reset AppConfig for other tests
    });

    test('initializes with local data when API base is not provided', () async {
      AppConfig.setApiBase('');

      viewModel.bindEntries(entries, userId: 'user_1');

      // Allow microtasks to complete (for the async loading)
      await Future.delayed(Duration.zero);

      expect(viewModel.usingServer, isFalse);
      expect(viewModel.lastServerError, isNull);
      verifyNever(mockAnalyticsApi.fetchDashboard());
    });

    test('fetches server data successfully when API base is provided',
        () async {
      AppConfig.setApiBase('http://test.com');
      final serverData = ServerAnalytics(
        totalHoursLoggedThisWeek: 10.0,
        activeUsers: 1,
        overtimeBalance: 2.0,
        averageDailyHours: 2.0,
        dailyTrends: [],
        userDistribution: [],
      );

      when(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => serverData);

      viewModel.bindEntries(entries, userId: 'user_1');

      // Allow microtasks to complete
      await Future.delayed(Duration.zero);

      expect(viewModel.usingServer, isTrue);
      expect(viewModel.lastServerError, isNull);
      verify(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).called(1);
    });

    test(
        'falls back to local data when server fetch throws a generic exception',
        () async {
      AppConfig.setApiBase('http://test.com');
      final exception = Exception('Network Error');
      when(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).thenThrow(exception);

      viewModel.bindEntries(entries, userId: 'user_1');

      await Future.delayed(Duration.zero);

      expect(viewModel.usingServer, isFalse);
      expect(viewModel.lastServerError, contains('Network Error'));
      verify(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).called(1);
    });

    test('falls back to local data on 401 Unauthorized error from server',
        () async {
      AppConfig.setApiBase('http://test.com');
      final exception = AuthException('Unauthorized');
      when(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).thenThrow(exception);

      viewModel.bindEntries(entries, userId: 'user_1');

      await Future.delayed(Duration.zero);

      expect(viewModel.usingServer, isFalse);
      expect(viewModel.lastServerError, contains('Access denied'));
      verify(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).called(1);
    });

    test('falls back to local data on 403 Forbidden error from server',
        () async {
      AppConfig.setApiBase('http://test.com');
      final exception = AuthException('Forbidden');
      when(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).thenThrow(exception);

      viewModel.bindEntries(entries, userId: 'user_1');

      await Future.delayed(Duration.zero);

      expect(viewModel.usingServer, isFalse);
      expect(viewModel.lastServerError, contains('Access denied'));
      verify(mockAnalyticsApi.fetchDashboard(
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        userId: anyNamed('userId'),
      )).called(1);
    });

    test('trends use minute buckets for selected range and travel toggle', () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'w-in-range',
          date: DateTime(2026, 1, 10, 9, 0),
          workedMinutes: 120,
        ),
        _travelEntry(
          id: 't-in-range',
          date: DateTime(2026, 1, 12, 18, 0),
          travelMinutes: 30,
        ),
        _workEntry(
          id: 'w-out-range',
          date: DateTime(2026, 2, 3, 9, 0),
          workedMinutes: 300,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 1, 10), DateTime(2026, 1, 12));
      viewModel.setTravelEnabled(true);

      final monthsWithTravel = viewModel.monthlyBreakdown;
      expect(monthsWithTravel, hasLength(1));
      final januaryWithTravel =
          _monthBreakdownFor(monthsWithTravel, year: 2026, month: 1);
      expect(januaryWithTravel.workMinutes, 120);
      expect(januaryWithTravel.travelMinutes, 30);
      expect(januaryWithTravel.totalMinutes, 150);

      final trendsWithTravel = viewModel.trendsData;
      final dailyWithTravel =
          trendsWithTravel['dailyTrends'] as List<Map<String, dynamic>>;
      final dailyTotalWithTravel = dailyWithTravel.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(dailyWithTravel, hasLength(7));
      expect(dailyWithTravel.first['date'], DateTime(2026, 1, 6));
      expect(dailyWithTravel.last['date'], DateTime(2026, 1, 12));
      expect(dailyTotalWithTravel, 150);

      viewModel.setTravelEnabled(false);
      final monthsWithoutTravel = viewModel.monthlyBreakdown;
      expect(monthsWithoutTravel, hasLength(1));
      final januaryWithoutTravel =
          _monthBreakdownFor(monthsWithoutTravel, year: 2026, month: 1);
      expect(januaryWithoutTravel.workMinutes, 120);
      expect(januaryWithoutTravel.travelMinutes, 0);
      expect(januaryWithoutTravel.totalMinutes, 120);

      final trendsWithoutTravel = viewModel.trendsData;
      final dailyWithoutTravel =
          trendsWithoutTravel['dailyTrends'] as List<Map<String, dynamic>>;
      final dailyTotalWithoutTravel = dailyWithoutTravel.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(dailyTotalWithoutTravel, 120);
    });

    test('daily trends use trailing 7-day window ending at selected end date',
        () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'w-before-selected-start',
          date: DateTime(2026, 1, 6),
          workedMinutes: 30,
        ),
        _workEntry(
          id: 'w-selected-start',
          date: DateTime(2026, 1, 10),
          workedMinutes: 60,
        ),
        _travelEntry(
          id: 't-selected-end',
          date: DateTime(2026, 1, 12),
          travelMinutes: 15,
        ),
        _workEntry(
          id: 'w-after-window',
          date: DateTime(2026, 1, 13),
          workedMinutes: 90,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 1, 10), DateTime(2026, 1, 12));
      viewModel.setTravelEnabled(true);
      viewModel.setTrendsEntryTypeFilter(null);

      final daily =
          viewModel.trendsData['dailyTrends'] as List<Map<String, dynamic>>;
      expect(daily, hasLength(7));
      expect(daily.first['date'], DateTime(2026, 1, 6));
      expect(daily.last['date'], DateTime(2026, 1, 12));

      final jan6 = daily.firstWhere(
        (day) => day['date'] == DateTime(2026, 1, 6),
      );
      final jan12 = daily.firstWhere(
        (day) => day['date'] == DateTime(2026, 1, 12),
      );
      expect(jan6['totalMinutes'], 30);
      expect(jan12['totalMinutes'], 15);

      final total = daily.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(total, 105);
    });

    test('trends apply inclusive date boundaries for selected range', () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'w-start-day',
          date: DateTime(2026, 1, 1),
          workedMinutes: 60,
        ),
        _travelEntry(
          id: 't-end-day',
          date: DateTime(2026, 1, 31),
          travelMinutes: 30,
        ),
        _workEntry(
          id: 'w-outside',
          date: DateTime(2026, 2, 1),
          workedMinutes: 90,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      viewModel.setTravelEnabled(true);
      viewModel.setTrendsEntryTypeFilter(null);

      final months = viewModel.monthlyBreakdown;
      expect(months, hasLength(1));
      final january = _monthBreakdownFor(months, year: 2026, month: 1);
      expect(january.workMinutes, 60);
      expect(january.travelMinutes, 30);
      expect(january.totalMinutes, 90);
      expect(_sumWeeklyMinutes(viewModel.trendsData), 90);
    });

    test('trends segment filter controls bucketing and bucket sums', () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'w1',
          date: DateTime(2026, 1, 5),
          workedMinutes: 120,
        ),
        _workEntry(
          id: 'w2',
          date: DateTime(2026, 1, 6),
          workedMinutes: 180,
        ),
        _travelEntry(
          id: 't1',
          date: DateTime(2026, 1, 5),
          travelMinutes: 30,
        ),
        _travelEntry(
          id: 't2',
          date: DateTime(2026, 1, 7),
          travelMinutes: 60,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      viewModel.setTravelEnabled(true);

      viewModel.setTrendsEntryTypeFilter(null);
      final allMonths = viewModel.monthlyBreakdown;
      expect(allMonths, hasLength(1));
      final januaryAll = _monthBreakdownFor(allMonths, year: 2026, month: 1);
      expect(januaryAll.workMinutes, 300);
      expect(januaryAll.travelMinutes, 90);
      expect(januaryAll.totalMinutes, 390);
      expect(_sumWeeklyMinutes(viewModel.trendsData), 390);
      expect(_sumWeeklyMinutes(viewModel.trendsData),
          _sumMonthlyTotalMinutes(allMonths));

      viewModel.setTrendsEntryTypeFilter(EntryType.work);
      final workMonths = viewModel.monthlyBreakdown;
      expect(workMonths, hasLength(1));
      final januaryWork = _monthBreakdownFor(workMonths, year: 2026, month: 1);
      expect(januaryWork.workMinutes, 300);
      expect(januaryWork.travelMinutes, 0);
      expect(januaryWork.totalMinutes, 300);
      expect(_sumWeeklyMinutes(viewModel.trendsData), 300);
      expect(_sumWeeklyMinutes(viewModel.trendsData),
          _sumMonthlyTotalMinutes(workMonths));

      viewModel.setTrendsEntryTypeFilter(EntryType.travel);
      final travelMonths = viewModel.monthlyBreakdown;
      expect(travelMonths, hasLength(1));
      final januaryTravel =
          _monthBreakdownFor(travelMonths, year: 2026, month: 1);
      expect(januaryTravel.workMinutes, 0);
      expect(januaryTravel.travelMinutes, 90);
      expect(januaryTravel.totalMinutes, 90);
      expect(_sumWeeklyMinutes(viewModel.trendsData), 90);
      expect(_sumWeeklyMinutes(viewModel.trendsData),
          _sumMonthlyTotalMinutes(travelMonths));

      viewModel.setTravelEnabled(false);
      viewModel.setTrendsEntryTypeFilter(null);
      final allWithoutTravel = viewModel.monthlyBreakdown;
      viewModel.setTrendsEntryTypeFilter(EntryType.work);
      final workWithoutTravel = viewModel.monthlyBreakdown;
      final januaryAllWithoutTravel =
          _monthBreakdownFor(allWithoutTravel, year: 2026, month: 1);
      final januaryWorkWithoutTravel =
          _monthBreakdownFor(workWithoutTravel, year: 2026, month: 1);

      expect(januaryAllWithoutTravel.travelMinutes, 0);
      expect(januaryAllWithoutTravel.totalMinutes,
          januaryWorkWithoutTravel.totalMinutes);
      expect(_sumWeeklyMinutes(viewModel.trendsData),
          _sumMonthlyTotalMinutes(workWithoutTravel));
    });

    test(
        'monthly breakdown includes previous month context for single-month range',
        () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'jan-work',
          date: DateTime(2026, 1, 20),
          workedMinutes: 90,
        ),
        _workEntry(
          id: 'feb-work',
          date: DateTime(2026, 2, 18),
          workedMinutes: 120,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 2, 1), DateTime(2026, 2, 19));
      viewModel.setTravelEnabled(true);
      viewModel.setTrendsEntryTypeFilter(null);

      final months = viewModel.monthlyBreakdown;
      expect(months, hasLength(2));
      expect(months.first.month.year, 2026);
      expect(months.first.month.month, 1);
      expect(months.first.totalMinutes, 90);
      expect(months.last.month.year, 2026);
      expect(months.last.month.month, 2);
      expect(months.last.totalMinutes, 120);

      // Daily/weekly buckets must still respect selected range (February only).
      final trendsData = viewModel.trendsData;
      expect(_sumWeeklyMinutes(trendsData), 120);
      final daily = trendsData['dailyTrends'] as List<Map<String, dynamic>>;
      final dailyTotal = daily.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(dailyTotal, 120);
    });

    test(
        'monthly breakdown for single-month selection includes Jan to selected month',
        () {
      AppConfig.setApiBase('');
      final scopedEntries = <Entry>[
        _workEntry(
          id: 'jan-work',
          date: DateTime(2026, 1, 5),
          workedMinutes: 60,
        ),
        _workEntry(
          id: 'mar-work',
          date: DateTime(2026, 3, 10),
          workedMinutes: 120,
        ),
      ];

      viewModel.bindEntries(scopedEntries, userId: 'user_1');
      viewModel.setDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      viewModel.setTravelEnabled(true);
      viewModel.setTrendsEntryTypeFilter(null);

      final months = viewModel.monthlyBreakdown;
      expect(months, hasLength(3));
      expect(months[0].month.year, 2026);
      expect(months[0].month.month, 1);
      expect(months[0].totalMinutes, 60);
      expect(months[1].month.year, 2026);
      expect(months[1].month.month, 2);
      expect(months[1].totalMinutes, 0);
      expect(months[2].month.year, 2026);
      expect(months[2].month.month, 3);
      expect(months[2].totalMinutes, 120);
    });
  });
}
