import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/absence.dart';
import '../models/balance_adjustment.dart';
import '../models/entry.dart';
import '../models/user_profile.dart';
import '../repositories/balance_adjustment_repository.dart';
import '../services/profile_service.dart';
import '../services/supabase_absence_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_entry_service.dart';
import '../utils/entry_filter.dart';
import '../utils/entry_filter_spec.dart';

typedef CurrentUserIdGetter = String? Function();
typedef EntriesInRangeFetcher = Future<List<Entry>> Function(
  String userId,
  DateTime start,
  DateTime end,
);
typedef AbsencesForYearFetcher = Future<List<AbsenceEntry>> Function(
  String userId,
  int year,
);
typedef ProfileFetcher = Future<UserProfile?> Function();
typedef AdjustmentsFetcher = Future<List<BalanceAdjustment>> Function(
  String userId,
);

class ReportQuerySpec {
  final DateTime start;
  final DateTime end;
  final EntryType? selectedType;

  const ReportQuerySpec({
    required this.start,
    required this.end,
    this.selectedType,
  });
}

class ProfileTrackingInfo {
  final DateTime trackingStartDate;
  final int openingFlexMinutes;

  const ProfileTrackingInfo({
    required this.trackingStartDate,
    required this.openingFlexMinutes,
  });
}

class ReportQueryData {
  final List<Entry> entriesInRange;
  final List<AbsenceEntry> leavesInRange;
  final ProfileTrackingInfo profileTrackingInfo;
  final List<BalanceAdjustment> adjustmentsUpToEnd;
  final List<BalanceAdjustment> adjustmentsInRange;

  const ReportQueryData({
    required this.entriesInRange,
    required this.leavesInRange,
    required this.profileTrackingInfo,
    required this.adjustmentsUpToEnd,
    required this.adjustmentsInRange,
  });
}

/// Opening balance/tracking configuration used by reports.
class OpeningBalanceConfig {
  final DateTime trackingStartDate;
  final int openingFlexMinutes;

  const OpeningBalanceConfig({
    required this.trackingStartDate,
    required this.openingFlexMinutes,
  });
}

/// Query service for reports.
///
/// Notes:
/// - Loads entries directly from Supabase in requested range.
/// - Does not mutate Entry/Absence/Contract provider state.
/// - Uses shared EntryFilter for post-load type filtering.
class ReportQueryService {
  final SupabaseAuthService? _authService;
  final SupabaseEntryService? _entryService;
  final SupabaseAbsenceService? _absenceService;
  final BalanceAdjustmentRepository? _adjustmentRepository;
  final ProfileService? _profileService;

  final CurrentUserIdGetter? _currentUserIdGetter;
  final EntriesInRangeFetcher? _entriesInRangeFetcher;
  final AbsencesForYearFetcher? _absencesForYearFetcher;
  final ProfileFetcher? _profileFetcher;
  final AdjustmentsFetcher? _adjustmentsFetcher;

  ReportQueryService({
    SupabaseAuthService? authService,
    SupabaseEntryService? entryService,
    SupabaseAbsenceService? absenceService,
    BalanceAdjustmentRepository? adjustmentRepository,
    ProfileService? profileService,
    CurrentUserIdGetter? currentUserIdGetter,
    EntriesInRangeFetcher? entriesInRangeFetcher,
    AbsencesForYearFetcher? absencesForYearFetcher,
    ProfileFetcher? profileFetcher,
    AdjustmentsFetcher? adjustmentsFetcher,
  })  : _authService = authService,
        _entryService = entryService,
        _absenceService = absenceService,
        _adjustmentRepository = adjustmentRepository,
        _profileService = profileService,
        _currentUserIdGetter = currentUserIdGetter,
        _entriesInRangeFetcher = entriesInRangeFetcher,
        _absencesForYearFetcher = absencesForYearFetcher,
        _profileFetcher = profileFetcher,
        _adjustmentsFetcher = adjustmentsFetcher;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  String? _currentUserId() {
    return _currentUserIdGetter?.call() ?? _authService?.currentUser?.id;
  }

  Future<List<Entry>> _fetchEntriesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    final fetcher = _entriesInRangeFetcher;
    if (fetcher != null) {
      return fetcher(userId, start, end);
    }
    final service = _entryService ?? SupabaseEntryService();
    return service.getEntriesInRange(userId, start, end);
  }

  Future<List<AbsenceEntry>> _fetchAbsencesForYear(String userId, int year) {
    final fetcher = _absencesForYearFetcher;
    if (fetcher != null) {
      return fetcher(userId, year);
    }
    final service = _absenceService ?? SupabaseAbsenceService();
    return service.fetchAbsencesForYear(userId, year);
  }

  Future<UserProfile?> _fetchProfile() {
    final fetcher = _profileFetcher;
    if (fetcher != null) {
      return fetcher();
    }
    final service = _profileService ?? ProfileService();
    return service.fetchProfile();
  }

  Future<List<BalanceAdjustment>> _fetchAllAdjustments(String userId) {
    final fetcher = _adjustmentsFetcher;
    if (fetcher != null) {
      return fetcher(userId);
    }
    final repository = _adjustmentRepository ??
        BalanceAdjustmentRepository(SupabaseConfig.client);
    return repository.listAllAdjustments(userId: userId);
  }

  List<BalanceAdjustment> _filterAdjustmentsUpToEnd(
    List<BalanceAdjustment> adjustments,
    DateTime end,
  ) {
    final endDate = _dateOnly(end);
    final filtered = adjustments.where((adjustment) {
      final date = _dateOnly(adjustment.effectiveDate);
      return !date.isAfter(endDate);
    }).toList();

    filtered.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return filtered;
  }

  List<BalanceAdjustment> adjustmentsInRange({
    required List<BalanceAdjustment> adjustments,
    required DateTime start,
    required DateTime end,
  }) {
    final startDate = _dateOnly(start);
    final endDate = _dateOnly(end);

    final filtered = adjustments.where((adjustment) {
      final date = _dateOnly(adjustment.effectiveDate);
      // "In period" excludes events effective on start date because those
      // belong to "balance at period start".
      return date.isAfter(startDate) && !date.isAfter(endDate);
    }).toList();

    filtered.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return filtered;
  }

  Future<List<AbsenceEntry>> _loadLeavesInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startDate = _dateOnly(start);
      final endDate = _dateOnly(end);

      final result = <AbsenceEntry>[];
      for (var year = startDate.year; year <= endDate.year; year++) {
        final yearLeaves = await _fetchAbsencesForYear(userId, year);
        for (final leave in yearLeaves) {
          final leaveDate = _dateOnly(leave.date);
          if (!leaveDate.isBefore(startDate) && !leaveDate.isAfter(endDate)) {
            result.add(leave);
          }
        }
      }

      result.sort((a, b) => a.date.compareTo(b.date));
      return result;
    } catch (e) {
      // If leaves are not available in this deployment/schema, treat as empty.
      debugPrint('ReportQueryService: Leaves unavailable for reports: $e');
      return const [];
    }
  }

  Future<ProfileTrackingInfo> _loadProfileTrackingInfo({
    required DateTime fallbackStart,
  }) async {
    final profile = await _fetchProfile();
    final fallbackTrackingStart = DateTime(fallbackStart.year, 1, 1);

    return ProfileTrackingInfo(
      trackingStartDate:
          _dateOnly(profile?.trackingStartDate ?? fallbackTrackingStart),
      openingFlexMinutes: profile?.openingFlexMinutes ?? 0,
    );
  }

  Future<ReportQueryData> getReportData(ReportQuerySpec spec) async {
    final startDate = _dateOnly(spec.start);
    final endDate = _dateOnly(spec.end);
    if (endDate.isBefore(startDate)) {
      throw ArgumentError.value(
        spec.end,
        'spec.end',
        'End date must be on or after start date.',
      );
    }

    final userId = _currentUserId();
    final profileTrackingInfo = await _loadProfileTrackingInfo(
      fallbackStart: startDate,
    );

    if (userId == null) {
      return ReportQueryData(
        entriesInRange: const [],
        leavesInRange: const [],
        profileTrackingInfo: profileTrackingInfo,
        adjustmentsUpToEnd: const [],
        adjustmentsInRange: const [],
      );
    }

    final loadedEntries =
        await _fetchEntriesInRange(userId, startDate, endDate);
    final entryFilterSpec = EntryFilterSpec(
      startDate: startDate,
      endDate: _endOfDay(endDate),
      selectedType: spec.selectedType,
    );
    final entriesInRange =
        EntryFilter.filterEntries(loadedEntries, entryFilterSpec);

    final leavesInRange = await _loadLeavesInRange(
      userId: userId,
      start: startDate,
      end: endDate,
    );

    final allAdjustments = await _fetchAllAdjustments(userId);
    final adjustmentsUpToEnd =
        _filterAdjustmentsUpToEnd(allAdjustments, endDate);
    final adjustmentsInRange = this.adjustmentsInRange(
      adjustments: adjustmentsUpToEnd,
      start: startDate,
      end: endDate,
    );

    return ReportQueryData(
      entriesInRange: entriesInRange,
      leavesInRange: leavesInRange,
      profileTrackingInfo: profileTrackingInfo,
      adjustmentsUpToEnd: adjustmentsUpToEnd,
      adjustmentsInRange: adjustmentsInRange,
    );
  }

  /// Backward-compatible helper used by existing aggregator code.
  Future<List<Entry>> getEntries(
    DateTime start,
    DateTime end,
    EntryType? selectedType,
  ) async {
    final data = await getReportData(
      ReportQuerySpec(start: start, end: end, selectedType: selectedType),
    );
    return data.entriesInRange;
  }

  /// Backward-compatible helper used by existing aggregator code.
  Future<List<AbsenceEntry>> getAbsences(
    DateTime start,
    DateTime end,
  ) async {
    final data = await getReportData(
      ReportQuerySpec(start: start, end: end),
    );
    return data.leavesInRange;
  }

  /// Backward-compatible helper used by existing aggregator code.
  Future<OpeningBalanceConfig> getOpeningBalanceConfig() async {
    final info = await _loadProfileTrackingInfo(
      fallbackStart: DateTime(DateTime.now().year, 1, 1),
    );
    return OpeningBalanceConfig(
      trackingStartDate: info.trackingStartDate,
      openingFlexMinutes: info.openingFlexMinutes,
    );
  }

  /// Backward-compatible helper used by existing aggregator code.
  Future<List<BalanceAdjustment>> getAdjustments(
    DateTime start,
    DateTime end,
  ) async {
    final data = await getReportData(
      ReportQuerySpec(start: start, end: end),
    );
    return data.adjustmentsInRange;
  }

  /// Backward-compatible helper used by existing aggregator code.
  Future<List<BalanceAdjustment>> getAdjustmentsBeforeRangeStart({
    required DateTime trackingStartDate,
    required DateTime rangeStart,
  }) async {
    final userId = _currentUserId();
    if (userId == null) return [];

    final endDate = _dateOnly(rangeStart).subtract(const Duration(days: 1));
    final startDate = _dateOnly(trackingStartDate);
    if (endDate.isBefore(startDate)) {
      return [];
    }

    final allAdjustments = await _fetchAllAdjustments(userId);
    final upToEnd = _filterAdjustmentsUpToEnd(allAdjustments, endDate);
    return upToEnd.where((adjustment) {
      final date = _dateOnly(adjustment.effectiveDate);
      return !date.isBefore(startDate);
    }).toList();
  }
}
