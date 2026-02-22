import 'package:flutter/material.dart';
import '../app_theme.dart';

/// A styled card with consistent padding and decoration.
///
/// Use this as the primary container for grouped content.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = widget.color ??
        (isDark ? AppColors.darkSurfaceElevated : theme.colorScheme.surface);

    final effectiveRadius = widget.borderRadius ?? AppRadius.cardRadius;

    Widget cardContent = Container(
      padding: widget.padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (isHighlighted) {
            if (isHighlighted) {
              _scaleController.reverse(); // Animate to 0.96 scale
            } else {
              _scaleController.forward(); // Animate back to 1.0 scale
            }
          },
          borderRadius: effectiveRadius,
          child: cardContent,
        ),
      );
    }

    Widget finalWidget = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: cardContent,
    );

    if (widget.onTap != null) {
      // Wrap with ScaleTransition only if it's tappable
      finalWidget = ScaleTransition(
        scale: _scaleController,
        child: finalWidget,
      );
    }

    return finalWidget;
  }
}

/// Section header with optional trailing action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.xl,
            bottom: AppSpacing.md,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionTitle(
              theme.colorScheme.onSurface,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A row displaying a metric value with icon and label.
class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metricValue(
              valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pill-shaped badge showing status.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  /// Factory for positive status (muted green)
  factory StatusPill.positive(String label, {IconData? icon}) {
    return StatusPill(
      label: label,
      color: FlexsaldoColors.positive,
      icon: icon,
    );
  }

  /// Factory for negative status (muted amber)
  factory StatusPill.negative(String label, {IconData? icon}) {
    return StatusPill(
      label: label,
      color: FlexsaldoColors.negative,
      icon: icon,
    );
  }

  /// Factory for neutral status
  factory StatusPill.neutral(String label, {IconData? icon}) {
    return StatusPill(
      label: label,
      color: FlexsaldoColors.neutral,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillColor = color ?? theme.colorScheme.primary;
    final backgroundColor = pillColor.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppIconSize.xs,
              color: pillColor,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(pillColor).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state placeholder with icon and message.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppIconSize.xl,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.sectionTitle(
                theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTypography.body(
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
