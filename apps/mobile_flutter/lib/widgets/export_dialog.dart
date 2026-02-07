import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../l10n/generated/app_localizations.dart';

class ExportDialog extends StatefulWidget {
  final List<Entry> entries;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const ExportDialog({
    super.key,
    required this.entries,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _customFileName = '';
  bool _includeAllData = true;
  bool _isExporting = false;
  String _exportFormat = 'excel'; // 'excel' or 'csv'
  String _entryTypeFilter = 'both'; // 'travel', 'work', or 'both'
  late TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    // Set default filename based on date range (without updating controller)
    _calculateDefaultFileName();
    // Initialize controller with the calculated filename
    _fileNameController = TextEditingController(text: _customFileName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _calculateDefaultFileName() {
    String typePrefix = '';
    if (_entryTypeFilter == 'travel') {
      typePrefix = 'travel_';
    } else if (_entryTypeFilter == 'work') {
      typePrefix = 'work_';
    }

    if (!_includeAllData && _startDate != null && _endDate != null) {
      final start = DateFormat('yyyyMMdd').format(_startDate!);
      final end = DateFormat('yyyyMMdd').format(_endDate!);
      _customFileName = '${typePrefix}time_tracker_${start}_to_$end';
    } else {
      _customFileName = '${typePrefix}time_tracker_export';
    }
  }

  String _dateRangeLabel(AppLocalizations t) {
    if (_startDate == null || _endDate == null) return t.dateRange_description;
    final start = DateFormat('MMM dd, yyyy').format(_startDate!);
    final end = DateFormat('MMM dd, yyyy').format(_endDate!);
    return '$start - $end';
  }

  void _updateDefaultFileName() {
    _calculateDefaultFileName();

    // Update the controller text if it's different (controller is initialized after initState)
    if (mounted && _fileNameController.text != _customFileName) {
      _fileNameController.text = _customFileName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filteredEntries = _getFilteredEntries();

    return AlertDialog(
      title: Text(t.export_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section
            Text(
              t.export_dateRange,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Include All Data Toggle
            CheckboxListTile(
              title: Text(t.export_includeAllData),
              subtitle: Text(t.export_includeAllDataDesc),
              value: _includeAllData,
              onChanged: (value) {
                setState(() {
                  _includeAllData = value ?? true;
                  if (!_includeAllData &&
                      (_startDate == null || _endDate == null)) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    _endDate = today;
                    _startDate = today.subtract(const Duration(days: 30));
                  }
                  _updateDefaultFileName();
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (!_includeAllData) ...[
              const SizedBox(height: 16),

              // Date Range (single picker)
              ListTile(
                title: Text(t.dateRange_title),
                subtitle: Text(_dateRangeLabel(t)),
                trailing: const Icon(Icons.date_range_rounded),
                onTap: _selectDateRange,
              ),
            ],

            const SizedBox(height: 24),

            // Entry Type Filter Section
            Text(
              t.export_entryType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Entry Type Selection
            RadioListTile<String>(
              title: Text(t.export_travelOnly),
              subtitle: Text(t.export_travelOnlyDesc),
              value: 'travel',
              groupValue: _entryTypeFilter,
              onChanged: (value) {
                setState(() {
                  _entryTypeFilter = value!;
                  _updateDefaultFileName();
                });
              },
            ),
            RadioListTile<String>(
              title: Text(t.export_workOnly),
              subtitle: Text(t.export_workOnlyDesc),
              value: 'work',
              groupValue: _entryTypeFilter,
              onChanged: (value) {
                setState(() {
                  _entryTypeFilter = value!;
                  _updateDefaultFileName();
                });
              },
            ),
            RadioListTile<String>(
              title: Text(t.export_both),
              subtitle: Text(t.export_bothDesc),
              value: 'both',
              groupValue: _entryTypeFilter,
              onChanged: (value) {
                setState(() {
                  _entryTypeFilter = value!;
                  _updateDefaultFileName();
                });
              },
            ),

            const SizedBox(height: 24),

            // Export Format Section
            Text(
              t.export_formatTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Export Format Selection
            RadioListTile<String>(
              title: Text(t.export_excelFormat),
              subtitle: Text(t.export_excelDesc),
              value: 'excel',
              groupValue: _exportFormat,
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(t.export_csvFormat),
              subtitle: Text(t.export_csvDesc),
              value: 'csv',
              groupValue: _exportFormat,
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Filename Section
            Text(
              t.export_options,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              decoration: InputDecoration(
                labelText: t.export_filename,
                hintText: t.export_filenameHint,
                border: const OutlineInputBorder(),
              ),
              controller: _fileNameController,
              onChanged: (value) {
                _customFileName = value;
              },
            ),

            const SizedBox(height: 16),

            // Export Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.export_summary,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t.export_totalEntries(filteredEntries.length)),
                  Text(t.export_travelEntries(filteredEntries
                      .where((e) => e.type == EntryType.travel)
                      .length)),
                  Text(t.export_workEntries(filteredEntries
                      .where((e) => e.type == EntryType.work)
                      .length)),
                  Text(t.export_totalHours(_calculateTotalHours(filteredEntries)
                      .toStringAsFixed(2))),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: Text(t.common_cancel),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.export_button),
        ),
      ],
    );
  }

  List<Entry> _getFilteredEntries() {
    List<Entry> filtered = widget.entries;

    // Filter by entry type
    if (_entryTypeFilter == 'travel') {
      filtered =
          filtered.where((entry) => entry.type == EntryType.travel).toList();
    } else if (_entryTypeFilter == 'work') {
      filtered =
          filtered.where((entry) => entry.type == EntryType.work).toList();
    }
    // If 'both', no type filtering needed

    // Filter by date range
    if (!_includeAllData) {
      final startDate = _startDate == null
          ? null
          : DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      // Inclusive end-of-day to avoid accidentally excluding entries on the end date.
      final endDate = _endDate == null
          ? null
          : DateTime(
              _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);
      filtered = filtered.where((entry) {
        if (startDate != null && entry.date.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && entry.date.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  double _calculateTotalHours(List<Entry> entries) {
    return entries.fold<double>(
      0.0,
      (total, entry) => total + entry.totalDuration.inMinutes / 60.0,
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final initialRange = (_startDate != null && _endDate != null)
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        // Store date-only in state, but filter inclusively (end-of-day) when applying.
        _startDate =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
        _updateDefaultFileName();
      });
    }
  }

  Future<void> _exportData() async {
    final t = AppLocalizations.of(context);
    if (_customFileName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.export_enterFilename)),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final filteredEntries = _getFilteredEntries();

      if (filteredEntries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.export_noEntriesInRange)),
        );
        return;
      }

      // Return the export configuration
      Navigator.of(context).pop({
        'entries': filteredEntries,
        'fileName': _customFileName.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'format': _exportFormat,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.export_errorPreparing(e.toString()))),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
