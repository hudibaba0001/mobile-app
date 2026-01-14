import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/customer_analytics_viewmodel.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/export_dialog.dart';
import '../services/export_service.dart';
import '../models/entry.dart';
import '../models/travel_entry.dart';
import '../services/supabase_auth_service.dart';
import '../repositories/repository_provider.dart';
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
    
    final t = AppLocalizations.of(context)!;
    
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
      final repositoryProvider = context.read<RepositoryProvider>();
      final authService = context.read<SupabaseAuthService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        return [];
      }

      // Get travel entries
      List<TravelEntry> travelEntries = [];
      List<WorkEntry> workEntries = [];

      final travelRepo = repositoryProvider.travelRepository;
      final workRepo = repositoryProvider.workRepository;

      if (travelRepo != null) {
        travelEntries = travelRepo.getAllForUser(userId);
      }
      if (workRepo != null) {
        workEntries = workRepo.getAllForUser(userId);
      }

      // Convert to unified Entry objects
      final allEntries = <Entry>[];

      // Convert travel entries
      for (final travelEntry in travelEntries) {
        allEntries.add(Entry(
          id: travelEntry.id,
          userId: travelEntry.userId,
          type: EntryType.travel,
          from: travelEntry.fromLocation,
          to: travelEntry.toLocation,
          travelMinutes: travelEntry.travelMinutes,
          date: travelEntry.date,
          notes: travelEntry.remarks,
          createdAt: travelEntry.createdAt,
          updatedAt: travelEntry.updatedAt,
        ));
      }

      // Convert work entries
      for (final workEntry in workEntries) {
        // Convert workMinutes to a Shift object
        final List<Shift> shifts = workEntry.workMinutes > 0
            ? [
                Shift(
                  start: workEntry.date,
                  end: workEntry.date
                      .add(Duration(minutes: workEntry.workMinutes)),
                  description: workEntry.remarks.isNotEmpty
                      ? workEntry.remarks
                      : 'Work Session',
                  location: 'Work Location', // Default location
                ),
              ]
            : [];

        allEntries.add(Entry(
          id: workEntry.id,
          userId: workEntry.userId,
          type: EntryType.work,
          shifts: shifts,
          date: workEntry.date,
          notes: workEntry.remarks,
          createdAt: workEntry.createdAt,
          updatedAt: workEntry.updatedAt,
        ));
      }

      // Sort by date (most recent first)
      allEntries.sort((a, b) => b.date.compareTo(a.date));

      return allEntries;
    } catch (e) {
      debugPrint('Error getting entries for export: $e');
      return [];
    }
  }

  Future<void> _performExport(Map<String, dynamic> exportConfig) async {
    if (!mounted) return;
    
    final t = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    
    try {
      final entries = exportConfig['entries'] as List<Entry>;
      final fileName = exportConfig['fileName'] as String;
      final startDate = exportConfig['startDate'] as DateTime?;
      final endDate = exportConfig['endDate'] as DateTime?;
      final format = exportConfig['format'] as String? ?? 'excel';

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
            startDate: startDate,
            endDate: endDate,
          );
        } else {
          filePath = await ExportService.exportEntriesToCSV(
            entries: entries,
            fileName: fileName,
            startDate: startDate,
            endDate: endDate,
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
    final t = AppLocalizations.of(context)!;
    
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
    final t = AppLocalizations.of(context)!;
    
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = CustomerAnalyticsViewModel();
        final repositoryProvider = context.read<RepositoryProvider>();
        final authService = context.read<SupabaseAuthService>();
        final userId = authService.currentUser?.id;
        viewModel.initialize(
          repositoryProvider.workRepository,
          repositoryProvider.travelRepository,
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
