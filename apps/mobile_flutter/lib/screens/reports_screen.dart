// ignore_for_file: deprecated_member_use
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../viewmodels/customer_analytics_viewmodel.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/export_dialog.dart';
import '../widgets/export_share_dialog.dart';
import '../services/export_service.dart';
import '../models/entry.dart';
import '../services/supabase_auth_service.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/contract_provider.dart';
import '../reporting/time_range.dart';
import 'reports/overview_tab.dart';
import 'reports/trends_tab.dart';
import 'reports/time_balance_tab.dart';
import 'reports/leaves_tab.dart';
import '../l10n/generated/app_localizations.dart';

enum ReportsPeriodPreset {
  today,
  thisWeek,
  last7Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

class OverviewTrackingRangeText extends StatelessWidget {
  const OverviewTrackingRangeText({
    super.key,
    required this.reportStart,
    required this.reportEnd,
    required this.trackingStartDate,
  });

  final DateTime reportStart;
  final DateTime reportEnd;
  final DateTime trackingStartDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final reportStartOnly = DateTime(
      reportStart.year,
      reportStart.month,
      reportStart.day,
    );
    final reportEndOnly = DateTime(
      reportEnd.year,
      reportEnd.month,
      reportEnd.day,
    );
    final trackingStartOnly = DateTime(
      trackingStartDate.year,
      trackingStartDate.month,
      trackingStartDate.day,
    );
    final effectiveStart = reportStartOnly.isBefore(trackingStartOnly)
        ? trackingStartOnly
        : reportStartOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report period: ${dateFormat.format(reportStartOnly)} → ${dateFormat.format(reportEndOnly)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Calculated from: ${dateFormat.format(effectiveStart)} → ${dateFormat.format(reportEndOnly)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportsPeriodPreset _selectedPeriod = ReportsPeriodPreset.thisMonth;
  DateTimeRange? _customRange;
  ReportSegment _selectedSegment = ReportSegment.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  EntryType? _entryTypeForSegment(ReportSegment segment) {
    switch (segment) {
      case ReportSegment.all:
      case ReportSegment.leave:
        return null;
      case ReportSegment.work:
        return EntryType.work;
      case ReportSegment.travel:
        return EntryType.travel;
    }
  }

  DateTimeRange _currentRange() {
    final now = DateTime.now();
    final today = _dateOnly(now);

    switch (_selectedPeriod) {
      case ReportsPeriodPreset.today:
        return DateTimeRange(start: today, end: today);
      case ReportsPeriodPreset.thisWeek:
        final daysSinceMonday = today.weekday - DateTime.monday;
        final start = today.subtract(Duration(days: daysSinceMonday));
        return DateTimeRange(start: start, end: today);
      case ReportsPeriodPreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case ReportsPeriodPreset.thisMonth:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: today);
      case ReportsPeriodPreset.lastMonth:
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
        final lastMonthStart =
            DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
        return DateTimeRange(
            start: lastMonthStart, end: _dateOnly(lastMonthEnd));
      case ReportsPeriodPreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case ReportsPeriodPreset.custom:
        return _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
    }
  }

  String _periodLabel(AppLocalizations t, ReportsPeriodPreset preset) {
    switch (preset) {
      case ReportsPeriodPreset.today:
        return t.reportsCustom_periodToday;
      case ReportsPeriodPreset.thisWeek:
        return t.reportsCustom_periodThisWeek;
      case ReportsPeriodPreset.last7Days:
        return t.reportsCustom_periodLast7Days;
      case ReportsPeriodPreset.thisMonth:
        return t.reportsCustom_periodThisMonth;
      case ReportsPeriodPreset.lastMonth:
        return t.reportsCustom_periodLastMonth;
      case ReportsPeriodPreset.thisYear:
        return t.reportsCustom_periodThisYear;
      case ReportsPeriodPreset.custom:
        return t.reportsCustom_periodCustom;
    }
  }

  Future<void> _onPeriodSelected(ReportsPeriodPreset preset) async {
    if (preset == ReportsPeriodPreset.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5, 1, 1),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: _customRange ?? _currentRange(),
      );

      if (!mounted || picked == null) return;
      setState(() {
        _selectedPeriod = ReportsPeriodPreset.custom;
        _customRange = DateTimeRange(
          start: _dateOnly(picked.start),
          end: _dateOnly(picked.end),
        );
      });
      return;
    }

    setState(() {
      _selectedPeriod = preset;
    });
  }

  Widget _buildPeriodBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final contractProvider = context.watch<ContractProvider>();
    final range = _currentRange();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final rangeText =
        '${dateFormat.format(range.start)} → ${dateFormat.format(range.end)}';

    final presets = <ReportsPeriodPreset>[
      ReportsPeriodPreset.today,
      ReportsPeriodPreset.thisWeek,
      ReportsPeriodPreset.last7Days,
      ReportsPeriodPreset.thisMonth,
      ReportsPeriodPreset.lastMonth,
      ReportsPeriodPreset.thisYear,
      ReportsPeriodPreset.custom,
    ];

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((preset) {
                final isSelected = _selectedPeriod == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_periodLabel(t, preset)),
                    selected: isSelected,
                    onSelected: (_) => _onPeriodSelected(preset),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rangeText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          OverviewTrackingRangeText(
            reportStart: range.start,
            reportEnd: range.end,
            trackingStartDate: contractProvider.trackingStartDate,
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    // Show loading indicator while fetching entries
    if (!mounted) return;

    final t = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get all entries from repositories
      final entries = await _getAllEntries();

      // Close loading indicator
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (entries.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.export_noData)),
        );
        return;
      }

      if (!mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => ExportDialog(
          entries: entries,
          initialStartDate: null,
          initialEndDate: null,
        ),
      );

      if (result != null && mounted) {
        await _performExport(result);
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_loadingEntries(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<List<Entry>> _getAllEntries() async {
    try {
      final entryProvider = context.read<EntryProvider>();
      final authService = context.read<SupabaseAuthService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        return [];
      }

      // Ensure entries are loaded
      if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
        await entryProvider.loadEntries();
      }

      // Get all entries from EntryProvider (already in unified Entry format)
      final allEntries = List<Entry>.from(entryProvider.entries);

      // Sort by date (most recent first)
      allEntries.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        // If same date, sort by updatedAt or createdAt
        final aTime = a.updatedAt ?? a.createdAt;
        final bTime = b.updatedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return allEntries;
    } catch (e) {
      debugPrint('Error getting entries for export: $e');
      return [];
    }
  }

  Future<void> _performExport(Map<String, dynamic> exportConfig) async {
    if (!mounted) return;

    final t = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      final entries = exportConfig['entries'] as List<Entry>;
      final fileName = exportConfig['fileName'] as String;
      final format = exportConfig['format'] as String? ?? 'excel';

      // Validate entries
      if (entries.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.export_noEntries),
            backgroundColor: AppColors.accent,
          ),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppSpacing.lg),
              Flexible(child: Text(t.export_generating(format.toUpperCase()))),
            ],
          ),
        ),
      );

      // Generate file based on format
      String filePath;
      try {
        if (format == 'excel') {
          filePath = await ExportService.exportEntriesToExcel(
            entries: entries,
            fileName: fileName,
          );
        } else {
          filePath = await ExportService.exportEntriesToCSV(
            entries: entries,
            fileName: fileName,
          );
        }
      } catch (e) {
        // Close loading dialog
        if (navigator.canPop()) navigator.pop();
        rethrow;
      }

      // Close loading dialog
      if (navigator.canPop()) navigator.pop();

      // On mobile/desktop, show share options dialog
      if (!kIsWeb && filePath.isNotEmpty && mounted) {
        await showExportShareDialog(
          context,
          filePath: filePath,
          fileName: fileName,
          format: format,
        );
      } else if (mounted) {
        // Web: just show download success
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.export_downloadedSuccess(format.toUpperCase())),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(t.export_failed(e.toString())),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ChangeNotifierProxyProvider<EntryProvider,
        CustomerAnalyticsViewModel>(
      create: (context) => CustomerAnalyticsViewModel(),
      update: (context, entryProvider, viewModel) {
        final authService = context.read<SupabaseAuthService>();
        final settingsProvider = context.read<SettingsProvider>();
        final userId = authService.currentUser?.id;

        // Ensure entries are loaded
        if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
          entryProvider.loadEntries();
        }

        final model = viewModel ?? CustomerAnalyticsViewModel();
        final range = _currentRange();
        model.setDateRange(range.start, range.end);
        model.setTravelEnabled(settingsProvider.isTravelLoggingEnabled);
        model.setTrendsEntryTypeFilter(_entryTypeForSegment(_selectedSegment));
        model.bindEntries(
          entryProvider.entries,
          userId: userId,
          isLoading: entryProvider.isLoading,
          errorMessage: entryProvider.error,
        );
        return model;
      },
      builder: (context, child) {
        final viewModel = context.watch<CustomerAnalyticsViewModel>();
        final currentRange = _currentRange();
        final trendsRange =
            TimeRange.custom(currentRange.start, currentRange.end);

        return Scaffold(
          appBar: StandardAppBar(
            title: t.reports_title,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.file_download_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: t.reports_exportData,
                onPressed: () => _showExportDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (viewModel.usingServer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          t.reports_serverAnalytics,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      if (viewModel.lastServerError != null)
                        Tooltip(
                          message: viewModel.lastServerError,
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              // Tab Bar
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  onTap: (_) => HapticFeedback.lightImpact(),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: t.reports_overview),
                    Tab(text: t.reports_trends),
                    Tab(text: t.reports_timeBalance),
                    Tab(text: t.reports_leaves),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                        _buildPeriodBar(context),
                        Expanded(
                          child: OverviewTab(
                            range: currentRange,
                            segment: _selectedSegment,
                            onSegmentChanged: (segment) {
                              setState(() {
                                _selectedSegment = segment;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    TrendsTab(range: trendsRange),
                    TimeBalanceTab(),
                    LeavesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
