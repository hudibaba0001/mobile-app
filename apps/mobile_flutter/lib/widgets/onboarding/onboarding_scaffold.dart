import 'package:flutter/material.dart';
import '../../design/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../language_toggle_action.dart';
import '../standard_app_bar.dart';

class OnboardingScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final int? step;
  final int? totalSteps;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const OnboardingScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.step,
    this.totalSteps,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final resolvedActions = actions ?? const [LanguageToggleAction()];
    final showStep = step != null &&
        totalSteps != null &&
        totalSteps! > 0 &&
        step! > 0;
    final normalizedStep = showStep ? step!.clamp(1, totalSteps!) : null;
    final progressValue = showStep ? normalizedStep! / totalSteps! : null;

    final headerChildren = <Widget>[];
    if (showStep) {
      headerChildren.add(
        Text(
          t.onboarding_stepIndicator(normalizedStep!, totalSteps!),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      headerChildren.add(const SizedBox(height: AppSpacing.sm));
      headerChildren.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 4,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            color: theme.colorScheme.primary,
          ),
        ),
      );
      headerChildren.add(const SizedBox(height: AppSpacing.lg));
    }

    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      headerChildren.add(
        Text(
          subtitle!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
      headerChildren.add(const SizedBox(height: AppSpacing.xl));
    }

    headerChildren.add(child);

    final showBottomActions =
        primaryLabel != null || secondaryLabel != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: StandardAppBar(
        title: title,
        showBackButton: showBack,
        onBack: onBack,
        actions: resolvedActions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: headerChildren,
                    ),
                  ),
                ),
              ),
            ),
            if (showBottomActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Row(
                        children: [
                          if (secondaryLabel != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onSecondary,
                                child: Text(secondaryLabel!),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          if (primaryLabel != null)
                            Expanded(
                              child: FilledButton(
                                onPressed: onPrimary,
                                child: Text(primaryLabel!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
