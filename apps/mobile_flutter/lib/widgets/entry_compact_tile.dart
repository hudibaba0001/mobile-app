import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/entry.dart';

class EntryCompactTile extends StatefulWidget {
  const EntryCompactTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.showDate = true,
    this.showNote = true,
    this.dense = true,
    this.heroTag,
  });

  final Entry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDate;
  final bool showNote;
  final bool dense;
  final String? heroTag;

  @override
  State<EntryCompactTile> createState() => _EntryCompactTileState();
}

class _EntryCompactTileState extends State<EntryCompactTile> {
  bool _pressed = false;

  void _handleLongPress() {
    HapticFeedback.lightImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isWork = widget.entry.type == EntryType.work;
    final leadingTintBase = isWork ? AppColors.success : colorScheme.primary;
    final leadingIcon =
        isWork ? Icons.work_outline_rounded : Icons.directions_car_rounded;
    final titleLabel = isWork ? t.entry_work : t.entry_travel;
    final subtitle = _buildSubtitle(t, locale);
    final meta = _buildMeta(locale);
    final horizontalPadding = widget.dense ? AppSpacing.md : AppSpacing.lg;
    final verticalPadding = widget.dense ? 10.0 : 12.0;
    final heroTag = widget.heroTag;

    Widget tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: leadingTintBase.withValues(alpha: 0.18),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress == null ? null : _handleLongPress,
            onHighlightChanged: (value) {
              if (_pressed == value) return;
              setState(() => _pressed = value);
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.dense ? 68 : 76),
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
                                  widget.entry.totalDuration.inMinutes,
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
      ),
    );

    if (heroTag != null) {
      tile = Hero(
        tag: heroTag,
        flightShuttleBuilder: (context, animation, direction, from, to) {
          return ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1).animate(animation),
            child: to.widget,
          );
        },
        child: tile,
      );
    }

    return tile;
  }

  String _buildSubtitle(AppLocalizations t, String locale) {
    if (widget.entry.type == EntryType.work) {
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
    if (widget.showDate) {
      parts.add(_formatDate(widget.entry.date, locale));
    }
    if (widget.showNote) {
      final note = widget.entry.notes?.trim();
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
    final shifts = widget.entry.shifts;
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
    if (widget.entry.travelLegs != null &&
        widget.entry.travelLegs!.isNotEmpty) {
      final first = widget.entry.travelLegs!.first;
      final last = widget.entry.travelLegs!.last;
      if (first.fromText.trim().isNotEmpty && last.toText.trim().isNotEmpty) {
        return '${first.fromText} \u2192 ${last.toText}';
      }
    }

    final from = widget.entry.from?.trim() ?? '';
    final to = widget.entry.to?.trim() ?? '';
    if (from.isNotEmpty && to.isNotEmpty) {
      return '$from \u2192 $to';
    }
    return null;
  }

  int _totalBreakMinutes() {
    final shifts = widget.entry.shifts;
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
