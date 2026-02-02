class ServerDailyTrend {
  final DateTime date;
  final double totalHours;
  final double workHours;
  final double travelHours;
  const ServerDailyTrend({
    required this.date,
    required this.totalHours,
    required this.workHours,
    required this.travelHours,
  });
  factory ServerDailyTrend.fromMap(Map<String, dynamic> m) => ServerDailyTrend(
        date: DateTime.parse(m['date'] as String),
        totalHours: (m['totalHours'] as num).toDouble(),
        workHours: (m['workHours'] as num).toDouble(),
        travelHours: (m['travelHours'] as num).toDouble(),
      );
}

class ServerUserSlice {
  final String userId;
  final String userName;
  final double totalHours;
  final double percentage;
  const ServerUserSlice({
    required this.userId,
    required this.userName,
    required this.totalHours,
    required this.percentage,
  });
  factory ServerUserSlice.fromMap(Map<String, dynamic> m) => ServerUserSlice(
        userId: (m['userId'] ?? '') as String,
        userName: (m['userName'] ?? '') as String,
        totalHours: (m['totalHours'] as num).toDouble(),
        percentage: (m['percentage'] as num).toDouble(),
      );
}

class ServerAnalytics {
  final double totalHoursLoggedThisWeek;
  final int activeUsers;
  final double overtimeBalance;
  final double averageDailyHours;
  final List<ServerDailyTrend> dailyTrends;
  final List<ServerUserSlice> userDistribution;
  const ServerAnalytics({
    required this.totalHoursLoggedThisWeek,
    required this.activeUsers,
    required this.overtimeBalance,
    required this.averageDailyHours,
    required this.dailyTrends,
    required this.userDistribution,
  });
  factory ServerAnalytics.fromMap(Map<String, dynamic> m) => ServerAnalytics(
        totalHoursLoggedThisWeek:
            (m['totalHoursLoggedThisWeek'] as num).toDouble(),
        activeUsers: (m['activeUsers'] as num).toInt(),
        overtimeBalance: (m['overtimeBalance'] as num).toDouble(),
        averageDailyHours: (m['averageDailyHours'] as num).toDouble(),
        dailyTrends: (m['dailyTrends'] as List<dynamic>)
            .map((e) => ServerDailyTrend.fromMap(e as Map<String, dynamic>))
            .toList(growable: false),
        userDistribution: (m['userDistribution'] as List<dynamic>)
            .map((e) => ServerUserSlice.fromMap(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
