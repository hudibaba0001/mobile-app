import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/travel_time_entry.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../config/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  late Box<TravelTimeEntry> _travelEntriesBox;

  @override
  void initState() {
    super.initState();
    _travelEntriesBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    // Set today's date as default
    _dateController.text = DateFormat(AppConstants.dateFormat).format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _infoController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat(AppConstants.dateFormat).format(picked);
      });
    }
  }

  void _logTravelTime() {
    if (_formKey.currentState!.validate()) {
      final entry = TravelTimeEntry(
        date: DateTime.parse(_dateController.text),
        departure: _departureController.text.trim(),
        arrival: _arrivalController.text.trim(),
        info: _infoController.text.trim().isEmpty ? null : _infoController.text.trim(),
        minutes: int.parse(_timeController.text),
      );

      _travelEntriesBox.add(entry);

      // Clear the form
      _formKey.currentState!.reset();
      _dateController.text = DateFormat(AppConstants.dateFormat).format(DateTime.now());
      _departureController.clear();
      _arrivalController.clear();
      _infoController.clear();
      _timeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Travel time logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Time Logger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.go(AppRouter.travelEntries),
            tooltip: 'View All Entries',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () => context.go(AppRouter.locations),
            tooltip: 'Manage Locations',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reports':
                  context.go(AppRouter.reports);
                  break;
                case 'settings':
                  context.go(AppRouter.settings);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reports',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Reports'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Entry Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Entry',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              hintText: 'Select travel date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _departureController,
                            decoration: const InputDecoration(
                              labelText: 'From',
                              hintText: 'Departure location',
                              prefixIcon: Icon(Icons.my_location),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => Validators.validateRequired(value, 'Departure location'),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _arrivalController,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              hintText: 'Arrival location',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => Validators.validateRequired(value, 'Arrival location'),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _timeController,
                            decoration: const InputDecoration(
                              labelText: 'Travel Time (minutes)',
                              hintText: 'e.g., 45',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: Validators.validateMinutes,
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          TextFormField(
                            controller: _infoController,
                            decoration: const InputDecoration(
                              labelText: 'Additional Info (Optional)',
                              hintText: 'Notes, delays, etc.',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: Validators.validateInfo,
                          ),
                          const SizedBox(height: AppConstants.largePadding),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logTravelTime,
                              icon: const Icon(Icons.add),
                              label: const Text('Log Travel Time'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            
            // Recent Entries Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Entries',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRouter.travelEntries),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    ValueListenableBuilder(
                      valueListenable: _travelEntriesBox.listenable(),
                      builder: (context, Box<TravelTimeEntry> box, _) {
                        if (box.values.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppConstants.largePadding),
                              child: Column(
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No travel entries yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Add your first entry above!',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        final recentEntries = box.values.toList()
                          ..sort((a, b) => b.date.compareTo(a.date));
                        final displayEntries = recentEntries.take(3).toList();
                        
                        return Column(
                          children: displayEntries.map((entry) => Card(
                            margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(entry.date.day.toString()),
                              ),
                              title: Text('${entry.departure} → ${entry.arrival}'),
                              subtitle: Text(
                                '${DateFormat(AppConstants.displayDateFormat).format(entry.date)} • ${entry.minutes} min',
                              ),
                              trailing: Text(
                                '${(entry.minutes / 60).toStringAsFixed(1)}h',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}