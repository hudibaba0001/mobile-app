import 'package:flutter/material.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segment ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${segment.departure} → ${segment.arrival}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit segment',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete segment',
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${segment.durationMinutes} minutes',
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
                  const SizedBox(width: 4),
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
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
