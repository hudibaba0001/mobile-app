import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_red_day.dart';
import '../services/holiday_service.dart';
import '../l10n/generated/app_localizations.dart';

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
    final t = AppLocalizations.of(context);
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
                ? t.redDay_updated
                : t.redDay_added),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_errorSaving(e.toString())),
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
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.redDay_removeTitle),
        content: Text(t.redDay_removeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(t.redDay_remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.holidayService
          .deletePersonalRedDay(widget.existingRedDay?.date ?? widget.date);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_removed),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_errorRemoving(e.toString())),
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
    final t = AppLocalizations.of(context);
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
            child:
                Text(isEditing ? t.redDay_editRedDay : t.redDay_markAsRedDay),
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
                  Icon(Icons.calendar_today,
                      size: 20, color: theme.colorScheme.primary),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.redDay_auto,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        redDayInfo.autoHolidayName ?? t.redDay_publicHoliday,
                        style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Kind selector
            Text(
              t.redDay_duration,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<RedDayKind>(
              segments: [
                ButtonSegment(
                  value: RedDayKind.full,
                  label: Text(t.redDay_fullDay),
                  icon: const Icon(Icons.calendar_today),
                ),
                ButtonSegment(
                  value: RedDayKind.half,
                  label: Text(t.redDay_halfDay),
                  icon: const Icon(Icons.timelapse),
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
                segments: [
                  ButtonSegment(
                    value: HalfDay.am,
                    label: Text(t.redDay_morningAM),
                  ),
                  ButtonSegment(
                    value: HalfDay.pm,
                    label: Text(t.redDay_afternoonPM),
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
              t.form_notesOptional,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: t.redDay_reasonHint,
                border: const OutlineInputBorder(),
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
            child: Text(t.redDay_remove),
          ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(t.common_cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? t.adjustment_update : t.common_save),
        ),
      ],
    );
  }
}
