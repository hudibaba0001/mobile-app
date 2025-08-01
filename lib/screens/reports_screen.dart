import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/travel_provider.dart';
import '../providers/location_provider.dart';
import '../services/export_service.dart';
import '../models/travel_summary.dart';
import '../widgets/date_range_picker_widget.dart';
import '../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TravelSummary? _summary;
  bool _isGenerating = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data and generate initial summary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TravelProvider>(context, listen: false).refreshEntries();
      Provider.of<LocationProvider>(context, listen: false).refreshLocations();
      _generateSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateSummary() async {
    setState(() => _isGenerating = true);
    
    final travelProvider = Provider.of<TravelProvider>(context, listen: false);
    final entries = travelProvider.entries.where((entry) {
      return entry.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    if (entries.isEmpty) {
      setState(() {
        _summary = TravelSummary(
          totalEntries: 0,
          totalMinutes: 0,
          startDate: _startDate,
          endDate: _endDate,
          locationFrequency: {},
        );
        _isGenerating = false;
      });
      return;
    }

    // Calculate comprehensive statistics
    final totalMinutes = entries.fold(0, (sum, entry) => sum + entry.minutes);
    final locationFrequency = <String, int>{};
    final departureFrequency = <String, int>{};
    final arrivalFrequency = <String, int>{};
    final dailyMinutes = <String, int>{};
    final weeklyMinutes = <String, int>{};

    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;
      
      departureFrequency[entry.departure] = (departureFrequency[entry.departure] ?? 0) + 1;
      arrivalFrequency[entry.arrival] = (arrivalFrequency[entry.arrival] ?? 0) + 1;
      
      final dayKey = DateFormat('yyyy-MM-dd').format(entry.date);
      dailyMinutes[dayKey] = (dailyMinutes[dayKey] ?? 0) + entry.minutes;
      
      final weekKey = _getWeekKey(entry.date);
      weeklyMinutes[weekKey] = (weeklyMinutes[weekKey] ?? 0) + entry.minutes;
    }

    setState(() {
      _summary = TravelSummary(
        totalEntries: entries.length,
        totalMinutes: totalMinutes,
        startDate: _startDate,
        endDate: _endDate,
        locationFrequency: locationFrequency,
        departureFrequency: departureFrequency,
        arrivalFrequency: arrivalFrequency,
        dailyMinutes: dailyMinutes,
        weeklyMinutes: weeklyMinutes,
      );
      _isGenerating = false;
    });
  }

  String _getWeekKey(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }

  Future<void> _selectDateRange() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Report Period',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              DateRangePickerWidget(
                initialStartDate: _startDate,
                initialEndDate: _endDate,
                onDateRangeSelected: (start, end) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                },
              ),
              const SizedBox(height: AppConstants.largePadding),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _generateSummary();
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('Generate Report'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(String format) async {
    setState(() => _isExporting = true);
    
    try {
      final travelProvider = Provider.of<TravelProvider>(context, listen: false);
      final exportService = ExportService();
      
      final entries = travelProvider.entries.where((entry) {
        return entry.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               entry.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      String? filePath;
      switch (format) {
        case 'csv':
          filePath = await exportService.exportToCSV(entries, _startDate, _endDate);
          break;
        case 'summary':
          if (_summary != null) {
            filePath = await exportService.exportSummaryToCSV(_summary!, _startDate, _endDate);
          }
          break;
      }

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully to $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => exportService.shareFile(filePath!),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            onSelected: _exportData,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Export Raw Data (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'summary',
                child: ListTile(
                  leading: Icon(Icons.summarize),
                  title: Text('Export Summary (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: _isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.location_on), text: 'Locations'),
          ],
        ),
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildLocationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summary!.totalEntries == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Card
          _buildDateRangeCard(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Overview Statistics
          _buildOverviewStats(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Quick Insights
          _buildQuickInsights(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Top Routes
          _buildTopRoutes(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_summary == null || _summary!.totalEntries == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Trends
          _buildDailyTrends(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Weekly Trends
          _buildWeeklyTrends(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Time Distribution
          _buildTimeDistribution(),
        ],
      ),
    );
  }

  Widget _buildLocationsTab() {
    if (_summary == null || _summary!.totalEntries == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Departure Locations
          _buildTopDepartures(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Top Arrival Locations
          _buildTopArrivals(),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Location Usage Map
          _buildLocationUsageMap(),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Trips',
                _summary!.totalEntries.toString(),
                Icons.trip_origin,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildStatCard(
                'Total Time',
                _summary!.formattedDuration,
                Icons.access_time,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Average Trip',
                '${_summary!.averageMinutesPerTrip.toStringAsFixed(0)} min',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildStatCard(
                'Daily Average',
                '${(_summary!.totalMinutes / _endDate.difference(_startDate).inDays).toStringAsFixed(0)} min',
                Icons.today,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    final insights = <String>[];
    
    if (_summary!.totalEntries > 0) {
      insights.add('You made ${_summary!.totalEntries} trips in this period');
      insights.add('Your longest trip was ${_summary!.longestTripMinutes} minutes');
      insights.add('Your shortest trip was ${_summary!.shortestTripMinutes} minutes');
      insights.add('Most frequent route: ${_summary!.mostFrequentRoute}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_right,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRoutes() {
    final sortedRoutes = _summary!.locationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Most Frequent Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...sortedRoutes.take(5).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value} trips',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Travel Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Daily trends chart would be displayed here\n(Chart implementation requires additional dependencies)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Travel Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Weekly trends chart would be displayed here\n(Chart implementation requires additional dependencies)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Duration Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Duration distribution chart would be displayed here\n(Chart implementation requires additional dependencies)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDepartures() {
    final sortedDepartures = _summary!.departureFrequency?.entries.toList() ?? [];
    sortedDepartures.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Departure Locations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...sortedDepartures.take(5).map((entry) => _buildLocationItem(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArrivals() {
    final sortedArrivals = _summary!.arrivalFrequency?.entries.toList() ?? [];
    sortedArrivals.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Arrival Locations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...sortedArrivals.take(5).map((entry) => _buildLocationItem(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(MapEntry<String, int> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.value}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUsageMap() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Usage Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Location usage visualization would be displayed here\n(Map implementation requires additional dependencies)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No data for selected period',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Try selecting a different date range or add some travel entries',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.add),
              label: const Text('Add Travel Entry'),
            ),
          ],
        ),
      ),
    );
  }
}