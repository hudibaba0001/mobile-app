import 'package:flutter/material.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/travel_segment.dart';

class TravelSegmentCard extends StatelessWidget {
  final TravelSegment segment;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLast;

  const TravelSegmentCard({
    super.key,
    required this.segment,
    required this.index,
    this.onEdit,
    this.onDelete,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.multiSegment_journeySegments} ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${segment.departure} â†’ ${segment.arrival}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: t.common_edit,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    tooltip: t.common_delete,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${segment.durationMinutes} ${t.entry_minutes.toLowerCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (segment.info?.isNotEmpty == true) ...[
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      segment.info!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (!isLast) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
