import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../l10n/generated/app_localizations.dart';

class EntryDetailSheet extends StatelessWidget {
  final Entry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EntryDetailSheet({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.type == EntryType.travel
                        ? Icons.directions_car_rounded
                        : Icons.work_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _titleFor(context, entry),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  entry.formattedDuration,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outline.withOpacity(0.2)),
            const SizedBox(height: 8),
            ..._detailWidgets(context, entry),
            const SizedBox(height: 20),
            Builder(builder: (context) {
              final t = AppLocalizations.of(context);
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(t.common_edit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(t.common_delete),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _titleFor(BuildContext context, Entry e) {
    if (e.type == EntryType.travel) {
      return 'Travel: ${e.from ?? ''} → ${e.to ?? ''}'.trim();
    }
    return AppLocalizations.of(context).entryDetail_workSession;
  }

  List<Widget> _detailWidgets(BuildContext context, Entry e) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = <Widget>[];

    items.add(_kv(theme, 'Date', _formatDate(e.date)));

    if (e.type == EntryType.travel) {
      items.addAll([
        _kv(theme, 'From', e.from ?? '-'),
        _kv(theme, 'To', e.to ?? '-'),
        _kv(theme, 'Duration', e.formattedDuration),
      ]);
    } else {
      final shifts = e.shifts ?? [];
      if (shifts.isEmpty) {
        items.add(_kv(theme, 'Shifts', '-'));
      } else {
        for (var i = 0; i < shifts.length; i++) {
          final s = shifts[i];
          items.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).edit_shift(i + 1),
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTime(s.start)} - ${_formatTime(s.end)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDuration(s.duration),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      items.add(_kv(theme, 'Total', e.formattedDuration));
    }

    if ((e.notes ?? '').isNotEmpty) {
      items.add(_kv(theme, 'Notes', e.notes!));
    }

    items.addAll([
      _kv(theme, 'Created', _formatDateTime(e.createdAt)),
      if (e.updatedAt != null)
        _kv(theme, 'Updated', _formatDateTime(e.updatedAt!)),
    ]);

    return items;
  }

  Widget _kv(ThemeData theme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _formatDateTime(DateTime d) {
    return '${_formatDate(d)} ${_formatTime(d)}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}
