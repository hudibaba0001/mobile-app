import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';

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

    if (_startDate != null && _endDate != null) {
      final start = DateFormat('yyyyMMdd').format(_startDate!);
      final end = DateFormat('yyyyMMdd').format(_endDate!);
      _customFileName = '${typePrefix}time_tracker_${start}_to_$end';
    } else {
      _customFileName = '${typePrefix}time_tracker_export';
    }
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
    final filteredEntries = _getFilteredEntries();

    return AlertDialog(
      title: const Text('Export Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Include All Data Toggle
            CheckboxListTile(
              title: const Text('Include all data'),
              subtitle: const Text('Export all entries regardless of date'),
              value: _includeAllData,
              onChanged: (value) {
                setState(() {
                  _includeAllData = value ?? true;
                  if (_includeAllData) {
                    _startDate = null;
                    _endDate = null;
                  }
                  _updateDefaultFileName();
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (!_includeAllData) ...[
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  _startDate != null
                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                      : 'Select start date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),

              // End Date
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(
                  _endDate != null
                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                      : 'Select end date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ],

            const SizedBox(height: 24),

            // Entry Type Filter Section
            const Text(
              'Entry Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Entry Type Selection
            RadioListTile<String>(
              title: const Text('Travel Entries Only'),
              subtitle: const Text('Export only travel time entries'),
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
              title: const Text('Work Entries Only'),
              subtitle: const Text('Export only work shift entries'),
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
              title: const Text('Both'),
              subtitle: const Text('Export all entries (travel + work)'),
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
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Export Format Selection
            RadioListTile<String>(
              title: const Text('Excel (.xlsx)'),
              subtitle: const Text('Professional format with formatting'),
              value: 'excel',
              groupValue: _exportFormat,
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('CSV (.csv)'),
              subtitle: const Text('Simple text format'),
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
            const Text(
              'Export Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Filename',
                hintText: 'Enter custom filename',
                border: OutlineInputBorder(),
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
                  const Text(
                    'Export Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Total entries: ${filteredEntries.length}'),
                  Text(
                      'Travel entries: ${filteredEntries.where((e) => e.type == EntryType.travel).length}'),
                  Text(
                      'Work entries: ${filteredEntries.where((e) => e.type == EntryType.work).length}'),
                  Text(
                      'Total hours: ${_calculateTotalHours(filteredEntries).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  List<Entry> _getFilteredEntries() {
    List<Entry> filtered = widget.entries;

    // Filter by entry type
    if (_entryTypeFilter == 'travel') {
      filtered = filtered.where((entry) => entry.type == EntryType.travel).toList();
    } else if (_entryTypeFilter == 'work') {
      filtered = filtered.where((entry) => entry.type == EntryType.work).toList();
    }
    // If 'both', no type filtering needed

    // Filter by date range
    if (!_includeAllData) {
      filtered = filtered.where((entry) {
        if (_startDate != null && entry.date.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && entry.date.isAfter(_endDate!)) {
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

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
        _updateDefaultFileName();
      });
    }
  }

  Future<void> _exportData() async {
    if (_customFileName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a filename')),
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
          const SnackBar(
              content: Text('No entries found for the selected date range')),
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
        SnackBar(content: Text('Error preparing export: $e')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
