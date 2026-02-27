import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../design/components/components.dart';
import '../models/user_red_day.dart';
import '../providers/network_status_provider.dart';
import '../services/holiday_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/error_message_mapper.dart';

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
    final isOffline =
        context.read<NetworkStatusProvider?>()?.isOffline ?? false;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_offlineEditBlockedMessage(t)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
        final colorScheme = Theme.of(context).colorScheme;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRedDay != null
                ? t.redDay_updated
                : t.redDay_added),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_errorSaving(ErrorMessageMapper.userMessage(
              e,
              t,
            ))),
            backgroundColor: colorScheme.error,
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
    final isOffline =
        context.read<NetworkStatusProvider?>()?.isOffline ?? false;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_offlineEditBlockedMessage(t)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
              backgroundColor:
                  Theme.of(dialogContext).colorScheme.errorContainer,
              foregroundColor:
                  Theme.of(dialogContext).colorScheme.onErrorContainer,
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
        final colorScheme = Theme.of(context).colorScheme;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_removed),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.redDay_errorRemoving(
              ErrorMessageMapper.userMessage(e, t),
            )),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _offlineEditBlockedMessage(AppLocalizations t) {
    if (t.localeName.toLowerCase().startsWith('sv')) {
      return 'Du ar offline. Anslut till internet for att redigera roda dagar.';
    }
    return "You're offline. Connect to edit red days.";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('EEEE, MMMM d, y').format(widget.date);
    final redDayInfo = widget.holidayService.getRedDayInfo(widget.date);
    final isEditing = widget.existingRedDay != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.event_busy,
            color: colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.md),
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
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(dateStr)),
                ],
              ),
            ),

            // Show auto holiday notice if applicable
            if (redDayInfo.isAutoHoliday) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                      ),
                      child: Text(
                        t.redDay_auto,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutral50,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        redDayInfo.autoHolidayName ?? t.redDay_publicHoliday,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Kind selector
            Text(
              t.redDay_duration,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),
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

            const SizedBox(height: AppSpacing.xl),

            // Reason field
            Text(
              t.form_notesOptional,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _reasonController,
              hintText: t.redDay_reasonHint,
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
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(t.redDay_remove),
          ),
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
