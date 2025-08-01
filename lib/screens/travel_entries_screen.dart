import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/entry_provider.dart'; // Updated to use EntryProvider
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/travel_entry_card.dart';
import '../widgets/quick_entry_form.dart';
import '../widgets/multi_segment_form.dart';
import '../models/entry.dart'; // Updated to use unified Entry model
import '../utils/constants.dart';

class TravelEntriesScreen extends StatefulWidget {
  const TravelEntriesScreen({super.key});

  @override
  State<TravelEntriesScreen> createState() => _TravelEntriesScreenState();
}

class _TravelEntriesScreenState extends State<TravelEntriesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  List<Entry> _selectedEntries = []; // Updated to use Entry model
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Load entries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EntryProvider>(context, listen: false).refreshEntries(); // Updated to use EntryProvider
    });

    // Hide FAB when scrolling down, show when scrolling up
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) setState(() => _showFab = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) setState(() => _showFab = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedEntries.length} selected')
            : const Text('Travel Entries'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedEntries.isNotEmpty ? _deleteSelectedEntries : null,
                  tooltip: 'Delete Selected',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showQuickEntryDialog(context),
                  tooltip: 'Quick Add',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select_mode',
                      child: ListTile(
                        leading: Icon(Icons.checklist),
                        title: Text('Select Multiple'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Export Data'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Consumer3<EntryProvider, SearchProvider, FilterProvider>( // Updated to use EntryProvider
        builder: (context, entryProvider, searchProvider, filterProvider, _) {
          if (entryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply search and filters
          List<Entry> entries = entryProvider.entries; // Updated to use Entry model
          
          // Apply search
          if (searchProvider.hasQuery) {
            entries = entries.where((entry) {
              final query = searchProvider.query.toLowerCase();
              return (entry.from?.toLowerCase().contains(query) ?? false) || // Entry uses 'from' instead of 'departure'
                     (entry.to?.toLowerCase().contains(query) ?? false) || // Entry uses 'to' instead of 'arrival'
                     (entry.notes?.toLowerCase().contains(query) ?? false); // Entry uses 'notes' instead of 'info'
            }).toList();
          }

          // Apply filters - need to update FilterProvider to work with Entry model
          entries = filterProvider.applyToEntries(entries); // Updated method name

          return Column(
            children: [
              // Search and Filter Bar
              SearchFilterBar(
                searchHint: 'Search travel entries...',
                onSearch: (query) {
                  // Search is handled by the SearchProvider
                },
                onFiltersChanged: () {
                  // Filters are handled by the FilterProvider
                },
              ),

              // Results summary
              if (searchProvider.hasQuery || filterProvider.hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} found',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Entries List
              Expanded(
                child: _buildEntriesList(entries, entryProvider), // Updated to use entryProvider
              ),
            ],
          );
        },
      ),
      floatingActionButton: _showFab && !_isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickEntryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            )
          : null,
    );
  }

  Widget _buildEntriesList(List<Entry> entries, EntryProvider entryProvider) { // Updated to use Entry and EntryProvider
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await entryProvider.refreshEntries(); // Updated to use entryProvider
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = _selectedEntries.contains(entry);

          return GestureDetector(
            onLongPress: () => _toggleSelectionMode(entry),
            child: TravelEntryCard(
              entry: entry,
              onEdit: () => _editEntry(context, entry),
              onDelete: () => _showDeleteConfirmation(context, entry, entryProvider), // Updated to use entryProvider
              onTap: _isSelectionMode 
                  ? () => _toggleEntrySelection(entry)
                  : () => _showEntryDetails(context, entry),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final searchProvider = Provider.of<SearchProvider>(context);
    final filterProvider = Provider.of<FilterProvider>(context);
    
    final hasActiveSearchOrFilter = searchProvider.hasQuery || filterProvider.hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveSearchOrFilter ? Icons.search_off : Icons.route,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              hasActiveSearchOrFilter 
                  ? 'No entries found'
                  : 'No travel entries yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              hasActiveSearchOrFilter
                  ? 'Try adjusting your search or filters'
                  : 'Add your first travel entry to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.largePadding),
            if (hasActiveSearchOrFilter)
              ElevatedButton.icon(
                onPressed: () {
                  searchProvider.clearQuery();
                  filterProvider.clearAllFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Search & Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showQuickEntryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add First Entry'),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'select_mode':
        _enterSelectionMode();
        break;
      case 'export':
        context.go('/reports');
        break;
      case 'refresh':
        Provider.of<EntryProvider>(context, listen: false).refreshEntries(); // Updated to use EntryProvider
        break;
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedEntries.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedEntries.clear();
    });
  }

  void _toggleSelectionMode(Entry entry) { // Updated to use Entry
    if (!_isSelectionMode) {
      _enterSelectionMode();
      _toggleEntrySelection(entry);
    }
  }

  void _toggleEntrySelection(Entry entry) { // Updated to use Entry
    setState(() {
      if (_selectedEntries.contains(entry)) {
        _selectedEntries.remove(entry);
      } else {
        _selectedEntries.add(entry);
      }
    });
  }

  void _selectAll() {
    final entryProvider = Provider.of<EntryProvider>(context, listen: false); // Updated to use EntryProvider
    setState(() {
      _selectedEntries = List.from(entryProvider.entries);
    });
  }

  void _deleteSelectedEntries() {
    if (_selectedEntries.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entries'),
        content: Text(
          'Are you sure you want to delete ${_selectedEntries.length} ${_selectedEntries.length == 1 ? 'entry' : 'entries'}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final entryProvider = Provider.of<EntryProvider>(context, listen: false); // Updated to use EntryProvider
              
              int deletedCount = 0;
              for (final entry in _selectedEntries) {
                final success = await entryProvider.deleteEntry(entry.id);
                if (success) deletedCount++;
              }
              
              _exitSelectionMode();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$deletedCount ${deletedCount == 1 ? 'entry' : 'entries'} deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showQuickEntryDialog(BuildContext context) {
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
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Entry',
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
              QuickEntryForm(
                onSuccess: () {
                  Navigator.of(context).pop();
                  Provider.of<EntryProvider>(context, listen: false).refreshEntries(); // Updated to use EntryProvider
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editEntry(BuildContext context, Entry entry) { // Updated to use Entry
    final entryProvider = Provider.of<EntryProvider>(context, listen: false); // Updated to use EntryProvider
    
    // Check if this is a multi-segment journey
    if (entryProvider.isMultiSegmentEntry(entry)) {
      // Edit as multi-segment journey
      final journeySegments = entryProvider.getJourneySegments(entry.journeyId!);
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            child: MultiSegmentForm(
              editingJourneyId: entry.journeyId,
              existingSegments: journeySegments,
              initialDate: entry.date,
              onSuccess: () {
                Navigator.of(context).pop();
                // Refresh the entries list
                entryProvider.refreshEntries(); // Updated to use entryProvider
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      );
    } else {
      // Edit as single entry
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            child: QuickEntryForm(
              initialEntry: entry,
              onSuccess: () {
                Navigator.of(context).pop();
                entryProvider.refreshEntries(); // Updated to use entryProvider
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      );
    }
  }

  void _showEntryDetails(BuildContext context, Entry entry) { // Updated to use Entry
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          child: TravelEntryCard(
            entry: entry,
            onEdit: () {
              Navigator.of(context).pop();
              _editEntry(context, entry);
            },
            onDelete: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, entry, Provider.of<EntryProvider>(context, listen: false)); // Updated to use EntryProvider
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Entry entry, // Updated to use Entry
    EntryProvider entryProvider, // Updated to use EntryProvider
  ) {
    final isMultiSegment = entryProvider.isMultiSegmentEntry(entry);
    final journeySegments = isMultiSegment ? entryProvider.getJourneySegments(entry.journeyId!) : <Entry>[]; // Updated to use Entry
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMultiSegment ? 'Delete Journey' : 'Delete Entry'),
        content: Text(isMultiSegment 
            ? 'Are you sure you want to delete the entire multi-segment journey with ${journeySegments.length} segments?'
            : 'Are you sure you want to delete the trip from ${entry.from ?? 'Unknown'} to ${entry.to ?? 'Unknown'}?'), // Updated to use Entry fields
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              bool success;
              if (isMultiSegment) {
                success = await entryProvider.deleteJourney(entry.journeyId!); // Updated to use entryProvider
              } else {
                success = await entryProvider.deleteEntry(entry.id); // Updated to use entryProvider
              }
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMultiSegment 
                        ? 'Multi-segment journey deleted successfully'
                        : 'Entry deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(entryProvider.lastError?.message ?? 'Failed to delete entry'), // Updated to use entryProvider
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}