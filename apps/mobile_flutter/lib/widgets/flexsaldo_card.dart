import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../calendar/sweden_holidays.dart';
import '../models/absence.dart';
import '../models/balance_adjustment.dart';
import '../models/entry.dart';
import '../design/app_theme.dart';
import '../config/app_router.dart';
import '../providers/absence_provider.dart';
import '../providers/balance_adjustment_provider.dart';
import '../providers/time_provider.dart';
import '../providers/contract_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../reporting/period_summary_calculator.dart';
import '../reporting/time_format.dart';
import '../reporting/time_range.dart';
import '../l10n/generated/app_localizations.dart';

class HomeTrackingRangeText extends StatelessWidget {
  const HomeTrackingRangeText({
    super.key,
    required this.baselineDate,
    required this.baselineMinutes,
    required this.today,
    required this.localeCode,
  });

  final DateTime baselineDate;
  final int baselineMinutes;
  final DateTime today;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final baselineDateText = dateFormat.format(baselineDate);
    final todayDateText = dateFormat.format(today);
    final baselineText = formatMinutes(
      baselineMinutes,
      localeCode: localeCode,
      signed: true,
      showPlusForZero: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Baseline: $baselineText (as of $baselineDateText)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Calculated from: $baselineDateText → $todayDateText',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
int computeHomeMonthlyStatusMinutes({
  required int monthActualMinutes,
  required int monthCreditMinutes,
  required int monthTargetMinutesToDate,
}) {
  return monthActualMinutes + monthCreditMinutes - monthTargetMinutesToDate;
}

int _sumAdjustmentsInRangeMinutes({
  required List<BalanceAdjustment> adjustments,
  required TimeRange range,
}) {
  return adjustments.fold<int>(0, (sum, adjustment) {
    final date = DateTime(
      adjustment.effectiveDate.year,
      adjustment.effectiveDate.month,
      adjustment.effectiveDate.day,
    );
    if (!date.isBefore(range.startInclusive) &&
        date.isBefore(range.endExclusive)) {
      return sum + adjustment.deltaMinutes;
    }
    return sum;
  });
}

@visibleForTesting
int computeHomeYearlyBalanceMinutes({
  required DateTime now,
  required List<Entry> entries,
  required List<AbsenceEntry> absences,
  required List<BalanceAdjustment> adjustments,
  required int weeklyTargetMinutes,
  required DateTime trackingStartDate,
  required int openingBalanceMinutes,
  required bool travelEnabled,
}) {
  final yearRange = TimeRange.thisYear(now: now);
  final effectiveYearRange = yearRange.clipStart(trackingStartDate);
  final adjustmentMinutesYear = _sumAdjustmentsInRangeMinutes(
    adjustments: adjustments,
    range: effectiveYearRange,
  );

  final periodSummaryYear = PeriodSummaryCalculator.compute(
    entries: entries,
    absences: absences,
    range: effectiveYearRange,
    travelEnabled: travelEnabled,
    weeklyTargetMinutes: weeklyTargetMinutes,
    holidays: SwedenHolidayCalendar(),
    trackingStartDate: trackingStartDate,
    startBalanceMinutes: openingBalanceMinutes,
    manualAdjustmentMinutes: adjustmentMinutesYear,
  );

  return periodSummaryYear.startBalanceMinutes +
      periodSummaryYear.manualAdjustmentMinutes +
      periodSummaryYear.differenceMinutes;
}

/// Flexsaldo card for the Home screen.
///
/// Shows:
/// - Balance Today (year-to-date + opening balance) as headline
/// - This month balance as secondary
/// - Starting balance (if != 0)
class FlexsaldoCard extends StatelessWidget {
  const FlexsaldoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    // Watch providers used by the formulas so Home balance updates immediately.
    final entryProvider = context.watch<EntryProvider>();
    final absenceProvider = context.watch<AbsenceProvider?>();
    final adjustmentProvider = context.watch<BalanceAdjustmentProvider?>();
    final settingsProvider = context.watch<SettingsProvider?>();

    return Consumer2<TimeProvider, ContractProvider>(
      builder: (context, timeProvider, contractProvider, _) {
        final now = DateTime.now();
        final year = now.year;
        final month = now.month;
        final todayDateOnly = DateTime(now.year, now.month, now.day);
        final trackingStartDateOnly = DateTime(
          contractProvider.effectiveTrackingStartDate.year,
          contractProvider.effectiveTrackingStartDate.month,
          contractProvider.effectiveTrackingStartDate.day,
        );
        final earliestEntryDate = entryProvider.earliestEntryDate;
        final showBackfillBanner = earliestEntryDate != null &&
            earliestEntryDate.isBefore(trackingStartDateOnly);
        final localeCode = Localizations.localeOf(context).toLanguageTag();
        final monthName =
            DateFormat.MMMM(Localizations.localeOf(context).toString())
                .format(now);

        // === MONTHLY VALUES (for secondary display) ===
        final monthActualMinutes =
            timeProvider.monthActualMinutesToDate(year, month);
        final monthCreditMinutes =
            timeProvider.monthCreditMinutesToDate(year, month);
        final monthTargetMinutesToDate =
            timeProvider.monthTargetMinutesToDate(year, month);
        final monthWorkedPlusCredited = monthActualMinutes + monthCreditMinutes;
        final monthBalanceMinutes = computeHomeMonthlyStatusMinutes(
          monthActualMinutes: monthActualMinutes,
          monthCreditMinutes: monthCreditMinutes,
          monthTargetMinutesToDate: monthTargetMinutesToDate,
        );

        // Full month target for display (not just to-date)
        final fullMonthTargetMinutes =
            (timeProvider.monthlyTargetHours(year: year, month: month) * 60)
                .round();

        // === YEAR-TO-DATE VALUES ===
        final yearActualMinutes = timeProvider.yearActualMinutesToDate(year);
        final yearCreditMinutes = timeProvider.yearCreditMinutesToDate(year);
        final yearTargetMinutes = timeProvider.yearTargetMinutesToDate(year);
        final yearAbsences =
            absenceProvider?.absencesForYear(year) ?? const <AbsenceEntry>[];
        final yearAdjustments =
            adjustmentProvider?.allAdjustments ?? const <BalanceAdjustment>[];
        final travelEnabled = settingsProvider?.isTravelLoggingEnabled ?? true;

        // === BALANCE TODAY (year-to-date + opening balance + year adjustments) ===
        final balanceTodayMinutes = computeHomeYearlyBalanceMinutes(
          now: now,
          entries: entryProvider.entries,
          absences: yearAbsences,
          adjustments: yearAdjustments,
          weeklyTargetMinutes: contractProvider.weeklyTargetMinutes,
          trackingStartDate: contractProvider.trackingStartDate,
          openingBalanceMinutes: contractProvider.openingFlexMinutes,
          travelEnabled: travelEnabled,
        );

        // Colors based on balance today (headline)
        final isPositive = balanceTodayMinutes >= 0;
        final balanceColor =
            isPositive ? FlexsaldoColors.positive : FlexsaldoColors.negative;

        // Format monthly balance for secondary line
        final isMonthPositive = monthBalanceMinutes >= 0;
        final workedText =
            formatMinutes(monthWorkedPlusCredited, localeCode: localeCode);
        final targetText =
            formatMinutes(monthTargetMinutesToDate, localeCode: localeCode);
        final yearWorkedText = formatMinutes(
          yearActualMinutes + yearCreditMinutes,
          localeCode: localeCode,
        );
        final yearTargetText =
            formatMinutes(yearTargetMinutes, localeCode: localeCode);
        final fullMonthTargetText =
            formatMinutes(fullMonthTargetMinutes, localeCode: localeCode);
        final fullMonthTargetLabel = t
            .balance_fullMonthTarget('')
            .replaceFirst(RegExp(r'h$'), '')
            .trim();

        Widget animatedSignedMinutes({
          required int valueMinutes,
          required TextStyle? style,
          bool showPlusForZero = false,
        }) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: valueMinutes.toDouble()),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              final animatedMinutes = animatedValue.round();
              return Text(
                formatMinutes(
                  animatedMinutes,
                  localeCode: localeCode,
                  signed: true,
                  showPlusForZero: showPlusForZero,
                ),
                style: style,
              );
            },
          );
        }

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
                color: AppColors.neutral900.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                    t.balance_thisMonthLabel(monthName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              HomeTrackingRangeText(
                baselineDate: trackingStartDateOnly,
                baselineMinutes: contractProvider.openingFlexMinutes,
                today: todayDateOnly,
                localeCode: localeCode,
              ),
              if (showBackfillBanner) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Du har poster före ditt startdatum. Saldo beräknas från startdatum.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            AppRouter.goToContractSettings(context),
                        child: const Text('Ändra'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Line 1 (PRIMARY): Status (to date)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    t.balance_statusToDate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  animatedSignedMinutes(
                    valueMinutes: monthBalanceMinutes,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isMonthPositive
                          ? FlexsaldoColors.positive
                          : FlexsaldoColors.negative,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Line 2: Accounted (to date): X.Xh / Y.Yh
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: '${t.balance_workedToDate} '),
                    TextSpan(
                      text: workedText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                    ),
                    const TextSpan(text: ' / '),
                    TextSpan(
                      text: targetText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Line 3 (small): Full month target: XXXh
              Text(
                '$fullMonthTargetLabel $fullMonthTargetText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Yearly summary
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    t.balance_yearlyLabel(year),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  animatedSignedMinutes(
                    valueMinutes: balanceTodayMinutes,
                    showPlusForZero: true,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Year accounted (to date): X.Xh / Y.Yh
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: '${t.balance_workedToDate} '),
                    TextSpan(
                      text: yearWorkedText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                    ),
                    const TextSpan(text: ' / '),
                    TextSpan(
                      text: yearTargetText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              if (contractProvider.hasOpeningBalance) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.balance_startingBalanceValue(
                      contractProvider.openingFlexFormatted),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
  }
}
