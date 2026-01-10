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
import 'reports/date_range_dialog.dart';
import 'reports/overview_tab.dart';
import 'reports/trends_tab.dart';
import 'reports/time_balance_tab.dart';
import '../config/app_router.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog(BuildContext context) async {
    // Get all entries from repositories
    final entries = await _getAllEntries();

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available for export')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExportDialog(
        entries: entries,
        initialStartDate: null, // Will be set by user in dialog
        initialEndDate: null, // Will be set by user in dialog
      ),
    );

    if (result != null) {
      await _performExport(result);
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

  Future<void> _showDateRangeDialog(
      BuildContext context, CustomerAnalyticsViewModel viewModel) async {
    final initialStartDate = viewModel.startDate ??
        DateTime.now().subtract(const Duration(days: 30));
    final initialEndDate = viewModel.endDate ?? DateTime.now();

    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (context) => DateRangeDialog(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );

    if (result != null) {
      viewModel.setDateRange(result.$1, result.$2);
    }
  }

  Future<void> _performExport(Map<String, dynamic> exportConfig) async {
    try {
      final entries = exportConfig['entries'] as List<Entry>;
      final fileName = exportConfig['fileName'] as String;
      final startDate = exportConfig['startDate'] as DateTime?;
      final endDate = exportConfig['endDate'] as DateTime?;
      final format = exportConfig['format'] as String? ?? 'excel';

      // Validate entries
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No entries to export. Please select entries with data.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Generating ${format.toUpperCase()} export...'),
            ],
          ),
        ),
      );

      // Generate file based on format
      String filePath;
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

      // Close loading dialog
      Navigator.of(context).pop();

      // Share the file (only on mobile/desktop, web already downloaded)
      if (!kIsWeb && filePath.isNotEmpty) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Time Tracker Export - $fileName',
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? '${format.toUpperCase()} file downloaded successfully!'
                : '${format.toUpperCase()} export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'Reports & Analytics',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Filter by Date',
                onPressed: () => _showDateRangeDialog(context, viewModel),
              ),
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Export Data',
                onPressed: () => _showExportDialog(context),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Refresh Data',
                onPressed: () {
                  viewModel.refreshData();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Time Balance',
                onPressed: () {
                  AppRouter.goToTimeBalance(context);
                },
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
                          'Server analytics',
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
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Trends'),
                    Tab(text: 'Time Balance'),
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
