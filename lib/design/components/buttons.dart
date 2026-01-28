import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Primary button - for main actions.
/// 
/// Filled style, prominent appearance.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonChild = isLoading
        ? SizedBox(
            width: AppIconSize.sm,
            height: AppIconSize.sm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.sm),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
        minimumSize: isExpanded ? const Size.fromHeight(48) : null,
      ),
      child: buttonChild,
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary button - for supporting actions.
/// 
/// Outlined style, less prominent than primary.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonChild = isLoading
        ? SizedBox(
            width: AppIconSize.sm,
            height: AppIconSize.sm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.sm),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 1,
        ),
        minimumSize: isExpanded ? const Size.fromHeight(48) : null,
      ),
      child: buttonChild,
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tertiary button - for subtle actions.
/// 
/// Text-only style, minimal visual weight.
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Quick action chip for fast input (e.g., +2h, +4h).
class QuickChip extends StatelessWidget {
  const QuickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: isSelected 
          ? theme.colorScheme.primaryContainer 
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.chipRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.chipRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppIconSize.xs,
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.button(
                  isSelected 
                      ? theme.colorScheme.onPrimaryContainer 
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
