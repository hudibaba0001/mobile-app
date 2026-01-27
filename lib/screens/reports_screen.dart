import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/customer_analytics_viewmodel.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/export_dialog.dart';
import '../services/export_service.dart';
import '../models/entry.dart';
import '../services/supabase_auth_service.dart';
import '../providers/entry_provider.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import 'reports/overview_tab.dart';
import 'reports/trends_tab.dart';
import 'reports/time_balance_tab.dart';
import 'reports/leaves_tab.dart';
import '../l10n/generated/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
            backgroundColor: Colors.red,
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
      final entryTypeFilter = exportConfig['entryTypeFilter'] as String? ?? 'both';

      // Validate entries
      if (entries.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.export_noEntries),
            backgroundColor: Colors.orange,
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
              const SizedBox(width: 16),
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
            entryTypeFilter: entryTypeFilter,
          );
        } else {
          filePath = await ExportService.exportEntriesToCSV(
            entries: entries,
            fileName: fileName,
            entryTypeFilter: entryTypeFilter,
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
        await _showShareOptionsDialog(context, filePath, fileName, format);
      } else if (mounted) {
        // Web: just show download success
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.export_downloadedSuccess(format.toUpperCase())),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(t.export_failed(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showShareOptionsDialog(
    BuildContext context,
    String filePath,
    String fileName,
    String format,
  ) async {
    if (!mounted) return;

    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(t.export_complete)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.export_savedSuccess(format.toUpperCase()),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              t.export_sharePrompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_done),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await Share.shareXFiles(
                  [XFile(filePath)],
                  subject: t.export_shareSubject(fileName),
                  text: t.export_shareText,
                );
              } catch (e) {
                debugPrint('Share error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.error_shareFile(e.toString())),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
            label: Text(t.common_share),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = CustomerAnalyticsViewModel();
        final entryProvider = context.read<EntryProvider>();
        final authService = context.read<SupabaseAuthService>();
        final userId = authService.currentUser?.id;
        
        // Ensure entries are loaded
        if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
          entryProvider.loadEntries();
        }
        
        // Convert Entry objects to legacy WorkEntry/TravelEntry for viewmodel compatibility
        // TODO: Refactor CustomerAnalyticsViewModel to use Entry model directly
        final workEntries = entryProvider.entries
            .where((e) => e.type == EntryType.work)
            .map((entry) {
              final shift = entry.atomicShift ?? entry.shifts?.first;
              final workMinutes = entry.totalWorkDuration?.inMinutes ?? 0;
              return WorkEntry(
                id: entry.id,
                userId: entry.userId,
                date: entry.date,
                workMinutes: workMinutes,
                remarks: entry.notes ?? shift?.notes ?? shift?.description ?? '',
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt,
              );
            })
            .toList();
        
        final travelEntries = entryProvider.entries
            .where((e) => e.type == EntryType.travel)
            .map((entry) {
              return TravelEntry(
                id: entry.id,
                userId: entry.userId,
                date: entry.date,
                fromLocation: entry.from ?? '',
                toLocation: entry.to ?? '',
                travelMinutes: entry.travelMinutes ?? 0,
                remarks: entry.notes ?? '',
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt,
              );
            })
            .toList();
        
        // Create mock repositories that return the converted entries
        // This is a temporary solution until CustomerAnalyticsViewModel is refactored
        final mockWorkRepo = _MockWorkRepository(workEntries);
        final mockTravelRepo = _MockTravelRepository(travelEntries);
        
        viewModel.initialize(
          mockWorkRepo,
          mockTravelRepo,
          userId: userId,
        );
        return viewModel;
      },
      builder: (context, child) {
        final viewModel = context.watch<CustomerAnalyticsViewModel>();

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
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
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  children: const [
                    OverviewTab(),
                    TrendsTab(),
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

// Temporary mock repositories to convert EntryProvider data for CustomerAnalyticsViewModel
// TODO: Refactor CustomerAnalyticsViewModel to use Entry model directly
// Note: These are read-only wrappers that convert Entry objects to legacy models
class _MockWorkRepository {
  final List<WorkEntry> _entries;
  
  _MockWorkRepository(this._entries);
  
  List<WorkEntry> getAllForUser(String userId) {
    return _entries.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  List<WorkEntry> getForUserInRange(String userId, DateTime start, DateTime end) {
    return _entries.where((e) =>
        e.userId == userId &&
        e.date.isAfter(start.subtract(const Duration(days: 1))) &&
        e.date.isBefore(end.add(const Duration(days: 1))))
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  WorkEntry? getById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
  
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.workMinutes);
  }
}

class _MockTravelRepository {
  final List<TravelEntry> _entries;
  
  _MockTravelRepository(this._entries);
  
  List<TravelEntry> getAllForUser(String userId) {
    return _entries.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  List<TravelEntry> getForUserInRange(String userId, DateTime start, DateTime end) {
    return _entries.where((e) =>
        e.userId == userId &&
        e.date.isAfter(start.subtract(const Duration(days: 1))) &&
        e.date.isBefore(end.add(const Duration(days: 1))))
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  TravelEntry? getById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
  
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.travelMinutes);
  }
}
