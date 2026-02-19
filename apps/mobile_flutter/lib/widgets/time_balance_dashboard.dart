import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/design.dart';
import '../reporting/time_format.dart';
import '../l10n/generated/app_localizations.dart';

/// Dashboard widget for displaying time balance information
/// Shows current month status and yearly balance with Material 3 styling
class TimeBalanceDashboard extends StatelessWidget {
  final int currentMonthMinutes;
  final int currentYearMinutes;
  final int yearNetMinutes; // Year-only balance (no opening balance)
  final int?
      contractBalanceMinutes; // Optional: lifetime/contract balance with opening
  final int targetMinutes; // Full month target (for display)
  final int targetYearlyMinutes; // Full year target (for display)
  final int?
      targetMinutesToDate; // Month target to date (for variance calculations)
  final int?
      targetYearlyMinutesToDate; // Year target to date (for variance calculations)
  final String currentMonthName;
  final int currentYear;
  final int? creditMinutes; // Optional: paid absence credits for month
  final int? yearCreditMinutes; // Optional: paid absence credits for year
  final String? openingBalanceFormatted; // e.g., "+12h 30m" for opening balance
  final DateTime? trackingStartDate; // Date from which tracking started
  final int monthlyAdjustmentMinutes;
  final int yearlyAdjustmentMinutes;
  final int openingBalanceMinutes;
  final bool
      showYearLoggedSince; // Whether to show "Logged since..." for year card
  final bool
      showMonthLoggedSince; // Whether to show "Logged since..." for month card

  const TimeBalanceDashboard({
    super.key,
    required this.currentMonthMinutes,
    required this.currentYearMinutes,
    required this.yearNetMinutes,
    required this.targetMinutes,
    required this.targetYearlyMinutes,
    required this.currentMonthName,
    required this.currentYear,
    required this.monthlyAdjustmentMinutes,
    required this.yearlyAdjustmentMinutes,
    required this.openingBalanceMinutes,
    this.contractBalanceMinutes,
    this.targetMinutesToDate,
    this.targetYearlyMinutesToDate,
    this.creditMinutes,
    this.yearCreditMinutes,
    this.openingBalanceFormatted,
    this.trackingStartDate,
    this.showYearLoggedSince = false,
    this.showMonthLoggedSince = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyStatusCard(
          monthName: currentMonthName,
          workedMinutes: currentMonthMinutes,
          targetMinutes: targetMinutes,
          targetMinutesToDate: targetMinutesToDate,
          creditMinutes: creditMinutes,
          adjustmentMinutes: monthlyAdjustmentMinutes,
          trackingStartDate: trackingStartDate,
          showLoggedSince: showMonthLoggedSince,
        ),
        const SizedBox(height: AppSpacing.lg),
        YearlyBalanceCard(
          year: currentYear,
          workedMinutes: currentYearMinutes,
          targetMinutes: targetYearlyMinutes,
          targetMinutesToDate: targetYearlyMinutesToDate,
          yearNetMinutes: yearNetMinutes,
          contractBalanceMinutes: contractBalanceMinutes,
          creditMinutes: yearCreditMinutes,
          adjustmentMinutes: yearlyAdjustmentMinutes,
          openingBalanceMinutes: openingBalanceMinutes,
          openingBalanceFormatted: openingBalanceFormatted,
          trackingStartDate: trackingStartDate,
          showLoggedSince: showYearLoggedSince,
        ),
      ],
    );
  }
}

/// Card displaying current month's work hours status
class MonthlyStatusCard extends StatelessWidget {
  final String monthName;
  final int workedMinutes;
  final int targetMinutes; // Full month target (for display)
  final int? targetMinutesToDate; // Target to date (for variance calculations)
  final int adjustmentMinutes;
  final int? creditMinutes; // Optional: paid absence credits
  final DateTime? trackingStartDate; // Date from which tracking started
  final bool showLoggedSince; // Whether to show "Logged since..." label

  const MonthlyStatusCard({
    super.key,
    required this.monthName,
    required this.workedMinutes,
    required this.targetMinutes,
    required this.adjustmentMinutes,
    this.targetMinutesToDate,
    this.creditMinutes,
    this.trackingStartDate,
    this.showLoggedSince = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;
    // Calculate effective minutes including credits and adjustments.
    final effectiveMinutes =
        workedMinutes + (creditMinutes ?? 0) + adjustmentMinutes;
    // Use target-to-date for variance calculation when available.
    final targetForVariance = targetMinutesToDate ?? targetMinutes;
    final varianceMinutes = effectiveMinutes - targetForVariance;
    final isOverTarget = varianceMinutes >= 0;

    // Theme-aware colors
    final positiveColor =
        isDark ? FlexsaldoColors.positive : FlexsaldoColors.positiveDark;
    final negativeColor =
        isDark ? FlexsaldoColors.negative : FlexsaldoColors.negativeDark;

    return AppCard(
      padding: AppSpacing.cardPadding * 1.5, // Slightly more padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: "This month: February"
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.balance_thisMonthLabel(monthName),
                style: AppTypography.cardTitle(theme.colorScheme.onSurface),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Line 1 (PRIMARY): Status (to date)
          Row(
            children: [
              Text(
                l10n.balance_statusToDate,
                style: AppTypography.sectionTitle(
                    theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                formatSignedMinutes(
                  varianceMinutes,
                  localeCode: localeCode,
                ),
                style: AppTypography.headline(
                  isOverTarget ? positiveColor : negativeColor,
                ).copyWith(fontSize: 28),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Line 2: Worked (to date): X.Xh / Y.Yh
          RichText(
            text: TextSpan(
              style: AppTypography.body(theme.colorScheme.onSurface)
                  .copyWith(fontSize: 16),
              children: [
                TextSpan(text: '${l10n.balance_workedToDate} '),
                TextSpan(
                  text: formatMinutes(
                    effectiveMinutes,
                    localeCode: localeCode,
                    padMinutes: true,
                  ),
                  style: AppTypography.body(theme.colorScheme.primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' / '),
                TextSpan(
                  text: formatMinutes(
                    targetForVariance,
                    localeCode: localeCode,
                    padMinutes: true,
                  ),
                  style: AppTypography.body(theme.colorScheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Line 3 (small): Full month target: XXXh
          Text(
            l10n.balance_fullMonthTargetValue(
              formatMinutes(
                targetMinutes,
                localeCode: localeCode,
                padMinutes: true,
              ),
            ),
            style: AppTypography.caption(
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ).copyWith(fontWeight: FontWeight.w500),
          ),

          // Show credits and adjustments if any
          if (creditMinutes != null && creditMinutes! > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.balance_creditedPaidLeaveValue(
                formatMinutes(
                  creditMinutes!,
                  localeCode: localeCode,
                  padMinutes: true,
                ),
              ),
              style: AppTypography.caption(
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (adjustmentMinutes != 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.balance_manualAdjustmentsValue(
                formatSignedMinutes(
                  adjustmentMinutes,
                  localeCode: localeCode,
                ),
              ),
              style: AppTypography.caption(
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],

          // Show "Logged since..." when tracking started mid-month
          if (showLoggedSince && trackingStartDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context).balance_loggedSince(
                DateFormat('d MMM').format(trackingStartDate!),
              ),
              style: AppTypography.caption(theme.colorScheme.tertiary).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Card displaying yearly balance
/// Primary: "Balance Today" (includes opening balance)
/// Secondary: "Net This Year" (from logged hours only)
class YearlyBalanceCard extends StatefulWidget {
  final int year;
  final int workedMinutes;
  final int targetMinutes; // Full year target (for display)
  final int?
      targetMinutesToDate; // Year target to date (for variance calculations)
  final int
      yearNetMinutes; // Year-only balance (worked - target + adjustments, NO opening)
  final int? contractBalanceMinutes; // Balance including opening (for verification)
  final int? creditMinutes; // Optional: paid absence credits
  final int adjustmentMinutes;
  final int openingBalanceMinutes;
  final String? openingBalanceFormatted; // e.g., "+12h 30m" or "-3h 15m"
  final DateTime? trackingStartDate; // Date from which tracking started
  final bool
      showLoggedSince; // Whether to show "Logged since..." label prominently

  const YearlyBalanceCard({
    super.key,
    required this.year,
    required this.workedMinutes,
    required this.targetMinutes,
    required this.yearNetMinutes,
    required this.adjustmentMinutes,
    required this.openingBalanceMinutes,
    this.targetMinutesToDate,
    this.contractBalanceMinutes,
    this.creditMinutes,
    this.openingBalanceFormatted,
    this.trackingStartDate,
    this.showLoggedSince = false,
  });

  @override
  State<YearlyBalanceCard> createState() => _YearlyBalanceCardState();
}

class _YearlyBalanceCardState extends State<YearlyBalanceCard> {
  bool _showDetails = false;

  Widget _buildBreakdownRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
    required Color positiveColor,
    required Color negativeColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppIconSize.xs,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(theme.colorScheme.onSurfaceVariant)
                  .copyWith(fontSize: 13),
            ),
          ),
          Text(
            value,
            style:
                AppTypography.body(isPositive ? positiveColor : negativeColor)
                    .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;

    // PRIMARY: Balance Today = yearNet + opening balance.
    // This is what the user cares about: their actual flex balance right now
    final balanceTodayMinutes = widget.contractBalanceMinutes ??
        (widget.yearNetMinutes + widget.openingBalanceMinutes);
    final isPositive = balanceTodayMinutes >= 0;
    final displayBalance = formatSignedMinutes(
      balanceTodayMinutes,
      localeCode: localeCode,
    );

    // Status reflects balanceToday (the real balance)
    final isOverTarget = balanceTodayMinutes >= 0;

    // Use target-to-date for display and progress when available
    final targetForDisplay = widget.targetMinutesToDate ?? widget.targetMinutes;

    // Theme-aware colors
    final positiveColor =
        isDark ? FlexsaldoColors.positive : FlexsaldoColors.positiveDark;
    final negativeColor =
        isDark ? FlexsaldoColors.negative : FlexsaldoColors.negativeDark;
    final cardBgColor = isDark
        ? (isPositive
            ? positiveColor.withValues(alpha: 0.06)
            : negativeColor.withValues(alpha: 0.06))
        : (isPositive
            ? positiveColor.withValues(alpha: 0.04)
            : negativeColor.withValues(alpha: 0.04));

    // Show details if there's an opening balance OR adjustments to explain
    final hasDetails =
        widget.openingBalanceMinutes != 0 || widget.adjustmentMinutes != 0;

    return AppCard(
      padding: AppSpacing.cardPadding * 1.5,
      color: cardBgColor,
      // We let AppCard handle the border, or we could override it if strictly needed.
      // Ideally AppCard should be flexible enough. For now, the standard border is fine.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: THIS YEAR 2026
          Text(
            l10n.balance_thisYear(widget.year),
            style: AppTypography.cardTitle(theme.colorScheme.onSurfaceVariant)
                .copyWith(
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Worked (to date): X.Xh / Y.Yh
          RichText(
            text: TextSpan(
              style: AppTypography.body(theme.colorScheme.onSurface)
                  .copyWith(fontSize: 16),
              children: [
                TextSpan(text: '${l10n.balance_workedToDate} '),
                TextSpan(
                  text: formatMinutes(
                    widget.workedMinutes +
                        (widget.creditMinutes ?? 0) +
                        widget.adjustmentMinutes,
                    localeCode: localeCode,
                    padMinutes: true,
                  ),
                  style: AppTypography.body(theme.colorScheme.primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' / '),
                TextSpan(
                  text: formatMinutes(
                    targetForDisplay,
                    localeCode: localeCode,
                    padMinutes: true,
                  ),
                  style: AppTypography.body(theme.colorScheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Full year target
          Text(
            l10n.balance_fullYearTargetValue(
              formatMinutes(
                widget.targetMinutes,
                localeCode: localeCode,
                padMinutes: true,
              ),
            ),
            style: AppTypography.caption(
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ).copyWith(fontWeight: FontWeight.w500),
          ),

          // Show "Logged since..." prominently when tracking started after Jan 1
          if (widget.showLoggedSince && widget.trackingStartDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm - 2,
              ),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppIconSize.xs,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.balance_loggedSince(
                          DateFormat('d MMM').format(widget.trackingStartDate!),
                        ),
                        style: AppTypography.caption(
                                theme.colorScheme.onTertiaryContainer)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  // Show starting balance if there is one
                  if (widget.openingBalanceFormatted != null) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      l10n.balance_startingBalanceAsOf(
                        DateFormat('d MMM').format(widget.trackingStartDate!),
                        widget.openingBalanceFormatted!,
                      ),
                      style: AppTypography.caption(
                        theme.colorScheme.onTertiaryContainer
                            .withValues(alpha: 0.8),
                      ).copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Credit hours if any (informational)
          if (widget.creditMinutes != null && widget.creditMinutes! > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.balance_creditedHoursValue(
                formatMinutes(
                  widget.creditMinutes!,
                  localeCode: localeCode,
                  padMinutes: true,
                ),
              ),
              style: AppTypography.body(theme.colorScheme.primary),
            ),
          ],

          // Adjustments if any
          if (widget.adjustmentMinutes != 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.balance_includesAdjustmentsValue(
                formatSignedMinutes(
                  widget.adjustmentMinutes,
                  localeCode: localeCode,
                ),
              ),
              style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Balance today (avoid "Status" wording)
          Row(
            children: [
              Icon(
                isOverTarget ? Icons.check_circle : Icons.error_outline,
                size: AppIconSize.sm,
                color: isOverTarget ? positiveColor : negativeColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.balance_balanceToday}: $displayBalance',
                style: AppTypography.body(
                  isOverTarget ? positiveColor : negativeColor,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),

          // PRIMARY: Balance Today - the main number users care about
          Text(
            l10n.balance_balanceToday,
            style: AppTypography.cardTitle(theme.colorScheme.onSurfaceVariant)
                .copyWith(
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayBalance,
            style: AppTypography.headline(
              isPositive ? positiveColor : negativeColor,
            ).copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),

          // SECONDARY: Show Net This Year (logged hours only) when there's an opening balance
          if (widget.openingBalanceMinutes != 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: AppIconSize.xs,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Text(
                  l10n.balance_netThisYear(
                    formatSignedMinutes(
                      widget.yearNetMinutes,
                      localeCode: localeCode,
                    ),
                  ),
                  style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: AppIconSize.xs,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Text(
                  l10n.balance_startingBalanceValue(
                    widget.openingBalanceFormatted ??
                        formatSignedMinutes(
                          widget.openingBalanceMinutes,
                          localeCode: localeCode,
                        ),
                  ),
                  style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.balance_resetsOn('31 Dec'),
            style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)
                .copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),

          // Collapsible Details section - breakdown of balance components
          if (hasDetails) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => setState(() => _showDetails = !_showDetails),
              borderRadius: AppRadius.buttonRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      _showDetails ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.balance_details,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showDetails) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.balance_breakdown,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Starting balance row
                    if (widget.openingBalanceMinutes != 0) ...[
                      _buildBreakdownRow(
                        context,
                        icon: Icons.account_balance_wallet,
                        label: widget.trackingStartDate != null
                            ? l10n
                                .balance_startingBalanceAsOf(
                                  DateFormat('d MMM')
                                      .format(widget.trackingStartDate!),
                                  '',
                                )
                                .replaceAll(': ', '')
                            : l10n.balance_startingBalance,
                        value: widget.openingBalanceFormatted ??
                            formatSignedMinutes(
                              widget.openingBalanceMinutes,
                              localeCode: localeCode,
                            ),
                        isPositive: widget.openingBalanceMinutes >= 0,
                        positiveColor: positiveColor,
                        negativeColor: negativeColor,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Net this year row
                    _buildBreakdownRow(
                      context,
                      icon: Icons.analytics,
                      label: l10n.balance_netThisYearLabel,
                      value: formatSignedMinutes(
                        widget.yearNetMinutes,
                        localeCode: localeCode,
                      ),
                      isPositive: widget.yearNetMinutes >= 0,
                      positiveColor: positiveColor,
                      negativeColor: negativeColor,
                    ),

                    // Adjustments row (if any)
                    if (widget.adjustmentMinutes != 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildBreakdownRow(
                        context,
                        icon: Icons.tune,
                        label: l10n.balance_adjustments,
                        value: formatSignedMinutes(
                          widget.adjustmentMinutes,
                          localeCode: localeCode,
                        ),
                        isPositive: widget.adjustmentMinutes >= 0,
                        positiveColor: positiveColor,
                        negativeColor: negativeColor,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    Divider(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.3)),
                    const SizedBox(height: AppSpacing.sm),

                    // Total row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.balance_balanceToday,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          displayBalance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? positiveColor : negativeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
