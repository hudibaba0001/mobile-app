import sys

with open(r'c:\Users\sanlo\Documents\GitHub\mobile-app\apps\mobile_flutter\lib\screens\reports\trends_tab.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add import
code = code.replace(
    "import '../../design/app_theme.dart';",
    "import '../../design/app_theme.dart';\nimport '../../design/components/components.dart';"
)

# 2. Update Monthly Comparison list mapping
old_list = """          else
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: visibleMonths.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final month = mapEntry.value;
                  final leaves = leaveSummaries[_monthKey(month.month)] ??
                      _MonthlyLeaveSummary.empty;
                  final isLast = index == visibleMonths.length - 1;
                  return Column(
                    children: [
                      _buildMonthlyBreakdownCard(
                        context,
                        theme,
                        month,
                        leaves,
                        contractProvider,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),"""

new_list = """          else
            Column(
              children: visibleMonths.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final month = mapEntry.value;
                final leaves = leaveSummaries[_monthKey(month.month)] ??
                    _MonthlyLeaveSummary.empty;
                final isLast = index == visibleMonths.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                  child: _buildMonthlyBreakdownCard(
                    context,
                    theme,
                    month,
                    leaves,
                    contractProvider,
                  ),
                );
              }).toList(),
            ),"""

code = code.replace(old_list, new_list)

# 3. Update Weekly Hours Chart
old_weekly = """          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: _buildWeeklyHoursChart(
                  theme,
                  trendsData['weeklyMinutes'] as List<int>? ??
                      List.filled(7, 0)),
            ),
          ),"""

new_weekly = """          AspectRatio(
            aspectRatio: 1.8,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _buildWeeklyHoursChart(
                  theme,
                  trendsData['weeklyMinutes'] as List<int>? ??
                      List.filled(7, 0)),
            ),
          ),"""

code = code.replace(old_weekly, new_weekly)

# 4. _buildMonthlyBreakdownCard replacement
old_monthly_card = """    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTrackedMinutes(
                      context,
                      accounted.deltaMinutes,
                      signed: true,
                      showPlusForZero: true,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.reportsMetric_delta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, month.workMinutes),
                label: t.trends_work,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, month.travelMinutes),
                label: t.trends_travel,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, accounted.leaveMinutes),
                label: t.reportsMetric_leave,
              ),
              _buildMonthlyMetric(
                theme,
                value:
                    _formatTrackedMinutes(context, accounted.accountedMinutes),
                label: t.reportsMetric_accounted,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, accounted.targetMinutes),
                label: t.trends_target,
              ),
            ],
          ),
          if (leaves.hasAny) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (leaves.paidVacationCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.paidVacationMinutes)} ${t.leave_paidVacation}',
                  ),
                if (leaves.sickLeaveCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.sickLeaveMinutes)} ${t.leave_sickLeave}',
                  ),
                if (leaves.vabCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.vabMinutes)} ${t.leave_vab}',
                  ),
                if (leaves.unpaidCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.unpaidMinutes)} ${t.leave_unpaid}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );"""

new_monthly_card = """    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTrackedMinutes(
                      context,
                      accounted.deltaMinutes,
                      signed: true,
                      showPlusForZero: true,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.reportsMetric_delta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, accounted.accountedMinutes),
                label: t.reportsMetric_accounted,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, accounted.targetMinutes),
                label: t.trends_target,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, month.workMinutes),
                label: t.trends_work,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, month.travelMinutes),
                label: t.trends_travel,
              ),
              _buildMonthlyMetric(
                theme,
                value: _formatTrackedMinutes(context, accounted.leaveMinutes),
                label: t.reportsMetric_leave,
              ),
            ],
          ),
          if (leaves.hasAny) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (leaves.paidVacationCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.paidVacationMinutes)} ${t.leave_paidVacation}',
                  ),
                if (leaves.sickLeaveCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.sickLeaveMinutes)} ${t.leave_sickLeave}',
                  ),
                if (leaves.vabCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.vabMinutes)} ${t.leave_vab}',
                  ),
                if (leaves.unpaidCount > 0)
                  _buildLeaveLabel(
                    theme,
                    '${_formatTrackedMinutes(context, leaves.unpaidMinutes)} ${t.leave_unpaid}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );"""

code = code.replace(old_monthly_card, new_monthly_card)

# 5. Replace _buildDailyTrendCard
old_daily_card = """    // Handle null dayData
    if (dayData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).overview_noDataAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final date = dayData['date'] as DateTime? ?? DateTime.now();
    final workMinutes = (dayData['workMinutes'] as int?) ?? 0;
    final travelMinutes = (dayData['travelMinutes'] as int?) ?? 0;
    final totalMinutes = (dayData['totalMinutes'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _getDayAbbreviation(context, date.weekday),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.month}/${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_formatTrackedMinutes(context, totalMinutes)} ${AppLocalizations.of(context).trends_total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatTrackedMinutes(context, workMinutes)} ${AppLocalizations.of(context).trends_work}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_formatTrackedMinutes(context, travelMinutes)} ${AppLocalizations.of(context).trends_travel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );"""

new_daily_card = """    // Handle null dayData
    if (dayData == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Text(
            AppLocalizations.of(context).overview_noDataAvailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final date = dayData['date'] as DateTime? ?? DateTime.now();
    final workMinutes = (dayData['workMinutes'] as int?) ?? 0;
    final travelMinutes = (dayData['travelMinutes'] as int?) ?? 0;
    final totalMinutes = (dayData['totalMinutes'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayAbbreviation(context, date.weekday),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatTrackedMinutes(context, totalMinutes)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).trends_total,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatTrackedMinutes(context, workMinutes)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.work_rounded, size: AppIconSize.xs, color: colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatTrackedMinutes(context, travelMinutes)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.directions_car_rounded, size: AppIconSize.xs, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );"""

code = code.replace(old_daily_card, new_daily_card)

with open(r'c:\Users\sanlo\Documents\GitHub\mobile-app\apps\mobile_flutter\lib\screens\reports\trends_tab.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Modification complete.")
