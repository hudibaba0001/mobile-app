import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/travel_provider.dart';
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/travel_entry_card.dart';
import '../widgets/quick_entry_form.dart';
import '../models/travel_time_entry.dart';
import '../utils/constants.dart';

class TravelEntriesScreen extends StatefulWidget {
  const TravelEntriesScreen({Key? key}) : super(key: key);

  @override
  State<TravelEntriesScreen> createState() => _TravelEntriesScreenState();
}

class _TravelEntriesScreenState extends State<TravelEntriesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  List<TravelTimeEntry> _selectedEntries = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Load entries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TravelProvider>(context, listen: false).refreshEntries();
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
      body: Consumer3<TravelProvider, SearchProvider, FilterProvider>(
        builder: (context, travelProvider, searchProvider, filterProvider, _) {
          if (travelProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply search and filters
          List<TravelTimeEntry> entries = travelProvider.entries;
          
          // Apply search
          if (searchProvider.hasQuery) {
            entries = entries.where((entry) {
              final query = searchProvider.query.toLowerCase();
              return entry.departure.toLowerCase().contains(query) ||
                     entry.arrival.toLowerCase().contains(query) ||
                     (entry.info?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          // Apply filters
          entries = filterProvider.applyToTravelEntries(entries);

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
                child: _buildEntriesList(entries, travelProvider),
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

  Widget _buildEntriesList(List<TravelTimeEntry> entries, TravelProvider travelProvider) {
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await travelProvider.refreshEntries();
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
              onDelete: () => _showDeleteConfirmation(context, entry, travelProvider),
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
        Provider.of<TravelProvider>(context, listen: false).refreshEntries();
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

  void _toggleSelectionMode(TravelTimeEntry entry) {
    if (!_isSelectionMode) {
      _enterSelectionMode();
      _toggleEntrySelection(entry);
    }
  }

  void _toggleEntrySelection(TravelTimeEntry entry) {
    setState(() {
      if (_selectedEntries.contains(entry)) {
        _selectedEntries.remove(entry);
      } else {
        _selectedEntries.add(entry);
      }
    });
  }

  void _selectAll() {
    final travelProvider = Provider.of<TravelProvider>(context, listen: false);
    setState(() {
      _selectedEntries = List.from(travelProvider.entries);
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
              final travelProvider = Provider.of<TravelProvider>(context, listen: false);
              
              int deletedCount = 0;
              for (final entry in _selectedEntries) {
                final success = await travelProvider.deleteEntry(entry.id);
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
                  Provider.of<TravelProvider>(context, listen: false).refreshEntries();
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

  void _editEntry(BuildContext context, TravelTimeEntry entry) {
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: const Text('Edit functionality will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(BuildContext context, TravelTimeEntry entry) {
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
              _showDeleteConfirmation(context, entry, Provider.of<TravelProvider>(context, listen: false));
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TravelTimeEntry entry,
    TravelProvider travelProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete the trip from ${entry.departure} to ${entry.arrival}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await travelProvider.deleteEntry(entry.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(travelProvider.lastError?.message ?? 'Failed to delete entry'),
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