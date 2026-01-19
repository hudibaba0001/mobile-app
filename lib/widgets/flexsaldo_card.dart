import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../providers/time_provider.dart';
import '../l10n/generated/app_localizations.dart';

/// Flexsaldo Month-to-Date card for the Home screen.
/// 
/// Shows:
/// - Current flex balance (+X.X h or -X.X h)
/// - Worked + credited vs Target
/// - Progress bar
/// - Export buttons (Time report, Travel report)
class FlexsaldoCard extends StatelessWidget {
  const FlexsaldoCard({
    super.key,
    this.onExportTimeReport,
    this.onExportTravelReport,
  });

  final VoidCallback? onExportTimeReport;
  final VoidCallback? onExportTravelReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    
    return Consumer<TimeProvider>(
      builder: (context, timeProvider, _) {
        final now = DateTime.now();
        final year = now.year;
        final month = now.month;
        
        // Get MTD values
        final actualMinutes = timeProvider.monthActualMinutesToDate(year, month);
        final creditMinutes = timeProvider.monthCreditMinutesToDate(year, month);
        final targetMinutes = timeProvider.monthTargetMinutesToDate(year, month);
        
        final workedPlusCredited = actualMinutes + creditMinutes;
        final balanceMinutes = workedPlusCredited - targetMinutes;
        final balanceHours = balanceMinutes / 60.0;
        
        // Progress (capped at 1.0 for display)
        final progress = targetMinutes > 0 
            ? (workedPlusCredited / targetMinutes).clamp(0.0, 1.5)
            : 0.0;
        
        // Colors based on balance
        final isPositive = balanceMinutes >= 0;
        final balanceColor = isPositive 
            ? FlexsaldoColors.positive 
            : FlexsaldoColors.negative;
        final balanceBackgroundColor = isPositive
            ? FlexsaldoColors.positiveLight
            : FlexsaldoColors.negativeLight;
        
        // Format values
        final balanceText = isPositive 
            ? '+${balanceHours.toStringAsFixed(1)} h'
            : '${balanceHours.toStringAsFixed(1)} h';
        final workedText = '${(workedPlusCredited / 60.0).toStringAsFixed(1)} h';
        final targetText = '${(targetMinutes / 60.0).toStringAsFixed(1)} h';
        
        return Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? AppColors.darkSurfaceElevated
                : theme.colorScheme.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: AppIconSize.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    t.balance_title,
                    style: AppTypography.sectionTitle(
                      theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Balance pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: balanceBackgroundColor,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      balanceText,
                      style: AppTypography.headline(balanceColor).copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Worked vs Target
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.balance_hoursWorked(workedText, targetText),
                          style: AppTypography.body(
                            theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Progress bar
              ClipRRect(
                borderRadius: AppRadius.chipRadius,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPositive ? FlexsaldoColors.positive : theme.colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Export buttons
              Row(
                children: [
                  Expanded(
                    child: _ExportButton(
                      icon: Icons.access_time_rounded,
                      label: 'Export Time',
                      onTap: onExportTimeReport,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ExportButton(
                      icon: Icons.directions_car_rounded,
                      label: 'Export Travel',
                      onTap: onExportTravelReport,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: AppRadius.buttonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppIconSize.xs,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button(theme.colorScheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
