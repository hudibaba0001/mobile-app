import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/travel_time_entry.dart';
import '../models/travel_summary.dart';
import '../utils/constants.dart';
import '../config/app_router.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Box<TravelTimeEntry> _travelEntriesBox;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TravelSummary? _summary;

  @override
  void initState() {
    super.initState();
    _travelEntriesBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    _generateSummary();
  }

  void _generateSummary() {
    final entries = _travelEntriesBox.values.where((entry) {
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
      });
      return;
    }

    final totalMinutes = entries.fold(0, (sum, entry) => sum + entry.minutes);
    final locationFrequency = <String, int>{};

    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      locationFrequency[route] = (locationFrequency[route] ?? 0) + 1;
    }

    setState(() {
      _summary = TravelSummary(
        totalEntries: entries.length,
        totalMinutes: totalMinutes,
        startDate: _startDate,
        endDate: _endDate,
        locationFrequency: locationFrequency,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _generateSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Period',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: AppConstants.smallPadding),
                        Text(
                          '${DateFormat(AppConstants.displayDateFormat).format(_startDate)} - ${DateFormat(AppConstants.displayDateFormat).format(_endDate)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Change Date Range'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Summary Statistics
            if (_summary != null) ...[
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Trips',
                      value: _summary!.totalEntries.toString(),
                      icon: Icons.trip_origin,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Time',
                      value: _summary!.formattedDuration,
                      icon: Icons.access_time,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.smallPadding),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Average Trip',
                      value: '${_summary!.averageMinutesPerTrip.toStringAsFixed(0)} min',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: _StatCard(
                      title: 'Most Frequent',
                      value: _summary!.mostFrequentRoute,
                      icon: Icons.route,
                      color: Colors.purple,
                      isRoute: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Route Frequency
              if (_summary!.locationFrequency.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Frequent Routes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        ..._summary!.locationFrequency.entries
                            .toList()
                            ..sort((a, b) => b.value.compareTo(a.value))
                            ..take(5)
                            ..map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${entry.value}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            // Empty State
            if (_summary != null && _summary!.totalEntries == 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No data for selected period',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try selecting a different date range or add some travel entries.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go(AppRouter.home),
                        child: const Text('Add Entry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isRoute;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              value,
              style: TextStyle(
                fontSize: isRoute ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: isRoute ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}