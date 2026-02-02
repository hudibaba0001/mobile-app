import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class DateRangeDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const DateRangeDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late int _selectedPresetIndex;

  List<_DateRangePreset> _getPresets(BuildContext context) {
    final t = AppLocalizations.of(context);
    return [
      _DateRangePreset(
        name: t.dateRange_last7Days,
        getRange: () {
          final now = DateTime.now();
          return (
            now.subtract(const Duration(days: 7)),
            now,
          );
        },
      ),
      _DateRangePreset(
        name: t.dateRange_last30Days,
        getRange: () {
          final now = DateTime.now();
          return (
            now.subtract(const Duration(days: 30)),
            now,
          );
        },
      ),
      _DateRangePreset(
        name: t.dateRange_thisMonth,
        getRange: () {
          final now = DateTime.now();
          return (
            DateTime(now.year, now.month, 1),
            now,
          );
        },
      ),
      _DateRangePreset(
        name: t.dateRange_lastMonth,
        getRange: () {
          final now = DateTime.now();
          final lastMonth = DateTime(now.year, now.month - 1);
          return (
            DateTime(lastMonth.year, lastMonth.month, 1),
            DateTime(now.year, now.month, 0),
          );
        },
      ),
      _DateRangePreset(
        name: t.dateRange_thisYear,
        getRange: () {
          final now = DateTime.now();
          return (
            DateTime(now.year, 1, 1),
            now,
          );
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedPresetIndex = -1;
  }

  void _checkPresetMatch(BuildContext context) {
    final presets = _getPresets(context);
    _selectedPresetIndex = -1;
    for (var i = 0; i < presets.length; i++) {
      final (presetStart, presetEnd) = presets[i].getRange();
      if (_isSameDay(_startDate, presetStart) && _isSameDay(_endDate, presetEnd)) {
        _selectedPresetIndex = i;
        break;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _selectPreset(int index, BuildContext context) {
    final presets = _getPresets(context);
    setState(() {
      _selectedPresetIndex = index;
      final (start, end) = presets[index].getRange();
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate
        ? DateTime(2020)
        : _startDate;
    final lastDate = isStartDate
        ? _endDate
        : DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
        // Clear preset selection if dates don't match any preset
        _checkPresetMatch(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final presets = _getPresets(context);
    
    // Check preset match on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPresetMatch(context);
    });

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dateRange_title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.dateRange_description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Selections
                  Text(
                    t.dateRange_quickSelections,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final preset = entry.value;
                      final isSelected = index == _selectedPresetIndex;

                      return FilterChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onSelected: (_) => _selectPreset(index, context),
                        showCheckmark: false,
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                        backgroundColor: colorScheme.surface,
                        selectedColor: colorScheme.primary,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Custom Range
                  Text(
                    t.dateRange_customRange,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          theme,
                          label: t.dateRange_startDate,
                          date: _startDate,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          theme,
                          label: t.dateRange_endDate,
                          date: _endDate,
                          onTap: () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            t.common_cancel,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop((_startDate, _endDate));
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(t.dateRange_apply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    ThemeData theme, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangePreset {
  final String name;
  final (DateTime, DateTime) Function() getRange;

  const _DateRangePreset({
    required this.name,
    required this.getRange,
  });
}
