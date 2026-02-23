import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/design.dart';
import '../reporting/time_format.dart';
import '../l10n/generated/app_localizations.dart';

class TimeBalanceDashboard extends StatelessWidget {
  final int currentMonthMinutes;
  final int currentYearMinutes;
  final int fullMonthlyTargetMinutes;
  final int fullYearlyTargetMinutes;
  final int? monthlyTargetToDateMinutes;
  final int? yearlyTargetToDateMinutes;
  final String currentMonthName;
  final int currentYear;
  final int? monthlyCreditMinutes;
  final int? yearlyCreditMinutes;
  final int monthlyAdjustmentMinutes;
  final int yearlyAdjustmentMinutes;
  final int openingBalanceMinutes;
  final DateTime? trackingStartDate;
  final bool travelEnabled;

  const TimeBalanceDashboard({
    super.key,
    required this.currentMonthMinutes,
    required this.currentYearMinutes,
    required this.fullMonthlyTargetMinutes,
    required this.fullYearlyTargetMinutes,
    required this.currentMonthName,
    required this.currentYear,
    required this.monthlyAdjustmentMinutes,
    required this.yearlyAdjustmentMinutes,
    required this.openingBalanceMinutes,
    this.monthlyTargetToDateMinutes,
    this.yearlyTargetToDateMinutes,
    this.monthlyCreditMinutes,
    this.yearlyCreditMinutes,
    this.trackingStartDate,
    this.travelEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyStatusCard(
          monthName: currentMonthName,
          workedMinutes: currentMonthMinutes,
          fullTargetMinutes: fullMonthlyTargetMinutes,
          targetMinutesToDate: monthlyTargetToDateMinutes,
          creditMinutes: monthlyCreditMinutes,
          adjustmentMinutes: monthlyAdjustmentMinutes,
          trackingStartDate: trackingStartDate,
          travelEnabled: travelEnabled,
        ),
        const SizedBox(height: AppSpacing.lg),
        YearlyBalanceCard(
          year: currentYear,
          workedMinutes: currentYearMinutes,
          fullTargetMinutes: fullYearlyTargetMinutes,
          targetMinutesToDate: yearlyTargetToDateMinutes,
          creditMinutes: yearlyCreditMinutes,
          adjustmentMinutes: yearlyAdjustmentMinutes,
          openingBalanceMinutes: openingBalanceMinutes,
          trackingStartDate: trackingStartDate,
          travelEnabled: travelEnabled,
        ),
      ],
    );
  }
}

class MonthlyStatusCard extends StatelessWidget {
  final String monthName;
  final int workedMinutes;
  final int fullTargetMinutes;
  final int? targetMinutesToDate;
  final int adjustmentMinutes;
  final int? creditMinutes;
  final DateTime? trackingStartDate;
  final bool travelEnabled;

  const MonthlyStatusCard({
    super.key,
    required this.monthName,
    required this.workedMinutes,
    required this.fullTargetMinutes,
    required this.adjustmentMinutes,
    this.targetMinutesToDate,
    this.creditMinutes,
    this.trackingStartDate,
    this.travelEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;

    final accountedMinutes = workedMinutes + (creditMinutes ?? 0);
    final targetForVariance = targetMinutesToDate ?? fullTargetMinutes;
    final varianceMinutes = accountedMinutes - targetForVariance;
    final isOverTarget = varianceMinutes >= 0;

    final positiveColor =
        isDark ? FlexsaldoColors.positive : FlexsaldoColors.positiveDark;
    final negativeColor =
        isDark ? FlexsaldoColors.negative : FlexsaldoColors.negativeDark;

    return AppCard(
      padding: AppSpacing.cardPadding * 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.balance_thisMonthLabel(monthName),
                  style: AppTypography.cardTitle(theme.colorScheme.onSurface),
                ),
              ),
              if (trackingStartDate != null &&
                  trackingStartDate!.month == DateTime.now().month &&
                  trackingStartDate!.year == DateTime.now().year)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    l10n.balance_countingFrom(
                        DateFormat('d MMM').format(trackingStartDate!)),
                    style: AppTypography.caption(
                            theme.colorScheme.onTertiaryContainer)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.balance_differenceVsPlan,
                style: AppTypography.sectionTitle(
                    theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                formatSignedMinutes(varianceMinutes,
                    localeCode: localeCode, showPlusForZero: true),
                style: AppTypography.headline(
                        isOverTarget ? positiveColor : negativeColor)
                    .copyWith(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildProgressBar(context, accountedMinutes, targetForVariance,
              positiveColor, negativeColor),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow(
              context, l10n.balance_loggedTime, workedMinutes, localeCode),
          _buildInfoRow(context, l10n.balance_creditedLeave, creditMinutes ?? 0,
              localeCode,
              isCredit: true),
          const Divider(height: 16),
          _buildInfoRow(
              context, l10n.balance_accountedTime, accountedMinutes, localeCode,
              isBold: true),
          _buildInfoRow(context, l10n.balance_plannedTimeSinceBaseline,
              targetForVariance, localeCode,
              isBold: true),
          if (targetForVariance == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.balance_planCalculatedFromStart,
                style:
                    AppTypography.caption(theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _buildCollapsibleDetails(
            context,
            l10n,
            localeCode,
            travelEnabled: travelEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int current, int target,
      Color positiveColor, Color negativeColor) {
    if (target == 0) return const SizedBox.shrink();
    final double percent = (current / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isOverTarget = current >= target;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 8,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          isOverTarget ? positiveColor : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, int minutes, String localeCode,
      {bool isBold = false, bool isCredit = false, bool isSubtle = false,
      bool isSigned = false}) {
    final theme = Theme.of(context);
    Color textColor = theme.colorScheme.onSurface;
    if (isSubtle) textColor = theme.colorScheme.onSurfaceVariant;
    if (isCredit && minutes > 0) textColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(textColor).copyWith(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                fontSize: isSubtle ? 13 : 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isSigned
                ? formatSignedMinutes(minutes,
                    localeCode: localeCode, showPlusForZero: true)
                : formatMinutes(minutes,
                    localeCode: localeCode, padMinutes: true),
            style: AppTypography.body(textColor).copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isSubtle ? 13 : 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDetails(
      BuildContext context, AppLocalizations l10n, String localeCode,
      {required bool travelEnabled}) {
    if (travelEnabled) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text(l10n.balance_details,
          style: AppTypography.body(Theme.of(context).colorScheme.primary)),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context, l10n.balance_travelExcluded, 0, localeCode,
            isSubtle: true),
      ],
    );
  }
}

class YearlyBalanceCard extends StatelessWidget {
  final int year;
  final int workedMinutes;
  final int fullTargetMinutes;
  final int? targetMinutesToDate;
  final int? creditMinutes;
  final int adjustmentMinutes;
  final int openingBalanceMinutes;
  final DateTime? trackingStartDate;
  final bool travelEnabled;

  const YearlyBalanceCard({
    super.key,
    required this.year,
    required this.workedMinutes,
    required this.fullTargetMinutes,
    required this.adjustmentMinutes,
    required this.openingBalanceMinutes,
    this.targetMinutesToDate,
    this.creditMinutes,
    this.trackingStartDate,
    this.travelEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;

    final accountedMinutes = workedMinutes + (creditMinutes ?? 0);
    final targetForVariance = targetMinutesToDate ?? fullTargetMinutes;
    final varianceMinutes = accountedMinutes - targetForVariance;
    final isOverTarget = varianceMinutes >= 0;

    final positiveColor =
        isDark ? FlexsaldoColors.positive : FlexsaldoColors.positiveDark;
    final negativeColor =
        isDark ? FlexsaldoColors.negative : FlexsaldoColors.negativeDark;

    return AppCard(
      padding: AppSpacing.cardPadding * 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.balance_thisYear(year),
                  style: AppTypography.cardTitle(theme.colorScheme.onSurface),
                ),
              ),
              if (trackingStartDate != null &&
                  trackingStartDate!.year == year &&
                  trackingStartDate!.isAfter(DateTime(year, 1, 1)))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    l10n.balance_countingFrom(
                        DateFormat('d MMM yyyy').format(trackingStartDate!)),
                    style: AppTypography.caption(
                            theme.colorScheme.onTertiaryContainer)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.balance_differenceVsPlan,
                style: AppTypography.sectionTitle(
                    theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                formatSignedMinutes(varianceMinutes,
                    localeCode: localeCode, showPlusForZero: true),
                style: AppTypography.headline(
                        isOverTarget ? positiveColor : negativeColor)
                    .copyWith(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildProgressBar(context, accountedMinutes, targetForVariance,
              positiveColor, negativeColor),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow(
              context, l10n.balance_loggedTime, workedMinutes, localeCode),
          _buildInfoRow(context, l10n.balance_creditedLeave, creditMinutes ?? 0,
              localeCode,
              isCredit: true),
          const Divider(height: 16),
          _buildInfoRow(
              context, l10n.balance_accountedTime, accountedMinutes, localeCode,
              isBold: true),
          _buildInfoRow(context, l10n.balance_plannedTimeSinceBaseline,
              targetForVariance, localeCode,
              isBold: true),
          if (targetForVariance == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.balance_planCalculatedFromStart,
                style:
                    AppTypography.caption(theme.colorScheme.onSurfaceVariant),
              ),
            ),
          if (adjustmentMinutes != 0)
            _buildInfoRow(context, l10n.balance_adjustments_this_year,
                adjustmentMinutes, localeCode,
                isBold: false, isSubtle: false, isSigned: true),
          _buildCollapsibleDetails(
            context,
            l10n,
            localeCode,
            travelEnabled: travelEnabled,
            openingBalanceMinutes: openingBalanceMinutes,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int current, int target,
      Color positiveColor, Color negativeColor) {
    if (target == 0) return const SizedBox.shrink();
    final double percent = (current / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isOverTarget = current >= target;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 8,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          isOverTarget ? positiveColor : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, int minutes, String localeCode,
      {bool isBold = false, bool isCredit = false, bool isSubtle = false,
      bool isSigned = false}) {
    final theme = Theme.of(context);
    Color textColor = theme.colorScheme.onSurface;
    if (isSubtle) textColor = theme.colorScheme.onSurfaceVariant;
    if (isCredit && minutes > 0) textColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(textColor).copyWith(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                fontSize: isSubtle ? 13 : 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isSigned
                ? formatSignedMinutes(minutes,
                    localeCode: localeCode, showPlusForZero: true)
                : formatMinutes(minutes,
                    localeCode: localeCode, padMinutes: true),
            style: AppTypography.body(textColor).copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isSubtle ? 13 : 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDetails(
      BuildContext context, AppLocalizations l10n, String localeCode,
      {required bool travelEnabled, required int openingBalanceMinutes}) {
    final hasDetails = !travelEnabled || openingBalanceMinutes != 0;
    if (!hasDetails) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(l10n.balance_details,
          style: AppTypography.body(theme.colorScheme.primary)),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!travelEnabled)
          _buildInfoRow(context, l10n.balance_travelExcluded, 0, localeCode,
              isSubtle: true),
        if (openingBalanceMinutes != 0) ...[
          _buildInfoRow(
            context,
            l10n.balance_startingBalance,
            openingBalanceMinutes,
            localeCode,
            isSubtle: true,
            isSigned: true,
          ),
          if (trackingStartDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                l10n.balance_countingFrom(
                    DateFormat('d MMM yyyy').format(trackingStartDate!)),
                style:
                    AppTypography.caption(theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }
}
