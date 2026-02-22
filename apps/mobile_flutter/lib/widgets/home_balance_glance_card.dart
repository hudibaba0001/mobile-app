import 'package:flutter/material.dart';
import '../design/app_theme.dart';
import '../reporting/time_format.dart';

/// Compact "glance" balance card for the Home screen.
///
/// Shows at most 4 lines:
/// 1. Title ("Tidssaldo") + "Se mer →"
/// 2. Big signed balance number (+Xh Ym)
/// 3. Progress bar (month accounted / planned)
/// 4. Month one-liner: "Feb: 124h 25m / 120h 0m  +4h 25m"
class HomeBalanceGlanceCard extends StatelessWidget {
  const HomeBalanceGlanceCard({
    super.key,
    required this.timeBalanceEnabled,
    required this.balanceTodayMinutes,
    required this.monthDeltaMinutes,
    required this.monthLabel,
    required this.yearDeltaMinutes,
    required this.yearLabel,
    required this.title,
    required this.balanceSubtitle,
    required this.changeVsPlanLabel,
    required this.seeMoreLabel,
    required this.localeCode,
    required this.onSeeMore,
    this.monthAccountedMinutes = 0,
    this.monthPlannedMinutes = 0,
    this.sinceStartLabel = '',
  });

  final bool timeBalanceEnabled;
  final int balanceTodayMinutes;
  final int monthAccountedMinutes;
  final int monthPlannedMinutes;
  final int monthDeltaMinutes;
  final String monthLabel;
  final int yearDeltaMinutes;
  final String yearLabel;
  final String title;
  final String balanceSubtitle;
  final String changeVsPlanLabel;
  final String seeMoreLabel;
  final String sinceStartLabel;
  final String localeCode;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onSeeMore,
      child: Container(
        key: const Key('card_balance_glance'),
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : theme.colorScheme.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neutral900
                  .withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Title + "Se mer →"
            _buildHeader(theme),
            const SizedBox(height: AppSpacing.md),

            // Row 2: Big balance number + subtitle (or log-only mode)
            if (timeBalanceEnabled) ...[
              _buildBigBalance(theme),
              const SizedBox(height: 2),
              Text(
                balanceSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              _buildLogOnlyBalance(theme),
            const SizedBox(height: AppSpacing.md),

            // Row 3: Progress bar
            if (timeBalanceEnabled) ...[
              _buildProgressBar(theme),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Row 4: Month change-vs-plan one-liner
            _buildMonthLine(theme),

            // Row 5: Year change-vs-plan one-liner (only in time-balance mode)
            if (timeBalanceEnabled) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildYearLine(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.balance_rounded,
              size: AppIconSize.sm,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Text(
          seeMoreLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBigBalance(ThemeData theme) {
    final isPositive = balanceTodayMinutes >= 0;
    final color =
        isPositive ? FlexsaldoColors.positive : FlexsaldoColors.negative;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: balanceTodayMinutes.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          formatMinutes(
            animatedValue.round(),
            localeCode: localeCode,
            signed: true,
            showPlusForZero: true,
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildLogOnlyBalance(ThemeData theme) {
    // In log-only mode, show this month's logged time as the big number
    return Text(
      '$monthLabel: ${formatMinutes(monthAccountedMinutes, localeCode: localeCode)}',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final ratio = monthPlannedMinutes > 0
        ? (monthAccountedMinutes / monthPlannedMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isOver = monthAccountedMinutes > monthPlannedMinutes &&
        monthPlannedMinutes > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 6,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          isOver ? FlexsaldoColors.positive : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMonthLine(ThemeData theme) {
    if (!timeBalanceEnabled) {
      // Log-only: no month line needed (already shown as big number)
      return const SizedBox.shrink();
    }

    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    // "Feb: Change vs plan +4h 25m"
    final delta = formatMinutes(
      monthDeltaMinutes,
      localeCode: localeCode,
      signed: true,
    );
    final deltaColor = monthDeltaMinutes >= 0
        ? FlexsaldoColors.positive
        : FlexsaldoColors.negative;

    return Row(
      children: [
        Flexible(
          child: Text(
            '$monthLabel: $changeVsPlanLabel ',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          delta,
          style: style?.copyWith(
            color: deltaColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildYearLine(ThemeData theme) {
    final delta = formatMinutes(
      yearDeltaMinutes,
      localeCode: localeCode,
      signed: true,
    );
    final deltaColor = yearDeltaMinutes >= 0
        ? FlexsaldoColors.positive
        : FlexsaldoColors.negative;

    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        Flexible(
          child: Text(
            '$yearLabel: $changeVsPlanLabel ',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          delta,
          style: style?.copyWith(
            color: deltaColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
