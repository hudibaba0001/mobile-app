import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/app_theme.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;
  final Function()? onClear;
  final String? label;
  final bool showQuickSelects;

  const DateRangePickerWidget({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
    this.onClear,
    this.label,
    this.showQuickSelects = true,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _updateControllers();
  }

  @override
  void didUpdateWidget(DateRangePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != oldWidget.initialStartDate ||
        widget.initialEndDate != oldWidget.initialEndDate) {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _startDateController.text = _startDate != null
        ? DateFormat(AppConstants.dateFormat).format(_startDate!)
        : '';
    _endDateController.text = _endDate != null
        ? DateFormat(AppConstants.dateFormat).format(_endDate!)
        : '';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _updateControllers();
      widget.onDateRangeSelected(_startDate!, _endDate!);
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
      _updateControllers();
      if (_endDate != null) {
        widget.onDateRangeSelected(_startDate!, _endDate!);
      }
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _updateControllers();
      if (_startDate != null) {
        widget.onDateRangeSelected(_startDate!, _endDate!);
      }
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _updateControllers();
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  void _setQuickDateRange(QuickDateRange range) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case QuickDateRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case QuickDateRange.yesterday:
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case QuickDateRange.thisWeek:
        // Start of week (Monday)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case QuickDateRange.lastWeek:
        // Start of last week (Monday)
        start = now.subtract(Duration(days: now.weekday + 6));
        start = DateTime(start.year, start.month, start.day);
        // End of last week (Sunday)
        end = now.subtract(Duration(days: now.weekday));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59);
        break;
      case QuickDateRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case QuickDateRange.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case QuickDateRange.last30Days:
        start = now.subtract(const Duration(days: 30));
        break;
      case QuickDateRange.last90Days:
        start = now.subtract(const Duration(days: 90));
        break;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _updateControllers();
    widget.onDateRangeSelected(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
        ],

        // Date range input
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat(AppConstants.dateFormat).format(_startDate!)} - ${DateFormat(AppConstants.dateFormat).format(_endDate!)}'
                            : 'Select date range',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _startDate != null && _endDate != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      if (_startDate != null && _endDate != null) ...[
                        const SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          '${_endDate!.difference(_startDate!).inDays + 1} days',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    onPressed: _clearDates,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear dates',
                  ),
              ],
            ),
          ),
        ),

        // Individual date selectors (alternative method)
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _startDateController,
                readOnly: true,
                onTap: _selectStartDate,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).dateRange_startDate,
                  hintText: AppLocalizations.of(context).dateRange_startDate,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: TextFormField(
                controller: _endDateController,
                readOnly: true,
                onTap: _selectEndDate,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).dateRange_endDate,
                  hintText: AppLocalizations.of(context).dateRange_endDate,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

        // Quick select options
        if (widget.showQuickSelects) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            AppLocalizations.of(context).dateRange_quickSelect,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Wrap(
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: QuickDateRange.values.map((range) {
              return ActionChip(
                label: Text(_getQuickRangeLabel(range)),
                onPressed: () => _setQuickDateRange(range),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _getQuickRangeLabel(QuickDateRange range) {
    final t = AppLocalizations.of(context);
    switch (range) {
      case QuickDateRange.today:
        return t.common_today;
      case QuickDateRange.yesterday:
        return t.dateRange_yesterday;
      case QuickDateRange.thisWeek:
        return t.dateRange_thisWeek;
      case QuickDateRange.lastWeek:
        return t.dateRange_lastWeek;
      case QuickDateRange.thisMonth:
        return t.dateRange_thisMonth;
      case QuickDateRange.lastMonth:
        return t.dateRange_lastMonth;
      case QuickDateRange.last30Days:
        return t.dateRange_last30Days;
      case QuickDateRange.last90Days:
        return t.dateRange_last90Days;
    }
  }
}

enum QuickDateRange {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last30Days,
  last90Days,
}
