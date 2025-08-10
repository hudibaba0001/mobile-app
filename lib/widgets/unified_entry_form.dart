import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/location_selector.dart';
import 'package:flutter/foundation.dart';

/// Unified entry form for both travel and work entries
/// Provides appropriate fields based on entry type
class UnifiedEntryForm extends StatefulWidget {
  final EntryType entryType;
  final Entry? existingEntry;
  final VoidCallback? onSaved;

  const UnifiedEntryForm({
    super.key,
    required this.entryType,
    this.existingEntry,
    this.onSaved,
  });

  @override
  State<UnifiedEntryForm> createState() => _UnifiedEntryFormState();
}

class _UnifiedEntryFormState extends State<UnifiedEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // Common fields
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  int _durationMinutes = 0;

  // Travel-specific fields
  String? _departureLocation;
  String? _arrivalLocation;

  // Work-specific fields
  String? _workLocation;
  Shift? _shift;

  // Get current user ID (you'll need to get this from your auth service)
  String get _currentUserId => 'current_user_id'; // TODO: Get from auth service

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _selectedDate = entry.date;
      _startTime = TimeOfDay.fromDateTime(entry.date);
      _durationMinutes = entry.minutes;
      _notesController.text = entry.notes ?? '';

      if (entry.type == EntryType.travel) {
        _departureLocation = entry.departureLocation;
        _arrivalLocation = entry.arrivalLocation;
      } else if (entry.type == EntryType.work) {
        _workLocation = entry.workLocation;
        _shift = entry.shift;
      }

      // Calculate end time from duration
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(
        Duration(minutes: _durationMinutes),
      );
      _endTime = TimeOfDay.fromDateTime(endDateTime);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTravel = widget.entryType == EntryType.travel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isTravel ? Icons.directions_car : Icons.work,
                  color: isTravel
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log ${isTravel ? 'Travel' : 'Work'} Entry',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date and Time Section
            _buildDateTimeSection(theme),
            const SizedBox(height: 20),

            // Location Section
            if (isTravel) _buildTravelLocationSection(theme),
            if (!isTravel) _buildWorkLocationSection(theme),
            const SizedBox(height: 20),

            // Duration Section
            _buildDurationSection(theme),
            const SizedBox(height: 20),

            // Work-specific fields
            if (!isTravel) _buildWorkSpecificFields(theme),

            // Notes Section
            _buildNotesSection(theme),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(theme),

            // Bottom padding for keyboard
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectStartTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startTime.format(context),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTravelLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Route',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: 'From',
          hintText: 'Enter departure location',
          initialValue: _departureLocation,
          onLocationSelected: (location) =>
              setState(() => _departureLocation = location),
          prefixIcon: Icons.my_location,
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: 'To',
          hintText: 'Enter arrival location',
          initialValue: _arrivalLocation,
          onLocationSelected: (location) =>
              setState(() => _arrivalLocation = location),
          prefixIcon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildWorkLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Location',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: 'Location',
          hintText: 'Enter work location',
          initialValue: _workLocation,
          onLocationSelected: (location) =>
              setState(() => _workLocation = location),
          prefixIcon: Icons.work,
        ),
      ],
    );
  }

  Widget _buildDurationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _durationMinutes > 0
                    ? (_durationMinutes ~/ 60).toString()
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                  suffixText: 'h',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final hours = int.tryParse(value) ?? 0;
                  final minutes = _durationMinutes % 60;
                  setState(() => _durationMinutes = (hours * 60) + minutes);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _durationMinutes > 0
                    ? (_durationMinutes % 60).toString()
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
                  suffixText: 'm',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final hours = _durationMinutes ~/ 60;
                  final minutes = int.tryParse(value) ?? 0;
                  setState(() => _durationMinutes = (hours * 60) + minutes);
                },
              ),
            ),
          ],
        ),
        if (_durationMinutes > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Total: ${_formatDuration(_durationMinutes)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkSpecificFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _shift?.description,
          decoration: const InputDecoration(
            labelText: 'Shift',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.schedule),
          ),
          items: Shift.values.map((shiftType) {
            return DropdownMenuItem(
              value: shiftType,
              child: Text(_getShiftDisplayName(shiftType)),
            );
          }).toList(),
          onChanged: (shiftType) {
            if (shiftType != null) {
              // Create a basic shift for the selected type
              final now = DateTime.now();
              final shift = Shift(
                start: now,
                end: now.add(const Duration(hours: 8)),
                description: shiftType,
                location: _workLocation,
              );
              setState(() => _shift = shift);
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Add any additional details...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : _saveEntry,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Entry'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (widget.entryType == EntryType.travel) {
      if (_departureLocation == null || _arrivalLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both departure and arrival locations'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_workLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a work location'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entryProvider = Provider.of<EntryProvider>(context, listen: false);

      final entryDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final entry = Entry(
        id: widget.existingEntry?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId,
        type: widget.entryType,
        date: entryDateTime,
        from: widget.entryType == EntryType.travel ? _departureLocation : null,
        to: widget.entryType == EntryType.travel ? _arrivalLocation : null,
        travelMinutes:
            widget.entryType == EntryType.travel ? _durationMinutes : null,
        shifts: widget.entryType == EntryType.work && _shift != null
            ? [_shift!]
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingEntry != null) {
        await entryProvider.updateEntry(entry);
      } else {
        await entryProvider.addEntry(entry);
      }

      if (kDebugMode) {
        print('✅ UnifiedEntryForm: Saved ${entry.type} entry');
        print('✅ UnifiedEntryForm: Entry ID: ${entry.id}');
        print('✅ UnifiedEntryForm: Duration: ${entry.totalDuration}');
        print('✅ UnifiedEntryForm: Work Duration: ${entry.workDuration}');
        print('✅ UnifiedEntryForm: Travel Duration: ${entry.travelDuration}');
        print('✅ UnifiedEntryForm: Shifts count: ${entry.shifts?.length ?? 0}');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.entryType == EntryType.travel ? 'Travel' : 'Work'} entry ${widget.existingEntry != null ? 'updated' : 'saved'} successfully! 🎉',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  String _getShiftDisplayName(String shiftType) {
    switch (shiftType) {
      case 'morning':
        return 'Morning Shift';
      case 'afternoon':
        return 'Afternoon Shift';
      case 'evening':
        return 'Evening Shift';
      case 'night':
        return 'Night Shift';
      default:
        return 'Unknown Shift';
    }
  }
}
