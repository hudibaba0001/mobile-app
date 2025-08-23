import 'package:flutter_test/flutter_test.dart';
// Test-only import that re-exports the library from /lib without relying on the package name.
import 'helpers/analytics_models_import.dart';

void main() {
  test('ServerAnalytics.fromMap parses dashboard payload correctly', () {
    final map = {
      'totalHoursLoggedThisWeek': 12.5,
      'activeUsers': 3,
      'overtimeBalance': -27.5,
      'averageDailyHours': 2.5,
      'dailyTrends': [
        {
          'date': DateTime(2024, 1, 1).toIso8601String(),
          'totalHours': 2.5,
          'workHours': 1.5,
          'travelHours': 1.0
        },
        {
          'date': DateTime(2024, 1, 2).toIso8601String(),
          'totalHours': 3.0,
          'workHours': 2.0,
          'travelHours': 1.0
        },
      ],
      'userDistribution': [
        {
          'userId': 'u1',
          'userName': 'Alice',
          'totalHours': 5.0,
          'percentage': 40.0
        },
        {
          'userId': 'u2',
          'userName': 'Bob',
          'totalHours': 7.5,
          'percentage': 60.0
        },
      ]
    };

    final sa = ServerAnalytics.fromMap(map);
    expect(sa.totalHoursLoggedThisWeek, 12.5);
    expect(sa.activeUsers, 3);
    expect(sa.overtimeBalance, -27.5);
    expect(sa.averageDailyHours, 2.5);

    expect(sa.dailyTrends.length, 2);
    expect(sa.dailyTrends.first.totalHours, 2.5);
    expect(sa.dailyTrends.first.workHours, 1.5);
    expect(sa.dailyTrends.first.travelHours, 1.0);
    expect(sa.dailyTrends.first.date, DateTime(2024, 1, 1));

    expect(sa.userDistribution.length, 2);
    expect(sa.userDistribution.first.userId, 'u1');
    expect(sa.userDistribution.first.userName, 'Alice');
    expect(sa.userDistribution.first.totalHours, 5.0);
    expect(sa.userDistribution.first.percentage, 40.0);
  });
}
