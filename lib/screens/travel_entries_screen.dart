import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/travel_time_entry.dart';
import '../utils/constants.dart';
import '../config/app_router.dart';

class TravelEntriesScreen extends StatefulWidget {
  const TravelEntriesScreen({super.key});

  @override
  State<TravelEntriesScreen> createState() => _TravelEntriesScreenState();
}

class _TravelEntriesScreenState extends State<TravelEntriesScreen> {
  late Box<TravelTimeEntry> _travelEntriesBox;
  final TextEditingController _searchController = TextEditingController();
  List<TravelTimeEntry> _filteredEntries = [];
  List<TravelTimeEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _travelEntriesBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEntries() {
    _allEntries = _travelEntriesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _filteredEntries = List.from(_allEntries);
  }

  void _filterEntries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = List.from(_allEntries);
      } else {
        _filteredEntries = _allEntries.where((entry) {
          final searchLower = query.toLowerCase();
          return entry.departure.toLowerCase().contains(searchLower) ||
                 entry.arrival.toLowerCase().contains(searchLower) ||
                 (entry.info?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }
    });
  }

  void _deleteEntry(TravelTimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete this travel entry?\n\n${entry.departure} → ${entry.arrival}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Find and delete the entry
              for (int i = 0; i < _travelEntriesBox.length; i++) {
                final boxEntry = _travelEntriesBox.getAt(i);
                if (boxEntry?.id == entry.id) {
                  _travelEntriesBox.deleteAt(i);
                  break;
                }
              }
              Navigator.of(context).pop();
              _loadEntries();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Entries'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.go(AppRouter.reports),
            tooltip: 'View Reports',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search entries',
                hintText: 'Search by location or info...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterEntries,
            ),
          ),
          
          // Entries List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _travelEntriesBox.listenable(),
              builder: (context, Box<TravelTimeEntry> box, _) {
                _loadEntries();
                _filterEntries(_searchController.text);
                
                if (_filteredEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty ? Icons.inbox : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'No travel entries yet'
                              : 'No entries match your search',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Add your first entry from the home screen!'
                              : 'Try a different search term',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go(AppRouter.home),
                            child: const Text('Add Entry'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                  itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    final duration = Duration(minutes: entry.minutes);
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes % 60;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          child: Text(
                            entry.date.day.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          '${entry.departure} → ${entry.arrival}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(AppConstants.displayDateFormat).format(entry.date),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (entry.info != null && entry.info!.isNotEmpty)
                              Text(
                                entry.info!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    context.go('${AppRouter.editEntry}/${entry.id}');
                                    break;
                                  case 'delete':
                                    _deleteEntry(entry);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, color: Colors.red),
                                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                              child: const Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                        isThreeLine: entry.info != null && entry.info!.isNotEmpty,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRouter.home),
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}