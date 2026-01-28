import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/features/reports/analytics_models.dart';
import 'package:myapp/models/entry.dart';

import 'package:myapp/services/analytics_api.dart';
import 'package:myapp/viewmodels/customer_analytics_viewmodel.dart';

import 'customer_analytics_viewmodel_test.mocks.dart';

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
  });
}
