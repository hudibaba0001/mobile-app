import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/repository_provider.dart';
import '../services/auth_service.dart';
import '../viewmodels/customer_analytics_viewmodel.dart';
import 'reports/overview_tab.dart';
import 'reports/trends_tab.dart';
import 'reports/locations_tab.dart';
import 'reports/date_range_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CustomerAnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize ViewModel
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) {
      // Handle error - user should be logged in to see this screen
      return;
    }

    _viewModel = CustomerAnalyticsViewModel(
      repository: context.read<RepositoryProvider>(),
      userId: userId,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDateRangeDialog() async {
    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (context) => DateRangeDialog(
        initialStartDate: _viewModel.startDate,
        initialEndDate: _viewModel.endDate,
      ),
    );

    if (result != null && mounted) {
      final (start, end) = result;
      await _viewModel.updateDateRange(start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Track your productivity',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Date Range Filter Button
          IconButton(
            onPressed: _showDateRangeDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.date_range_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            tooltip: 'Filter by date',
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Locations'),
          ],
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<CustomerAnalyticsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load analytics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () => _viewModel.loadData(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: const [
                OverviewTab(),
                TrendsTab(),
                LocationsTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}
