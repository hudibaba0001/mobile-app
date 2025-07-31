import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';
import '../widgets/travel_entry_card.dart';
import '../models/entry.dart';

/// History screen showing unified history of both travel and work entries.
/// Features: All entries display, filtering by type, search functionality.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterType = 'all'; // 'all', 'travel', 'work'

  @override
  void initState() {
    super.initState();
    // Load entries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EntryProvider>(context, listen: false).refreshEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'all', child: Text('All Entries')),
              const PopupMenuItem(value: 'travel', child: Text('Travel Only')),
              const PopupMenuItem(value: 'work', child: Text('Work Only')),
            ],
          ),
        ],
      ),
      body: Consumer<EntryProvider>(
        builder: (context, entryProvider, child) {
          if (entryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter entries based on selected type
          List<Entry> filteredEntries = entryProvider.entries;
          if (_filterType != 'all') {
            filteredEntries = entryProvider.entries
                .where(
                  (entry) =>
                      entry.type.toString().split('.').last == _filterType,
                )
                .toList();
          }

          if (filteredEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _filterType == 'all'
                        ? 'No entries yet'
                        : 'No ${_filterType} entries yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start logging your ${_filterType == 'all' ? 'travel and work' : _filterType} time!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEntries.length,
            itemBuilder: (context, index) {
              final entry = filteredEntries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TravelEntryCard(
                  entry: entry,
                  onTap: () {
                    // Navigate to edit entry
                    // AppRouter.goToEditEntry(
                    //   context,
                    //   entryId: entry.id,
                    //   entryType: entry.type.toString().split('.').last,
                    // );
                  },
                  onDelete: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Entry'),
                        content: const Text(
                          'Are you sure you want to delete this entry?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await entryProvider.deleteEntry(entry.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
