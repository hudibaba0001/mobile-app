import 'package:flutter/material.dart';

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

  final _presets = [
    _DateRangePreset(
      name: 'Last 7 Days',
      getRange: () {
        final now = DateTime.now();
        return (
          now.subtract(const Duration(days: 7)),
          now,
        );
      },
    ),
    _DateRangePreset(
      name: 'Last 30 Days',
      getRange: () {
        final now = DateTime.now();
        return (
          now.subtract(const Duration(days: 30)),
          now,
        );
      },
    ),
    _DateRangePreset(
      name: 'This Month',
      getRange: () {
        final now = DateTime.now();
        return (
          DateTime(now.year, now.month, 1),
          now,
        );
      },
    ),
    _DateRangePreset(
      name: 'Last Month',
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
      name: 'This Year',
      getRange: () {
        final now = DateTime.now();
        return (
          DateTime(now.year, 1, 1),
          now,
        );
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedPresetIndex = -1;

    // Check if current range matches any preset
    for (var i = 0; i < _presets.length; i++) {
      final (presetStart, presetEnd) = _presets[i].getRange();
      if (_isSameDay(_startDate, presetStart) && _isSameDay(_endDate, presetEnd)) {
        _selectedPresetIndex = i;
        break;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      final (start, end) = _presets[index].getRange();
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
        _selectedPresetIndex = -1;
        for (var i = 0; i < _presets.length; i++) {
          final (presetStart, presetEnd) = _presets[i].getRange();
          if (_isSameDay(_startDate, presetStart) &&
              _isSameDay(_endDate, presetEnd)) {
            _selectedPresetIndex = i;
            break;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                color: colorScheme.primary.withOpacity(0.1),
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
                      color: colorScheme.primary.withOpacity(0.2),
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
                          'Select Date Range',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a time period to analyze',
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
                    'Quick Selections',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final preset = entry.value;
                      final isSelected = index == _selectedPresetIndex;

                      return FilterChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onSelected: (_) => _selectPreset(index),
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
                              : colorScheme.outline.withOpacity(0.2),
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
                    'Custom Range',
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
                          label: 'Start Date',
                          date: _startDate,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          theme,
                          label: 'End Date',
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
                            'Cancel',
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
                          child: const Text('Apply'),
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
            color: theme.colorScheme.outline.withOpacity(0.2),
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
