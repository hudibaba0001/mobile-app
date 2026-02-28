// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../models/absence.dart';
import '../models/entry.dart';
import '../providers/absence_provider.dart';
import '../providers/entry_provider.dart';
import '../widgets/absence_entry_dialog.dart';
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
      _loadAbsencesForVisibleRange();
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
      await _loadAbsencesForVisibleRange();
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadAbsencesForVisibleRange() async {
    final absenceProvider = context.read<AbsenceProvider>();
    final now = DateTime.now();
    await absenceProvider.loadAbsences(year: now.year);
    await absenceProvider.loadAbsences(year: now.year - 1);
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

    return Consumer2<EntryProvider, AbsenceProvider>(
      builder: (context, entryProvider, absenceProvider, child) {
        // Show loading indicator when loading entries
        if (entryProvider.isLoading || absenceProvider.isLoading) {
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

        final items = _buildTimelineItems(
          context,
          entries: entryProvider.filteredEntries,
          absenceProvider: absenceProvider,
        );

        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm + 2),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return _buildLoadingIndicator(context);
            }

            final item = items[index];
            return item.when(
              entry: (entry) => _buildEntryCard(context, entry),
              absence: (absence) => _buildAbsenceCard(context, absence),
            );
          },
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, Entry entry) {
    return EntryCompactTile(
      entry: entry,
      onTap: () => _openQuickView(entry),
      onLongPress: () => _openQuickView(entry),
      showDate: true,
      showNote: true,
      dense: true,
      heroTag: 'entry-${entry.id}',
    );
  }

  Widget _buildAbsenceCard(BuildContext context, AbsenceEntry absence) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final (label, icon, color) = _absenceTypeInfo(context, absence.type);
    final durationLabel = absence.minutes == 0
        ? t.absence_fullDay
        : '${(absence.minutes / 60.0).toStringAsFixed(1)}h';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label),
        subtitle: Text(
          '${DateFormat('yyyy-MM-dd').format(absence.date)} • $durationLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.event_note_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 18,
        ),
        onTap: () => _openAbsenceEdit(absence),
      ),
    );
  }

  List<_HistoryItem> _buildTimelineItems(
    BuildContext context, {
    required List<Entry> entries,
    required AbsenceProvider absenceProvider,
  }) {
    final dateRange = _getDateRangeFilter();
    final query = _searchController.text.trim().toLowerCase();

    final filteredAbsences = _selectedTypeNotifier.value != null
        ? const <AbsenceEntry>[]
        : _allLoadedAbsences(absenceProvider).where((absence) {
            if (dateRange != null) {
              final start = DateTime(
                dateRange.start.year,
                dateRange.start.month,
                dateRange.start.day,
              );
              final end = DateTime(
                dateRange.end.year,
                dateRange.end.month,
                dateRange.end.day,
                23,
                59,
                59,
              );
              if (absence.date.isBefore(start) || absence.date.isAfter(end)) {
                return false;
              }
            }

            if (query.isEmpty) return true;
            final typeLabel = _absenceTypeLabel(context, absence.type);
            final dateLabel = DateFormat('yyyy-MM-dd').format(absence.date);
            return typeLabel.toLowerCase().contains(query) ||
                dateLabel.contains(query);
          }).toList();

    final items = <_HistoryItem>[
      ...entries.map(_HistoryItem.entry),
      ...filteredAbsences.map(_HistoryItem.absence),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return items;
  }

  List<AbsenceEntry> _allLoadedAbsences(AbsenceProvider absenceProvider) {
    final now = DateTime.now();
    final absences = <AbsenceEntry>[
      ...absenceProvider.absencesForYear(now.year),
      ...absenceProvider.absencesForYear(now.year - 1),
    ];
    absences.sort((a, b) => b.date.compareTo(a.date));
    return absences;
  }

  Future<void> _openAbsenceEdit(AbsenceEntry absence) async {
    await showAbsenceEntryDialog(
      context,
      year: absence.date.year,
      absence: absence,
    );
  }

  (String, IconData, Color) _absenceTypeInfo(
      BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case AbsenceType.vacationPaid:
        return (t.leave_paidVacation, Icons.beach_access, colorScheme.primary);
      case AbsenceType.sickPaid:
        return (t.leave_sickLeave, Icons.healing, AppColors.error);
      case AbsenceType.vabPaid:
        return (t.leave_vab, Icons.child_care, AppColors.warning);
      case AbsenceType.parentalLeave:
        return (t.leave_parentalLeave, Icons.family_restroom, AppColors.error);
      case AbsenceType.unpaid:
        return (t.leave_unpaid, Icons.money_off, colorScheme.onSurfaceVariant);
      case AbsenceType.unknown:
        return (t.leave_unknownType, Icons.help_outline, colorScheme.outline);
    }
  }

  String _absenceTypeLabel(BuildContext context, AbsenceType type) {
    final (label, _, __) = _absenceTypeInfo(context, type);
    return label;
  }

  void _openQuickView(Entry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
            heroTag: 'entry-${entry.id}',
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

class _HistoryItem {
  final DateTime date;
  final Entry? entry;
  final AbsenceEntry? absence;

  const _HistoryItem._({
    required this.date,
    this.entry,
    this.absence,
  });

  factory _HistoryItem.entry(Entry entry) => _HistoryItem._(
        date: entry.date,
        entry: entry,
      );

  factory _HistoryItem.absence(AbsenceEntry absence) => _HistoryItem._(
        date: absence.date,
        absence: absence,
      );

  T when<T>({
    required T Function(Entry entry) entry,
    required T Function(AbsenceEntry absence) absence,
  }) {
    if (this.entry != null) return entry(this.entry!);
    return absence(this.absence!);
  }
}
