import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/location_selector.dart';
import '../services/supabase_auth_service.dart';
import '../services/map_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/keyboard_aware_form_container.dart';

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

  String? get _currentUserId => context.read<SupabaseAuthService>().currentUser?.id;

  bool _isLoading = false;
  bool _isCalculatingTravelTime = false;
  String? _travelTimeError;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _selectedDate = entry.date;
      _durationMinutes = entry.minutes ?? 0;
      _notesController.text = entry.notes ?? '';

      if (entry.type == EntryType.travel) {
        _departureLocation = entry.departureLocation;
        _arrivalLocation = entry.arrivalLocation;
        // For travel entries, set start time to current time (not used for saving, just for display if needed)
        _startTime = TimeOfDay.now();
      } else if (entry.type == EntryType.work) {
        // Initialize work fields from first shift if present
        final Shift? firstShift = entry.shift;
        _workLocation = firstShift?.location ?? entry.workLocation;
        if (firstShift != null) {
          _selectedDate = DateTime(
            firstShift.start.year,
            firstShift.start.month,
            firstShift.start.day,
          );
          _startTime = TimeOfDay.fromDateTime(firstShift.start);
          _endTime = TimeOfDay.fromDateTime(firstShift.end);
        } else {
          _startTime = TimeOfDay.fromDateTime(entry.date);
        }
      } else {
        _startTime = TimeOfDay.fromDateTime(entry.date);
      }
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

    return KeyboardAwareFormContainer(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date and Time Section
              isTravel
                  ? _buildTravelDateAndTimesSection(theme)
                  : _buildWorkDateAndTimesSection(theme),
              const SizedBox(height: 20),

              // Location Section
              if (isTravel) _buildTravelLocationSection(theme),
              if (!isTravel) _buildWorkLocationSection(theme),
              const SizedBox(height: 20),

              // Duration Section: for Travel only (manual minutes when no end time)
              if (isTravel) _buildDurationSection(theme),
              const SizedBox(height: 20),

              // Work-specific fields
              if (!isTravel) _buildWorkSpecificFields(theme),

              // Notes Section
              _buildNotesSection(theme),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(theme),

              // End padding handled via container padding
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused _buildDateTimeSection

  Widget _buildTravelDateAndTimesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
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
          ],
        ),
      ],
    );
  }

  Widget _buildWorkDateAndTimesSection(ThemeData theme) {
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
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
                        Icons.play_arrow,
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
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectEndTime,
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
                        Icons.stop,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'End time',
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
          onLocationSelected: (location) {
            setState(() {
              _departureLocation = location;
              _travelTimeError = null; // Clear error when location changes
            });
          },
          prefixIcon: Icons.my_location,
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: 'To',
          hintText: 'Enter arrival location',
          initialValue: _arrivalLocation,
          onLocationSelected: (location) {
            setState(() {
              _arrivalLocation = location;
              _travelTimeError = null; // Clear error when location changes
            });
          },
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 12),
        // Calculate Travel Time Button
        if (_departureLocation != null && 
            _departureLocation!.isNotEmpty && 
            _arrivalLocation != null && 
            _arrivalLocation!.isNotEmpty)
          OutlinedButton.icon(
            onPressed: _isCalculatingTravelTime ? null : _calculateTravelTime,
            icon: _isCalculatingTravelTime
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.directions_car),
            label: Text(_isCalculatingTravelTime 
                ? 'Calculating...' 
                : 'Calculate Travel Time'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (_travelTimeError != null) ...[
          const SizedBox(height: 8),
          Text(
            _travelTimeError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _calculateTravelTime() async {
    if (_departureLocation == null || 
        _departureLocation!.isEmpty || 
        _arrivalLocation == null || 
        _arrivalLocation!.isEmpty) {
      return;
    }

    setState(() {
      _isCalculatingTravelTime = true;
      _travelTimeError = null;
    });

    try {
      final result = await MapService.calculateTravelTime(
        origin: _departureLocation!,
        destination: _arrivalLocation!,
      );

      final durationMinutes = result['durationMinutes'] as int;
      final durationText = result['durationText'] as String;
      final distanceText = result['distanceText'] as String;

      setState(() {
        _durationMinutes = durationMinutes;
        // Calculate end time based on start time and duration
        final startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));
        _endTime = TimeOfDay.fromDateTime(endDateTime);
        _isCalculatingTravelTime = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Travel time calculated: $durationText ($distanceText)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculatingTravelTime = false;
        _travelTimeError = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calculate travel time: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

  Future<void> _selectEndTime() async {
    final initial =
        _endTime ?? _startTime.replacing(minute: (_startTime.minute + 30) % 60);
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time != null) {
      setState(() => _endTime = time);
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
      if (_endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an end time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // For Work: duration is derived from start/end; no manual minutes required

    setState(() => _isLoading = true);

    try {
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to save entries'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final entryProvider = context.read<EntryProvider>();

      // For travel entries, use date only (no time). For work entries, include time.
      final entryDateTime = widget.entryType == EntryType.travel
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            )
          : DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _startTime.hour,
              _startTime.minute,
            );

      // For travel entries, use calculated duration or manual duration input
      int? finalTravelMinutes;
      if (widget.entryType == EntryType.travel) {
        // Use calculated duration (from Mapbox API) or manual duration input
        finalTravelMinutes = _durationMinutes > 0 ? _durationMinutes : null;
      }

      final entry = Entry(
        id: widget.existingEntry?.id, // Let Entry model generate UUID if null
        userId: _currentUserId!,
        type: widget.entryType,
        date: entryDateTime,
        from: widget.entryType == EntryType.travel ? _departureLocation : null,
        to: widget.entryType == EntryType.travel ? _arrivalLocation : null,
        travelMinutes: finalTravelMinutes,
        shifts: widget.entryType == EntryType.work
            ? [
                Shift(
                  start: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _startTime.hour,
                    _startTime.minute,
                  ),
                  end: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  ),
                  description: _shift?.description,
                  location: _workLocation,
                ),
              ]
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
