import '../models/absence.dart';
import '../models/entry.dart';
import '../reporting/leave_minutes.dart';
import 'report_query_service.dart';

class ReportSummary {
  final List<Entry> filteredEntries;
  final int workMinutes;
  final int travelMinutes;
  final int totalTrackedMinutes;
  final WorkInsights workInsights;
  final TravelInsights travelInsights;
  final LeavesSummary leavesSummary;
  final BalanceOffsetSummary balanceOffsets;

  const ReportSummary({
    required this.filteredEntries,
    required this.workMinutes,
    required this.travelMinutes,
    required this.totalTrackedMinutes,
    required this.workInsights,
    required this.travelInsights,
    required this.leavesSummary,
    required this.balanceOffsets,
  });

  /// Explicit alias used by reports/export integration.
  int get trackedMinutes => totalTrackedMinutes;

  /// Sum of in-range adjustment minutes only (does not include opening balance).
  int get balanceAdjustmentMinutesInRange =>
      balanceOffsets.adjustmentsInRangeMinutes;

  /// Opening balance minutes, 0 when opening event is out of range/future.
  int get openingBalanceMinutes => balanceOffsets.openingEvent?.minutes ?? 0;

  /// Convenience aliases for saldo section.
  int get startingBalanceMinutes => balanceOffsets.startingBalanceMinutes;
  int get closingBalanceMinutes => balanceOffsets.closingBalanceMinutes;
}

class WorkInsights {
  final LongestShiftInsight? longestShift;
  final double averageWorkedMinutesPerDay;
  final int totalBreakMinutes;
  final double averageBreakMinutesPerShift;
  final int shiftCount;
  final int activeWorkDays;

  const WorkInsights({
    required this.longestShift,
    required this.averageWorkedMinutesPerDay,
    required this.totalBreakMinutes,
    required this.averageBreakMinutesPerShift,
    required this.shiftCount,
    required this.activeWorkDays,
  });
}

class LongestShiftInsight {
  final DateTime date;
  final int spanMinutes;
  final int workedMinutes;
  final int breakMinutes;
  final String? location;
  final String? notes;
  final Entry entry;

  const LongestShiftInsight({
    required this.date,
    required this.spanMinutes,
    required this.workedMinutes,
    required this.breakMinutes,
    required this.location,
    required this.notes,
    required this.entry,
  });
}

class TravelInsights {
  final int tripCount;
  final double averageMinutesPerTrip;
  final List<RouteSummary> topRoutes;

  const TravelInsights({
    required this.tripCount,
    required this.averageMinutesPerTrip,
    required this.topRoutes,
  });
}

class RouteSummary {
  final String from;
  final String to;
  final String routeKey;
  final int tripCount;
  final int totalMinutes;

  const RouteSummary({
    required this.from,
    required this.to,
    required this.routeKey,
    required this.tripCount,
    required this.totalMinutes,
  });
}

class LeavesSummary {
  final List<AbsenceEntry> absences;
  final Map<AbsenceType, LeaveTypeSummary> byType;
  final int totalEntries;
  final int totalMinutes;
  final double totalDays;

  const LeavesSummary({
    required this.absences,
    required this.byType,
    required this.totalEntries,
    required this.totalMinutes,
    required this.totalDays,
  });

  int get unpaidMinutes => byType[AbsenceType.unpaid]?.totalMinutes ?? 0;

  int get paidMinutes => totalMinutes - unpaidMinutes;

  int get creditedMinutes => paidMinutes;
}

class LeaveTypeSummary {
  final int entryCount;
  final int fullDayCount;
  final int totalMinutes;
  final double totalDays;

  const LeaveTypeSummary({
    required this.entryCount,
    required this.fullDayCount,
    required this.totalMinutes,
    required this.totalDays,
  });
}

class BalanceOffsetSummary {
  final BalanceOffsetEvent? openingEvent;
  final List<BalanceOffsetEvent> adjustmentsInRange;
  final List<BalanceOffsetEvent> eventsBeforeStart;
  final List<BalanceOffsetEvent> eventsInRange;
  final int startingBalanceMinutes;
  final int closingBalanceMinutes;

  const BalanceOffsetSummary({
    required this.openingEvent,
    required this.adjustmentsInRange,
    required this.eventsBeforeStart,
    required this.eventsInRange,
    required this.startingBalanceMinutes,
    required this.closingBalanceMinutes,
  });

  int get adjustmentsInRangeMinutes =>
      adjustmentsInRange.fold<int>(0, (sum, adj) => sum + adj.minutes);
}

class BalanceOffsetEvent {
  final DateTime effectiveDate;
  final int minutes;
  final String type;
  final String? note;

  const BalanceOffsetEvent({
    required this.effectiveDate,
    required this.minutes,
    required this.type,
    this.note,
  });

  factory BalanceOffsetEvent.opening({
    required DateTime effectiveDate,
    required int minutes,
  }) {
    return BalanceOffsetEvent(
      effectiveDate:
          DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day),
      minutes: minutes,
      type: 'opening_balance',
    );
  }

  factory BalanceOffsetEvent.adjustment({
    required DateTime effectiveDate,
    required int minutes,
    String? note,
  }) {
    return BalanceOffsetEvent(
      effectiveDate:
          DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day),
      minutes: minutes,
      type: 'adjustment',
      note: note,
    );
  }
}

/// Aggregates report data into one source usable by both report UI and export.
///
/// Important:
/// - Tracked work/travel totals are entries-only.
/// - Opening balance and adjustments are represented separately as saldo offsets.
class ReportAggregator {
  final ReportQueryService _queryService;

  ReportAggregator({
    required ReportQueryService queryService,
  }) : _queryService = queryService;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isOnOrBefore(DateTime a, DateTime b) {
    return !a.isAfter(b);
  }

  bool _isAfter(DateTime a, DateTime b) {
    return a.isAfter(b);
  }

  Future<ReportSummary> buildSummary({
    required DateTime start,
    required DateTime end,
    EntryType? selectedType,
  }) async {
    final startDate = _dateOnly(start);
    final endDate = _dateOnly(end);
    if (endDate.isBefore(startDate)) {
      throw ArgumentError.value(
        end,
        'end',
        'End date must be on or after start date.',
      );
    }

    final queryData = await _queryService.getReportData(
      ReportQuerySpec(
        start: startDate,
        end: endDate,
        selectedType: selectedType,
      ),
    );
    final filteredEntries = queryData.entriesInRange;
    final absences = queryData.leavesInRange;
    final openingConfig = OpeningBalanceConfig(
      trackingStartDate: queryData.profileTrackingInfo.trackingStartDate,
      openingFlexMinutes: queryData.profileTrackingInfo.openingFlexMinutes,
    );
    // Period-start semantics:
    // - effective date <= startDate => already applied at period start
    // - effective date > startDate && <= endDate => change during period
    final adjustmentsOnOrBeforeStart =
        queryData.adjustmentsUpToEnd.where((adj) {
      final date = _dateOnly(adj.effectiveDate);
      return !date.isBefore(openingConfig.trackingStartDate) &&
          _isOnOrBefore(date, startDate);
    }).toList()
          ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    final adjustmentsAfterStartInRange =
        queryData.adjustmentsUpToEnd.where((adj) {
      final date = _dateOnly(adj.effectiveDate);
      return !date.isBefore(openingConfig.trackingStartDate) &&
          _isAfter(date, startDate) &&
          _isOnOrBefore(date, endDate);
    }).toList()
          ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    final sortedEntries = List<Entry>.from(filteredEntries)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        final aTime = a.updatedAt ?? a.createdAt;
        final bTime = b.updatedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

    final workMinutes = sortedEntries
        .where((entry) => entry.type == EntryType.work)
        .fold<int>(0, (sum, entry) => sum + entry.workDuration.inMinutes);
    final travelMinutes = sortedEntries
        .where((entry) => entry.type == EntryType.travel)
        .fold<int>(0, (sum, entry) => sum + entry.travelDuration.inMinutes);

    final openingEvent = BalanceOffsetEvent.opening(
      effectiveDate: openingConfig.trackingStartDate,
      minutes: openingConfig.openingFlexMinutes,
    );

    final adjustmentEventsBeforeStart = adjustmentsOnOrBeforeStart
        .map(
          (adj) => BalanceOffsetEvent.adjustment(
            effectiveDate: adj.effectiveDate,
            minutes: adj.deltaMinutes,
            note: adj.note,
          ),
        )
        .toList();
    final adjustmentEventsInRange = adjustmentsAfterStartInRange
        .map(
          (adj) => BalanceOffsetEvent.adjustment(
            effectiveDate: adj.effectiveDate,
            minutes: adj.deltaMinutes,
            note: adj.note,
          ),
        )
        .toList();

    final openingOnOrBeforeStart =
        _isOnOrBefore(openingEvent.effectiveDate, startDate);
    final openingInRange = _isAfter(openingEvent.effectiveDate, startDate) &&
        _isOnOrBefore(openingEvent.effectiveDate, endDate);

    final eventsBeforeStart = <BalanceOffsetEvent>[
      if (openingOnOrBeforeStart) openingEvent,
      ...adjustmentEventsBeforeStart,
    ]..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    final eventsInRange = <BalanceOffsetEvent>[
      if (openingInRange) openingEvent,
      ...adjustmentEventsInRange,
    ]..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    final startingBalanceMinutes = eventsBeforeStart.fold<int>(
      0,
      (sum, event) => sum + event.minutes,
    );
    final closingBalanceMinutes = startingBalanceMinutes +
        eventsInRange.fold<int>(0, (sum, event) => sum + event.minutes);

    return ReportSummary(
      filteredEntries: sortedEntries,
      workMinutes: workMinutes,
      travelMinutes: travelMinutes,
      totalTrackedMinutes: workMinutes + travelMinutes,
      workInsights: _buildWorkInsights(sortedEntries),
      travelInsights: _buildTravelInsights(sortedEntries),
      leavesSummary: _buildLeavesSummary(absences),
      balanceOffsets: BalanceOffsetSummary(
        openingEvent:
            openingEvent.effectiveDate.isAfter(endDate) ? null : openingEvent,
        adjustmentsInRange: adjustmentEventsInRange,
        eventsBeforeStart: eventsBeforeStart,
        eventsInRange: eventsInRange,
        startingBalanceMinutes: startingBalanceMinutes,
        closingBalanceMinutes: closingBalanceMinutes,
      ),
    );
  }

  WorkInsights _buildWorkInsights(List<Entry> entries) {
    final workEntries = entries.where((entry) => entry.type == EntryType.work);
    final workedByDay = <DateTime, int>{};

    LongestShiftInsight? longestShift;
    var shiftCount = 0;
    var totalBreakMinutes = 0;

    for (final entry in workEntries) {
      final entryDate = _dateOnly(entry.date);
      workedByDay[entryDate] =
          (workedByDay[entryDate] ?? 0) + entry.workDuration.inMinutes;

      final shifts = entry.shifts ?? const [];
      for (final shift in shifts) {
        shiftCount += 1;
        totalBreakMinutes += shift.unpaidBreakMinutes;

        final workedMinutes = shift.workedMinutes;
        final spanMinutes = shift.duration.inMinutes;

        if (longestShift == null ||
            workedMinutes > longestShift.workedMinutes) {
          longestShift = LongestShiftInsight(
            date: entryDate,
            spanMinutes: spanMinutes,
            workedMinutes: workedMinutes,
            breakMinutes: shift.unpaidBreakMinutes,
            location: shift.location,
            notes: shift.notes,
            entry: entry,
          );
        }
      }
    }

    final totalWorkedMinutes =
        workedByDay.values.fold<int>(0, (sum, minutes) => sum + minutes);
    final activeWorkDays = workedByDay.length;

    return WorkInsights(
      longestShift: longestShift,
      averageWorkedMinutesPerDay:
          activeWorkDays == 0 ? 0 : totalWorkedMinutes / activeWorkDays,
      totalBreakMinutes: totalBreakMinutes,
      averageBreakMinutesPerShift:
          shiftCount == 0 ? 0 : totalBreakMinutes / shiftCount,
      shiftCount: shiftCount,
      activeWorkDays: activeWorkDays,
    );
  }

  TravelInsights _buildTravelInsights(List<Entry> entries) {
    final travelEntries =
        entries.where((entry) => entry.type == EntryType.travel).toList();

    final routeMinutes = <String, int>{};
    final routeTrips = <String, int>{};
    final routeEndpoints = <String, ({String from, String to})>{};
    var tripCount = 0;
    var totalTravelMinutes = 0;

    for (final entry in travelEntries) {
      final legs = entry.travelLegs;

      if (legs != null && legs.isNotEmpty) {
        for (final leg in legs) {
          final from = leg.fromText.trim();
          final to = leg.toText.trim();
          final key = _normalizedRouteKey(from, to);
          routeEndpoints.putIfAbsent(key, () => (from: from, to: to));
          routeTrips[key] = (routeTrips[key] ?? 0) + 1;
          routeMinutes[key] = (routeMinutes[key] ?? 0) + leg.minutes;
          tripCount += 1;
          totalTravelMinutes += leg.minutes;
        }
      } else {
        final from = (entry.from ?? '').trim();
        final to = (entry.to ?? '').trim();
        final key = _normalizedRouteKey(from, to);
        routeEndpoints.putIfAbsent(key, () => (from: from, to: to));
        routeTrips[key] = (routeTrips[key] ?? 0) + 1;
        final minutes = entry.travelDuration.inMinutes;
        routeMinutes[key] = (routeMinutes[key] ?? 0) + minutes;
        tripCount += 1;
        totalTravelMinutes += minutes;
      }
    }

    final topRoutes = routeMinutes.entries
        .map((entry) {
          final endpoints = routeEndpoints[entry.key];
          if (endpoints == null) return null;
          return RouteSummary(
            from: endpoints.from,
            to: endpoints.to,
            routeKey: '${endpoints.from}→${endpoints.to}',
            tripCount: routeTrips[entry.key] ?? 0,
            totalMinutes: entry.value,
          );
        })
        .whereType<RouteSummary>()
        .toList()
      ..sort((a, b) {
        final byMinutes = b.totalMinutes.compareTo(a.totalMinutes);
        if (byMinutes != 0) return byMinutes;
        return b.tripCount.compareTo(a.tripCount);
      });

    return TravelInsights(
      tripCount: tripCount,
      averageMinutesPerTrip:
          tripCount == 0 ? 0 : totalTravelMinutes / tripCount,
      topRoutes: topRoutes,
    );
  }

  String _normalizedRouteKey(String from, String to) {
    final normalizedFrom = from.trim().toLowerCase();
    final normalizedTo = to.trim().toLowerCase();
    return '$normalizedFrom->$normalizedTo';
  }

  LeavesSummary _buildLeavesSummary(List<AbsenceEntry> absences) {
    final sortedAbsences = List<AbsenceEntry>.from(absences)
      ..sort((a, b) => a.date.compareTo(b.date));

    final byType = <AbsenceType, LeaveTypeSummary>{};
    for (final type in AbsenceType.values) {
      byType[type] = const LeaveTypeSummary(
        entryCount: 0,
        fullDayCount: 0,
        totalMinutes: 0,
        totalDays: 0,
      );
    }

    var totalMinutes = 0;
    var totalDays = 0.0;

    for (final absence in sortedAbsences) {
      final isFullDay = absence.minutes == 0;
      final minutes = normalizedLeaveMinutes(absence);
      final days = isFullDay ? 1.0 : minutes / kDefaultFullLeaveDayMinutes;

      totalMinutes += minutes;
      totalDays += days;

      final current = byType[absence.type]!;
      byType[absence.type] = LeaveTypeSummary(
        entryCount: current.entryCount + 1,
        fullDayCount: current.fullDayCount + (isFullDay ? 1 : 0),
        totalMinutes: current.totalMinutes + minutes,
        totalDays: current.totalDays + days,
      );
    }

    return LeavesSummary(
      absences: sortedAbsences,
      byType: byType,
      totalEntries: sortedAbsences.length,
      totalMinutes: totalMinutes,
      totalDays: totalDays,
    );
  }
}
