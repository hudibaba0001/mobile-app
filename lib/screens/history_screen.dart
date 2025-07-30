import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EntryType { travel, work, all }
enum DateRange { today, yesterday, lastWeek, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  EntryType selectedType = EntryType.all;
  DateRange selectedDateRange = DateRange.today;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreEntries();
    }
  }

  void _loadMoreEntries() {
    if (!isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });
      
      // Simulate loading delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoadingMore = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
        ),
        title: Text(
          'History',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Entry Type Toggle
                _buildEntryTypeToggle(context),
                
                const SizedBox(height: 16),
                
                // Date Range Chips
                _buildDateRangeChips(context),
                
                const SizedBox(height: 16),
                
                // Search Field
                _buildSearchField(context),
              ],
            ),
          ),
          
          // Entry List
          Expanded(
            child: _buildEntryList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTypeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              context,
              'Travel',
              EntryType.travel,
              Icons.directions_car_rounded,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              context,
              'Work',
              EntryType.work,
              Icons.work_outline_rounded,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              context,
              'All',
              EntryType.all,
              Icons.list_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String label,
    EntryType type,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDateChip(context, 'Today', DateRange.today),
          const SizedBox(width: 8),
          _buildDateChip(context, 'Yesterday', DateRange.yesterday),
          const SizedBox(width: 8),
          _buildDateChip(context, 'Last 7 Days', DateRange.lastWeek),
          const SizedBox(width: 8),
          _buildDateChip(context, 'Custom', DateRange.custom),
        ],
      ),
    );
  }

  Widget _buildDateChip(BuildContext context, String label, DateRange range) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedDateRange == range;

    return FilterChip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedDateRange = range;
        });
        if (range == DateRange.custom) {
          _showDateRangePicker(context);
        }
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by location, notes...',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.clear_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildEntryList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock data - replace with actual data
    final entries = _getMockEntries();

    return Container(
      color: colorScheme.surfaceVariant.withOpacity(0.1),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return _buildLoadingIndicator(context);
          }
          
          final entry = entries[index];
          return _buildEntryCard(context, entry);
        },
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, HistoryEntry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Leading Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.type == EntryType.work
                    ? colorScheme.secondary.withOpacity(0.1)
                    : colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                entry.type == EntryType.work
                    ? Icons.work_outline_rounded
                    : Icons.directions_car_rounded,
                color: entry.type == EntryType.work
                    ? colorScheme.secondary
                    : colorScheme.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Entry Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.type == EntryType.work ? 'Work' : 'Travel',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: entry.type == EntryType.work
                              ? colorScheme.secondary.withOpacity(0.1)
                              : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.duration,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: entry.type == EntryType.work
                                ? colorScheme.secondary
                                : colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.dateTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // More Menu
            IconButton(
              onPressed: () => _showEntryMenu(context, entry),
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
  }

  void _showEntryMenu(BuildContext context, HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Entry'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: const Text('Delete Entry'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete entry logic
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<HistoryEntry> _getMockEntries() {
    return [
      HistoryEntry(
        type: EntryType.work,
        subtitle: 'Office work session',
        dateTime: 'Today, 9:00 AM - 5:00 PM',
        duration: '8h',
      ),
      HistoryEntry(
        type: EntryType.travel,
        subtitle: 'Home → Office',
        dateTime: 'Today, 8:30 AM',
        duration: '30m',
      ),
      HistoryEntry(
        type: EntryType.work,
        subtitle: 'Remote work',
        dateTime: 'Yesterday, 10:00 AM - 6:00 PM',
        duration: '8h',
      ),
      HistoryEntry(
        type: EntryType.travel,
        subtitle: 'Office → Client Meeting',
        dateTime: 'Yesterday, 2:00 PM',
        duration: '45m',
      ),
      HistoryEntry(
        type: EntryType.work,
        subtitle: 'Client presentation',
        dateTime: 'Yesterday, 2:45 PM - 4:00 PM',
        duration: '1h 15m',
      ),
    ];
  }
}

class HistoryEntry {
  final EntryType type;
  final String subtitle;
  final String dateTime;
  final String duration;

  HistoryEntry({
    required this.type,
    required this.subtitle,
    required this.dateTime,
    required this.duration,
  });
}
