import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../services/entry_service.dart';
import '../services/holiday_service.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/unified_entry_form.dart';
import '../widgets/entry_detail_sheet.dart';
import '../l10n/generated/app_localizations.dart';

enum DateRange { today, yesterday, lastWeek, custom }

class EnhancedHistoryScreen extends StatefulWidget {
  const EnhancedHistoryScreen({super.key});

  @override
  State<EnhancedHistoryScreen> createState() => _EnhancedHistoryScreenState();
}

class _EnhancedHistoryScreenState extends State<EnhancedHistoryScreen> {
  final ValueNotifier<EntryType?> _selectedTypeNotifier = ValueNotifier(null);
  final ValueNotifier<DateRange> _selectedDateRangeNotifier =
      ValueNotifier(DateRange.today);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  DateTimeRange? _customDateRange;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Entries should already be loaded on app startup, but reload if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entryProvider = context.read<EntryProvider>();
      if (entryProvider.entries.isEmpty && !entryProvider.isLoading) {
        entryProvider.loadEntries();
      }
    });
  }

  @override
  void dispose() {
    _selectedTypeNotifier.dispose();
    _selectedDateRangeNotifier.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreEntries();
    }
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await EntryService().getMoreEntries();
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(title: t.history_title),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Entry Type Segmented Control
                _buildSegmentedControl(context),

                const SizedBox(height: 16),

                // Date Range Filter Chips
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

  Widget _buildSegmentedControl(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<EntryType?>(
      valueListenable: _selectedTypeNotifier,
      builder: (context, selectedType, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  context,
                  t.history_travel,
                  EntryType.travel,
                  Icons.directions_car_rounded,
                  selectedType,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  context,
                  t.history_work,
                  EntryType.work,
                  Icons.work_outline_rounded,
                  selectedType,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  context,
                  t.history_all,
                  null,
                  Icons.list_alt_rounded,
                  selectedType,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    String label,
    EntryType? type,
    IconData icon,
    EntryType? selectedType,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedType == type;

    return Semantics(
      label: '$label entries filter',
      hint:
          isSelected 
            ? AppLocalizations.of(context)!.history_currentlySelected 
            : AppLocalizations.of(context)!.history_tapToFilter(label),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _selectedTypeNotifier.value = type;
            // Apply filter to EntryProvider
            context.read<EntryProvider>().filterEntries(
                  selectedType: type,
                  searchQuery: _searchController.text,
                  startDate: _getDateRangeFilter()?.start,
                  endDate: _getDateRangeFilter()?.end,
                );
          },
          borderRadius: BorderRadius.circular(8),
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
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeChips(BuildContext context) {
    return ValueListenableBuilder<DateRange>(
      valueListenable: _selectedDateRangeNotifier,
      builder: (context, selectedRange, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Builder(
            builder: (context) {
              final t = AppLocalizations.of(context)!;
              return Row(
                children: [
                  _buildDateChip(context, t.common_today, DateRange.today, selectedRange),
                  const SizedBox(width: 8),
                  _buildDateChip(
                      context, t.history_yesterday, DateRange.yesterday, selectedRange),
                  const SizedBox(width: 8),
                  _buildDateChip(
                      context, t.history_last7Days, DateRange.lastWeek, selectedRange),
                  const SizedBox(width: 8),
                  _buildDateChip(
                      context, t.history_custom, DateRange.custom, selectedRange),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    String label,
    DateRange range,
    DateRange selectedRange,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedRange == range;

    return FilterChip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color:
              isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) async {
        _selectedDateRangeNotifier.value = range;
        if (range == DateRange.custom) {
          await _showDateRangePicker(context);
        }
        // Apply filter to EntryProvider
        context.read<EntryProvider>().filterEntries(
              selectedType: _selectedTypeNotifier.value,
              searchQuery: _searchController.text,
              startDate: _getDateRangeFilter()?.start,
              endDate: _getDateRangeFilter()?.end,
            );
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final t = AppLocalizations.of(context)!;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: t.history_searchHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, child) {
            return value.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
        // Trigger search filtering
        context.read<EntryProvider>().filterEntries(
              searchQuery: value,
              selectedType: _selectedTypeNotifier.value,
              startDate: _getDateRangeFilter()?.start,
              endDate: _getDateRangeFilter()?.end,
            );
      },
    );
  }

  Widget _buildEntryList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
      child: Consumer<EntryProvider>(
        builder: (context, entryProvider, child) {
          // Show loading indicator when loading entries
          if (entryProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.history_loadingEntries,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final entries = entryProvider.filteredEntries;

          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == entries.length) {
                return _buildLoadingIndicator(context);
              }

              final entry = entries[index];
              return _buildEntryCard(context, entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, Entry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWorkEntry = entry.type == EntryType.work;
    final holidayService = context.read<HolidayService>();
    final holidayInfo = holidayService.getHolidayInfo(entry.date);

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openQuickView(entry),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Leading Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWorkEntry
                        ? colorScheme.secondary.withOpacity(0.1)
                        : colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isWorkEntry
                        ? Icons.work_outline_rounded
                        : Icons.directions_car_rounded,
                    color: isWorkEntry
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
                            isWorkEntry 
                                ? AppLocalizations.of(context)!.history_work 
                                : AppLocalizations.of(context)!.history_travel,
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
                              color: isWorkEntry
                                  ? colorScheme.secondary.withOpacity(0.1)
                                  : colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDuration(entry.totalDuration),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isWorkEntry
                                    ? colorScheme.secondary
                                    : colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Holiday work badge (for work entries on red days)
                          if (entry.isHolidayWork) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: AppLocalizations.of(context)!.history_holidayWork(
                                entry.holidayName ?? AppLocalizations.of(context)!.history_redDay
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.history_holidayWorkBadge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Show red day badges (Auto and/or Personal)
                            if (holidayInfo != null) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: AppLocalizations.of(context)!.history_autoMarked(holidayInfo.name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.history_autoBadge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.description ?? AppLocalizations.of(context)!.history_noDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _formatEntryDateTime(entry),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ),
                          if (holidayInfo != null) ...[
                            Text(
                              ' • ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade400,
                              ),
                            ),
                            Text(
                              holidayInfo.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuickView(Entry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: EntryDetailSheet(
            entry: entry,
            onEdit: () => _openEditForm(entry),
            onDelete: () => _showDeleteConfirmation(context, entry),
          ),
        );
      },
    );
  }

  void _openEditForm(Entry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: UnifiedEntryForm(
          entryType: entry.type,
          existingEntry: entry,
          onSaved: () => context.read<EntryProvider>().loadEntries(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
      // Apply custom date range filter
      context.read<EntryProvider>().filterEntries(
            searchQuery: _searchController.text,
            selectedType: _selectedTypeNotifier.value,
            startDate: picked.start,
            endDate: picked.end,
          );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Entry entry) {
    final t = AppLocalizations.of(context)!;
    final typeStr = entry.type == EntryType.travel ? t.entry_travel : t.entry_work;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.entry_deleteTitle),
        content: Text(t.entry_deleteConfirm(typeStr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EntryProvider>().deleteEntry(entry.id);
            },
            child: Text(t.common_delete),
          ),
        ],
      ),
    );
  }

  DateTimeRange? _getDateRangeFilter() {
    switch (_selectedDateRangeNotifier.value) {
      case DateRange.today:
        final now = DateTime.now();
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case DateRange.yesterday:
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(
              yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        );
      case DateRange.lastWeek:
        final now = DateTime.now();
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case DateRange.custom:
        return _customDateRange;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatEntryDateTime(Entry entry) {
    final dateStr = DateFormat('MMM dd, yyyy').format(entry.date);
    
    // For work entries with shifts, show time range
    if (entry.type == EntryType.work && entry.shifts != null && entry.shifts!.isNotEmpty) {
      final firstShift = entry.shifts!.first;
      final lastShift = entry.shifts!.last;
      final startTime = DateFormat('h:mm a').format(firstShift.start);
      final endTime = DateFormat('h:mm a').format(lastShift.end);
      return '$dateStr • $startTime - $endTime';
    }
    
    // For travel entries, just show the date
    return dateStr;
  }
}
