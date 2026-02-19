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
      expect(monthsWithTravel.first.workMinutes, 120);
      expect(monthsWithTravel.first.travelMinutes, 30);
      expect(monthsWithTravel.first.totalMinutes, 150);

      final trendsWithTravel = viewModel.trendsData;
      final dailyWithTravel =
          trendsWithTravel['dailyTrends'] as List<Map<String, dynamic>>;
      final dailyTotalWithTravel = dailyWithTravel.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(dailyWithTravel, hasLength(3));
      expect(dailyTotalWithTravel, 150);

      viewModel.setTravelEnabled(false);
      final monthsWithoutTravel = viewModel.monthlyBreakdown;
      expect(monthsWithoutTravel.first.workMinutes, 120);
      expect(monthsWithoutTravel.first.travelMinutes, 0);
      expect(monthsWithoutTravel.first.totalMinutes, 120);

      final trendsWithoutTravel = viewModel.trendsData;
      final dailyWithoutTravel =
          trendsWithoutTravel['dailyTrends'] as List<Map<String, dynamic>>;
      final dailyTotalWithoutTravel = dailyWithoutTravel.fold<int>(
        0,
        (sum, day) => sum + (day['totalMinutes'] as int? ?? 0),
      );
      expect(dailyTotalWithoutTravel, 120);
    });
  });
}
