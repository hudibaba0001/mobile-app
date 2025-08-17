import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/customer_analytics_viewmodel.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/export_dialog.dart';
import '../services/export_service.dart';
import '../models/entry.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../repositories/repository_provider.dart';
import '../services/auth_service.dart';
import 'reports/date_range_dialog.dart';
import 'reports/overview_tab.dart';
import 'reports/trends_tab.dart';
import 'reports/locations_tab.dart';

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
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid;

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

  Future<void> _showDateRangeDialog(BuildContext context) async {
    final viewModel = context.read<CustomerAnalyticsViewModel>();
    final initialStartDate = viewModel.startDate ?? DateTime.now().subtract(const Duration(days: 30));
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

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating export...'),
            ],
          ),
        ),
      );

      // Generate CSV file
      final filePath = await ExportService.exportEntriesToCSV(
        entries: entries,
        fileName: fileName,
        startDate: startDate,
        endDate: endDate,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Time Tracker Export - $fileName',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export completed successfully!'),
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
        final authService = context.read<AuthService>();
        final userId = authService.currentUser?.uid;
        viewModel.initialize(
          repositoryProvider.workRepository,
          repositoryProvider.travelRepository,
          userId: userId,
        );
        return viewModel;
      },
      child: Scaffold(
        appBar: StandardAppBar(
          title: 'Reports & Analytics',
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Filter by Date',
              onPressed: () => _showDateRangeDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export Data',
              onPressed: () => _showExportDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: () {
                context.read<CustomerAnalyticsViewModel>().refreshData();
              },
            ),
          ],
        ),
        body: Column(
          children: [
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
                  Tab(text: 'Locations'),
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
                  LocationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
