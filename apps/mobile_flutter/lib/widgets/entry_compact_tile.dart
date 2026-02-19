import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/entry.dart';

class EntryCompactTile extends StatelessWidget {
  const EntryCompactTile({
    super.key,
    required this.entry,
    this.onTap,
    this.showDate = true,
    this.showNote = true,
    this.dense = true,
  });

  final Entry entry;
  final VoidCallback? onTap;
  final bool showDate;
  final bool showNote;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isWork = entry.type == EntryType.work;
    final leadingTintBase = isWork ? AppColors.success : colorScheme.primary;
    final leadingIcon =
        isWork ? Icons.work_outline_rounded : Icons.directions_car_rounded;
    final titleLabel = isWork ? t.entry_work : t.entry_travel;
    final subtitle = _buildSubtitle(t, locale);
    final meta = _buildMeta(locale);
    final horizontalPadding = dense ? AppSpacing.md : AppSpacing.lg;
    final verticalPadding = dense ? 10.0 : 12.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: leadingTintBase.withValues(alpha: 0.18),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: dense ? 68 : 76),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: leadingTintBase.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 18,
                      color: leadingTintBase,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                titleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _DurationPill(
                              text: _formatDurationMinutes(
                                entry.totalDuration.inMinutes,
                              ),
                              tint: leadingTintBase,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: AppSpacing.xs / 2),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(AppLocalizations t, String locale) {
    if (entry.type == EntryType.work) {
      final timeRange = _formatTimeRange(locale);
      if (timeRange.isEmpty) return t.history_work;
      final breakMinutes = _totalBreakMinutes();
      if (breakMinutes > 0) {
        return '$timeRange \u2022 Break ${breakMinutes}m';
      }
      return timeRange;
    }

    final route = _travelRoute();
    if (route != null) return route;
    return t.history_travel;
  }

  String? _buildMeta(String locale) {
    final parts = <String>[];
    if (showDate) {
      parts.add(_formatDate(entry.date, locale));
    }
    if (showNote) {
      final note = entry.notes?.trim();
      if (note != null && note.isNotEmpty) {
        parts.add(note);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join(' \u2022 ');
  }

  String _formatDurationMinutes(int minutes) {
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final hours = safeMinutes ~/ 60;
    final remainder = safeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainder}m';
    }
    return '${remainder}m';
  }

  String _formatTimeRange(String locale) {
    final shifts = entry.shifts;
    if (shifts == null || shifts.isEmpty) return '';
    final first = shifts.first;
    final last = shifts.last;
    final formatter = DateFormat('HH:mm', locale);
    return '${formatter.format(first.start)}\u2013${formatter.format(last.end)}';
  }

  String _formatDate(DateTime date, String locale) {
    return DateFormat.yMMMd(locale).format(date);
  }

  String? _travelRoute() {
    if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
      final first = entry.travelLegs!.first;
      final last = entry.travelLegs!.last;
      if (first.fromText.trim().isNotEmpty && last.toText.trim().isNotEmpty) {
        return '${first.fromText} \u2192 ${last.toText}';
      }
    }

    final from = entry.from?.trim() ?? '';
    final to = entry.to?.trim() ?? '';
    if (from.isNotEmpty && to.isNotEmpty) {
      return '$from \u2192 $to';
    }
    return null;
  }

  int _totalBreakMinutes() {
    final shifts = entry.shifts;
    if (shifts == null || shifts.isEmpty) return 0;
    return shifts.fold<int>(0, (sum, shift) => sum + shift.unpaidBreakMinutes);
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.text,
    required this.tint,
  });

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
