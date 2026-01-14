import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_red_day.dart';
import '../services/holiday_service.dart';

/// Dialog for adding/editing a personal red day
class AddRedDayDialog extends StatefulWidget {
  final DateTime date;
  final HolidayService holidayService;
  final String userId;
  final UserRedDay? existingRedDay;

  const AddRedDayDialog({
    super.key,
    required this.date,
    required this.holidayService,
    required this.userId,
    this.existingRedDay,
  });

  @override
  State<AddRedDayDialog> createState() => _AddRedDayDialogState();
}

class _AddRedDayDialogState extends State<AddRedDayDialog> {
  late RedDayKind _kind;
  HalfDay? _half;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRedDay != null) {
      _kind = widget.existingRedDay!.kind;
      _half = widget.existingRedDay!.half;
      _reasonController.text = widget.existingRedDay!.reason ?? '';
    } else {
      _kind = RedDayKind.full;
      _half = null;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final redDay = UserRedDay(
        id: widget.existingRedDay?.id,
        userId: widget.userId,
        date: widget.date,
        kind: _kind,
        half: _kind == RedDayKind.half ? _half : null,
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
        source: RedDaySource.manual,
      );

      await widget.holidayService.upsertPersonalRedDay(redDay);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRedDay != null 
                ? 'Red day updated' 
                : 'Red day added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving red day: $e'),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Red Day?'),
        content: const Text('This will remove the personal red day marker from this date.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.holidayService.deletePersonalRedDay(widget.date);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Red day removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing red day: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, MMMM d, y').format(widget.date);
    final redDayInfo = widget.holidayService.getRedDayInfo(widget.date);
    final isEditing = widget.existingRedDay != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.event_busy,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(isEditing ? 'Edit Red Day' : 'Mark as Red Day'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(dateStr)),
                ],
              ),
            ),

            // Show auto holiday notice if applicable
            if (redDayInfo.isAutoHoliday) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Auto',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        redDayInfo.autoHolidayName ?? 'Public Holiday',
                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Kind selector
            Text(
              'Duration',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<RedDayKind>(
              segments: const [
                ButtonSegment(
                  value: RedDayKind.full,
                  label: Text('Full Day'),
                  icon: Icon(Icons.calendar_today),
                ),
                ButtonSegment(
                  value: RedDayKind.half,
                  label: Text('Half Day'),
                  icon: Icon(Icons.timelapse),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) {
                setState(() {
                  _kind = selection.first;
                  if (_kind == RedDayKind.half && _half == null) {
                    _half = HalfDay.am;
                  }
                });
              },
            ),

            // Half day selector (only if half)
            if (_kind == RedDayKind.half) ...[
              const SizedBox(height: 12),
              SegmentedButton<HalfDay>(
                segments: const [
                  ButtonSegment(
                    value: HalfDay.am,
                    label: Text('Morning (AM)'),
                  ),
                  ButtonSegment(
                    value: HalfDay.pm,
                    label: Text('Afternoon (PM)'),
                  ),
                ],
                selected: {_half ?? HalfDay.am},
                onSelectionChanged: (selection) {
                  setState(() => _half = selection.first);
                },
              ),
            ],

            const SizedBox(height: 20),

            // Reason field
            Text(
              'Reason (optional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Personal day, Appointment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        // Delete button (only if editing)
        if (isEditing)
          TextButton(
            onPressed: _isLoading ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
