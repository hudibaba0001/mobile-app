import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/local_entry_provider.dart';
import '../services/dummy_auth_service.dart';

/// Simple entry form for both travel and work entries
class SimpleEntryForm extends StatefulWidget {
  final EntryType entryType;
  final Entry? existingEntry;
  final VoidCallback? onSaved;

  const SimpleEntryForm({
    super.key,
    required this.entryType,
    this.existingEntry,
    this.onSaved,
  });

  @override
  State<SimpleEntryForm> createState() => _SimpleEntryFormState();
}

class _SimpleEntryFormState extends State<SimpleEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
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
      _notesController.text = entry.notes ?? '';

      if (entry.type == EntryType.travel) {
        _fromController.text = entry.from ?? '';
        _toController.text = entry.to ?? '';
        final minutes = entry.travelMinutes ?? 0;
        _hoursController.text = (minutes ~/ 60).toString();
        _minutesController.text = (minutes % 60).toString();
      } else if (entry.type == EntryType.work) {
        final totalMinutes = entry.workDuration.inMinutes;
        _hoursController.text = (totalMinutes ~/ 60).toString();
        _minutesController.text = (totalMinutes % 60).toString();
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTravel = widget.entryType == EntryType.travel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log ${isTravel ? 'Travel' : 'Work'} Entry',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Selection
              _buildDateTimeSection(theme),
              const SizedBox(height: 20),

              // Location fields for travel
              if (isTravel) ...[
                TextFormField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'From Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.my_location),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter departure location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'To Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter arrival location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Duration Section
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
                      controller: _hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                        suffixText: 'h',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final hours = int.tryParse(value ?? '');
                        if (hours == null || hours < 0) {
                          return 'Enter valid hours';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                        suffixText: 'm',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final minutes = int.tryParse(value ?? '');
                        if (minutes == null || minutes < 0 || minutes >= 60) {
                          return 'Enter 0-59 minutes';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notes Section
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEntry,
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
              ),

              // Bottom padding for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
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

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<DummyAuthService>(context, listen: false);
      final entryProvider = Provider.of<LocalEntryProvider>(
        context,
        listen: false,
      );

      final hours = int.tryParse(_hoursController.text) ?? 0;
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final totalMinutes = (hours * 60) + minutes;

      if (totalMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid duration'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final entryDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      Entry entry;

      if (widget.entryType == EntryType.travel) {
        entry = Entry(
          id: widget.existingEntry?.id,
          userId: authService.currentUserId,
          type: EntryType.travel,
          from: _fromController.text.trim(),
          to: _toController.text.trim(),
          travelMinutes: totalMinutes,
          date: entryDateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: widget.existingEntry?.createdAt,
        );
      } else {
        // For work entries, create a simple shift
        final shift = Shift(
          start: entryDateTime,
          end: entryDateTime.add(Duration(minutes: totalMinutes)),
          description: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        entry = Entry(
          id: widget.existingEntry?.id,
          userId: authService.currentUserId,
          type: EntryType.work,
          shifts: [shift],
          date: entryDateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: widget.existingEntry?.createdAt,
        );
      }

      if (widget.existingEntry != null) {
        await entryProvider.updateEntry(entry);
      } else {
        await entryProvider.addEntry(entry);
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
}
