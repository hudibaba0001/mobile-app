import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/app_theme.dart';
import '../models/entry.dart'; // Updated to use unified Entry model
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';

class TravelEntryCard extends StatefulWidget {
  final Entry entry; // Updated to use Entry model
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;
  final bool showDate;

  const TravelEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
    this.showDate = true,
  });

  @override
  State<TravelEntryCard> createState() => _TravelEntryCardState();
}

class _TravelEntryCardState extends State<TravelEntryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  String get _formattedDuration {
    final minutes = widget.entry.travelMinutes ??
        0; // Entry uses 'travelMinutes' instead of 'minutes'
    final duration = Duration(minutes: minutes);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Color get _durationColor {
    final minutes = widget.entry.travelMinutes ??
        0; // Entry uses 'travelMinutes' instead of 'minutes'
    if (minutes < 30) {
      return AppColors.success;
    } else if (minutes < 60) {
      return AppColors.accent;
    } else if (minutes < 120) {
      return AppColors.error;
    } else {
      return AppColors.secondary;
    }
  }

  IconData get _routeIcon {
    // Show route icon for multi-segment journeys
    if (widget.entry.journeyId != null) {
      return Icons.route;
    }

    final departure = (widget.entry.from ?? '')
        .toLowerCase(); // Entry uses 'from' instead of 'departure'
    final arrival = (widget.entry.to ?? '')
        .toLowerCase(); // Entry uses 'to' instead of 'arrival'

    if (departure.contains('home') || arrival.contains('home')) {
      return Icons.home;
    } else if (departure.contains('office') ||
        arrival.contains('office') ||
        departure.contains('work') ||
        arrival.contains('work')) {
      return Icons.business;
    } else if (departure.contains('airport') || arrival.contains('airport')) {
      return Icons.flight;
    } else if (departure.contains('station') || arrival.contains('station')) {
      return Icons.train;
    } else {
      return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onTap != null ? _onTapDown : null,
            onTapUp: widget.onTap != null ? _onTapUp : null,
            onTapCancel: widget.onTap != null ? _onTapCancel : null,
            onTap: widget.onTap,
            child: Card(
              margin: EdgeInsets.symmetric(
                vertical: widget.isCompact ? 2 : 4,
                horizontal: 0,
              ),
              elevation: _isPressed ? 8 : 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1),
                  ),
                ),
                child: widget.isCompact
                    ? _buildCompactContent()
                    : _buildFullContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Route icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.md - 2),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Icon(
              _routeIcon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Route info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.entry.from ?? 'Unknown'} → ${widget.entry.to ?? 'Unknown'}', // Entry uses 'from' and 'to'
                  style: AppTypography.body(colorScheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.showDate)
                  Text(
                    DateFormat(AppConstants.displayDateFormat)
                        .format(widget.entry.date),
                    style: AppTypography.caption(onSurfaceVariant),
                  ),
              ],
            ),
          ),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _durationColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _formattedDuration,
              style: AppTypography.caption(_durationColor)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          // Actions
          if (widget.showActions)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    widget.onEdit?.call();
                    break;
                  case 'delete':
                    widget.onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit, size: 20),
                    title: Text(AppLocalizations.of(context).common_edit),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading:
                        Icon(Icons.delete, color: colorScheme.error, size: 20),
                    title: Text(AppLocalizations.of(context).common_delete,
                        style: AppTypography.body(colorScheme.error)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildFullContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Route icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.md - 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Icon(
                  _routeIcon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Date and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showDate)
                      Text(
                        DateFormat(AppConstants.displayDateFormat)
                            .format(widget.entry.date),
                        style: AppTypography.body(onSurfaceVariant),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: _durationColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formattedDuration,
                          style: AppTypography.sectionTitle(_durationColor)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (widget.showActions)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEdit?.call();
                        break;
                      case 'delete':
                        widget.onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(AppLocalizations.of(context).common_edit),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: colorScheme.error),
                        title: Text(AppLocalizations.of(context).common_delete,
                            style: AppTypography.body(colorScheme.error)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Route details
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                // Departure
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.entry.from ??
                            'Unknown', // Entry uses 'from' instead of 'departure'
                        style: AppTypography.body(colorScheme.onSurface)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                // Route line
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 1,
                        height: 20,
                        color: onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: AppSpacing.sm - 1),
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: onSurfaceVariant,
                      ),
                    ],
                  ),
                ),

                // Arrival
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.entry.to ??
                            'Unknown', // Entry uses 'to' instead of 'arrival'
                        style: AppTypography.body(colorScheme.onSurface)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Additional info
          if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
            // Entry uses 'notes' instead of 'info'
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget
                          .entry.notes!, // Entry uses 'notes' instead of 'info'
                      style: AppTypography.body(colorScheme.primary)
                          .copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Multi-segment journey indicator
          if (widget.entry.journeyId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Segment ${widget.entry.segmentOrder}/${widget.entry.totalSegments}',
                    style: AppTypography.caption(colorScheme.primary).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Metadata
          if (widget.entry.createdAt != widget.entry.date) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: onSurfaceVariant.withValues(alpha: 0.85),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Logged ${DateFormat('MMM dd, HH:mm').format(widget.entry.createdAt)}',
                  style: AppTypography.caption(onSurfaceVariant).copyWith(
                    fontSize: 11,
                  ),
                ),
                if (widget.entry.updatedAt != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Updated ${DateFormat('MMM dd, HH:mm').format(widget.entry.updatedAt!)}',
                    style: AppTypography.caption(onSurfaceVariant).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
