import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class DailyAggregateRow {
  final DateTime? day;
  final int workMinutes;
  final int travelMinutes;
  final int creditedLeaveMinutes;
  final Map<String, int> creditedLeaveByType;
  final int plannedMinutes;
  final int adjustmentMinutes;
  final int deltaMinutes;
  final bool isTotal;

  const DailyAggregateRow({
    required this.day,
    required this.workMinutes,
    required this.travelMinutes,
    required this.creditedLeaveMinutes,
    required this.creditedLeaveByType,
    required this.plannedMinutes,
    required this.adjustmentMinutes,
    required this.deltaMinutes,
    required this.isTotal,
  });

  int get actualMinutes => workMinutes + travelMinutes;

  factory DailyAggregateRow.fromMap(Map<String, dynamic> map) {
    return DailyAggregateRow(
      day: _parseDate(map['day']),
      workMinutes: _parseInt(map['work_minutes']),
      travelMinutes: _parseInt(map['travel_minutes']),
      creditedLeaveMinutes: _parseInt(map['credited_leave_minutes']),
      creditedLeaveByType:
          _parseByType(map['credited_leave_by_type'] as Object?),
      plannedMinutes: _parseInt(map['planned_minutes']),
      adjustmentMinutes: _parseInt(map['adjustment_minutes']),
      deltaMinutes: _parseInt(map['delta_minutes']),
      isTotal: _parseBool(map['is_total']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static int _parseInt(Object? raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final value = raw?.toString().toLowerCase().trim();
    return value == 'true' || value == '1' || value == 't';
  }

  static Map<String, int> _parseByType(Object? raw) {
    final result = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        if (key.isEmpty) continue;
        result[key] = _parseInt(entry.value);
      }
    }
    return result;
  }
}

class AggregateResult {
  final List<DailyAggregateRow> daily;
  final DailyAggregateRow totals;

  const AggregateResult({
    required this.daily,
    required this.totals,
  });
}

class TimeBalanceAggregateService {
  final SupabaseClient _supabase;

  TimeBalanceAggregateService({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  Future<AggregateResult> fetchAggregates({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime trackingStartDate,
    required bool travelEnabled,
  }) async {
    final response = await _supabase.rpc(
      'get_time_balance_aggregates',
      params: {
        'p_user_id': userId,
        'p_start_date': _toDate(startDate),
        'p_end_date': _toDate(endDate),
        'p_tracking_start_date': _toDate(trackingStartDate),
        'p_travel_enabled': travelEnabled,
      },
    );

    if (response is! List) {
      throw StateError(
          'Invalid RPC response for get_time_balance_aggregates: expected List');
    }

    final rows = response
        .whereType<Map>()
        .map((row) => DailyAggregateRow.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList();

    final daily = rows.where((row) => !row.isTotal && row.day != null).toList()
      ..sort((a, b) => a.day!.compareTo(b.day!));

    final totals = rows.firstWhere(
      (row) => row.isTotal,
      orElse: () => _sumDaily(daily),
    );

    return AggregateResult(daily: daily, totals: totals);
  }

  static String _toDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static DailyAggregateRow _sumDaily(List<DailyAggregateRow> rows) {
    var work = 0;
    var travel = 0;
    var credited = 0;
    var planned = 0;
    var adjustment = 0;
    var delta = 0;
    final byType = <String, int>{};

    for (final row in rows) {
      work += row.workMinutes;
      travel += row.travelMinutes;
      credited += row.creditedLeaveMinutes;
      planned += row.plannedMinutes;
      adjustment += row.adjustmentMinutes;
      delta += row.deltaMinutes;
      for (final entry in row.creditedLeaveByType.entries) {
        byType[entry.key] = (byType[entry.key] ?? 0) + entry.value;
      }
    }

    return DailyAggregateRow(
      day: null,
      workMinutes: work,
      travelMinutes: travel,
      creditedLeaveMinutes: credited,
      creditedLeaveByType: byType,
      plannedMinutes: planned,
      adjustmentMinutes: adjustment,
      deltaMinutes: delta,
      isTotal: true,
    );
  }
}
