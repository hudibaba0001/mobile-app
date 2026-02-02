import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../providers/time_provider.dart';
import '../providers/contract_provider.dart';
import '../providers/entry_provider.dart';
import '../l10n/generated/app_localizations.dart';

/// Flexsaldo card for the Home screen.
///
/// Shows:
/// - Balance Today (year-to-date + opening balance) as headline
/// - This month balance as secondary
/// - Starting balance (if != 0)
/// - Progress bar for current month
class FlexsaldoCard extends StatelessWidget {
  const FlexsaldoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    // Watch EntryProvider to rebuild when entries change
    // (TimeProvider methods read directly from EntryProvider.entries)
    context.watch<EntryProvider>();

    return Consumer2<TimeProvider, ContractProvider>(
      builder: (context, timeProvider, contractProvider, _) {
        final now = DateTime.now();
        final year = now.year;
        final month = now.month;
        final monthName = DateFormat.MMMM(Localizations.localeOf(context).toString()).format(now);

        // === MONTHLY VALUES (for secondary display) ===
        final monthActualMinutes = timeProvider.monthActualMinutesToDate(year, month);
        final monthCreditMinutes = timeProvider.monthCreditMinutesToDate(year, month);
        final monthTargetMinutesToDate = timeProvider.monthTargetMinutesToDate(year, month);
        final monthWorkedPlusCredited = monthActualMinutes + monthCreditMinutes;
        final monthBalanceMinutes = monthWorkedPlusCredited - monthTargetMinutesToDate;
        final monthBalanceHours = monthBalanceMinutes / 60.0;

        // Full month target for display (not just to-date)
        final fullMonthTargetHours = timeProvider.monthlyTargetHours(year: year, month: month);

        // === YEAR-TO-DATE VALUES ===
        final yearActualMinutes = timeProvider.yearActualMinutesToDate(year);
        final yearCreditMinutes = timeProvider.yearCreditMinutesToDate(year);
        final yearTargetMinutes = timeProvider.yearTargetMinutesToDate(year);
        final yearAdjustmentMinutes = timeProvider.yearAdjustmentMinutesToDate(year);

        // Year net balance (without opening balance)
        final yearNetMinutes = yearActualMinutes + yearCreditMinutes + yearAdjustmentMinutes - yearTargetMinutes;

        // === BALANCE TODAY (year-to-date + opening balance) ===
        final openingMinutes = contractProvider.openingFlexMinutes;
        final balanceTodayMinutes = yearNetMinutes + openingMinutes;
        final balanceTodayHours = balanceTodayMinutes / 60.0;

        // Progress for month (use full month target for meaningful progress display)
        final fullMonthTargetMinutes = fullMonthTargetHours * 60;
        final monthProgress = fullMonthTargetMinutes > 0
            ? (monthWorkedPlusCredited / fullMonthTargetMinutes).clamp(0.0, 1.5)
            : 0.0;

        // Colors based on balance today (headline)
        final isPositive = balanceTodayMinutes >= 0;
        final balanceColor = isPositive
            ? FlexsaldoColors.positive
            : FlexsaldoColors.negative;
        final balanceBackgroundColor = isPositive
            ? FlexsaldoColors.positiveLight
            : FlexsaldoColors.negativeLight;

        // Format headline: Balance Today
        final balanceTodayText = isPositive
            ? '+${balanceTodayHours.toStringAsFixed(1)} h'
            : '${balanceTodayHours.toStringAsFixed(1)} h';

        // Format monthly balance for secondary line
        final isMonthPositive = monthBalanceMinutes >= 0;
        final monthBalanceText = isMonthPositive
            ? '+${monthBalanceHours.toStringAsFixed(1)}h'
            : '${monthBalanceHours.toStringAsFixed(1)}h';

        // Format values for progress text (no "h" suffix - localization adds it)
        final workedText = (monthWorkedPlusCredited / 60.0).toStringAsFixed(1);
        final targetText = (monthTargetMinutesToDate / 60.0).toStringAsFixed(1);

        return Container(
          key: const Key('card_balance'),
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
              // Header row with Balance Today as headline
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: AppIconSize.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    t.balance_balanceToday,
                    style: AppTypography.sectionTitle(
                      theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Balance Today pill (headline value)
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
                      balanceTodayText,
                      style: AppTypography.headline(balanceColor).copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Secondary: This month balance vs target
              Row(
                children: [
                  Text(
                    '$monthName: ',
                    style: AppTypography.body(
                      theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    monthBalanceText,
                    style: AppTypography.body(
                      isMonthPositive
                          ? FlexsaldoColors.positive
                          : FlexsaldoColors.negative,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ' vs ${fullMonthTargetHours.toStringAsFixed(0)}h target',
                    style: AppTypography.body(
                      theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Starting balance (only if != 0)
              if (contractProvider.hasOpeningBalance) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.balance_startingBalanceValue(contractProvider.openingFlexFormatted),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Worked vs Target for month (special-case zero target-to-date)
              if (monthTargetMinutesToDate == 0) ...[
                Text(
                  t.home_targetToDateZero('0'),
                  style: AppTypography.body(
                    theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.home_loggedHours(workedText),
                  style: AppTypography.body(
                    theme.colorScheme.onSurfaceVariant,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ] else ...[
                Text(
                  t.balance_hoursWorked(workedText, targetText),
                  style: AppTypography.body(
                    theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Progress bar for month
              ClipRRect(
                borderRadius: AppRadius.chipRadius,
                child: LinearProgressIndicator(
                  value: monthProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPositive ? FlexsaldoColors.positive : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
