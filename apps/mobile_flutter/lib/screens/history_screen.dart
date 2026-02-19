// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/unified_entry_form.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/entry_compact_tile.dart';
import '../l10n/generated/app_localizations.dart';

enum DateRange { today, yesterday, lastWeek, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
      // EntryProvider already loads all entries, so pagination is handled client-side
      // If needed in future, implement pagination in EntryProvider
      final entryProvider = context.read<EntryProvider>();
      await entryProvider.loadEntries();
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

    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(title: t.history_title),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Entry Type Segmented Control
                _buildSegmentedControl(context),

                const SizedBox(height: AppSpacing.lg),

                // Date Range Filter Chips
                _buildDateRangeChips(context),

                const SizedBox(height: AppSpacing.lg),

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
    final t = AppLocalizations.of(context);

    return ValueListenableBuilder<EntryType?>(
      valueListenable: _selectedTypeNotifier,
      builder: (context, selectedType, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
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
      hint: isSelected
          ? AppLocalizations.of(context).history_currentlySelected
          : AppLocalizations.of(context).history_tapToFilter(label),
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                const SizedBox(width: AppSpacing.sm),
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
              final t = AppLocalizations.of(context);
              return Row(
                children: [
                  _buildDateChip(
                      context, t.common_today, DateRange.today, selectedRange),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDateChip(context, t.history_yesterday,
                      DateRange.yesterday, selectedRange),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDateChip(context, t.history_last7Days,
                      DateRange.lastWeek, selectedRange),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDateChip(context, t.history_custom, DateRange.custom,
                      selectedRange),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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

    final t = AppLocalizations.of(context);
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
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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

    return Consumer<EntryProvider>(
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppLocalizations.of(context).history_loadingEntries,
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

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: entries.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm + 2),
          itemBuilder: (context, index) {
            if (index == entries.length) {
              return _buildLoadingIndicator(context);
            }

            final entry = entries[index];
            return _buildEntryCard(context, entry);
          },
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, Entry entry) {
    return EntryCompactTile(
      entry: entry,
      onTap: () => _openQuickView(entry),
      showDate: true,
      showNote: true,
      dense: true,
    );
  }

  void _openQuickView(Entry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context).history_noEntriesFound,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).history_tryAdjustingFilters,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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

    if (picked != null && mounted) {
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
    final t = AppLocalizations.of(context);
    final typeStr =
        entry.type == EntryType.travel ? t.entry_travel : t.entry_work;
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
}
