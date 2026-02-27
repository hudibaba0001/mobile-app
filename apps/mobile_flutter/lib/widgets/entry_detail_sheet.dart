import 'package:flutter/material.dart';
import '../design/app_theme.dart';
import '../models/entry.dart';
import '../l10n/generated/app_localizations.dart';

class EntryDetailSheet extends StatelessWidget {
  final Entry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? heroTag;

  const EntryDetailSheet({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget sheet = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md - 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      entry.type == EntryType.travel
                          ? Icons.directions_car_rounded
                          : Icons.work_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _detailWidgets(context, entry),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
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
                    const SizedBox(width: AppSpacing.md),
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
      ),
    );

    if (heroTag != null) {
      sheet = Hero(
        tag: heroTag!,
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          child: sheet,
        ),
      );
    }

    return sheet;
  }

  String _titleFor(BuildContext context, Entry e) {
    if (e.type == EntryType.travel) {
      return 'Travel: ${e.from ?? ''} â†’ ${e.to ?? ''}'.trim();
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
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).edit_shift(i + 1),
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
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
