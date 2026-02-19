# How Starting Balance Works

This document is based strictly on the current code in this repository.

## 1) Domain meaning: what "Starting balance" is

### Definition in code
- `ContractProvider` documents it as a balance-tracking anchor, not worked time:
  - "starting point for balance tracking" with:
    - `trackingStartDate`: "Date from which balances are calculated"
    - `openingFlexMinutes`: "Opening flex/time bank balance as of start date"
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:14`, `apps/mobile_flutter/lib/providers/contract_provider.dart:15`, `apps/mobile_flutter/lib/providers/contract_provider.dart:16`
- Stored field comment says signed credit/deficit minutes:
  - `int _openingFlexMinutes = 0; // Signed: positive = credit, negative = deficit`
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:28`

### User-facing wording already in app
- Contract settings helper text says this is the saldo starting point:
  - "Set your starting point for balance calculations. Ask your manager for your flex saldo as of this date."
  - "Credit means you have extra time", "Deficit means you owe time"
  - Reference: `apps/mobile_flutter/lib/l10n/app_en.arb:108`, `apps/mobile_flutter/lib/l10n/app_en.arb:113`, `apps/mobile_flutter/lib/l10n/app_en.arb:114`

### Blueprint documentation
- Blueprint separates balance offsets from tracked time:
  - opening balance + manual adjustments are "Balance offsets"
  - "Never mix opening/adjustments into tracked totals"
  - Reference: `apps/mobile_flutter/docs/BLUEPRINT.md:321`, `apps/mobile_flutter/docs/BLUEPRINT.md:352`, `apps/mobile_flutter/docs/BLUEPRINT.md:354`

Conclusion: Starting balance is carry-over saldo (+/-), not "hours already worked".

## 2) Where starting balance is stored

### Cloud data model and fields
- Profile model contains:
  - `DateTime? trackingStartDate`
  - `int openingFlexMinutes`
  - Reference: `apps/mobile_flutter/lib/models/user_profile.dart:20`, `apps/mobile_flutter/lib/models/user_profile.dart:21`
- Supabase profile mapping:
  - read: `tracking_start_date`, `opening_flex_minutes`
  - write: `tracking_start_date`, `opening_flex_minutes`
  - Reference: `apps/mobile_flutter/lib/models/user_profile.dart:86`, `apps/mobile_flutter/lib/models/user_profile.dart:89`, `apps/mobile_flutter/lib/models/user_profile.dart:115`, `apps/mobile_flutter/lib/models/user_profile.dart:118`
- Written to `profiles` table by `ProfileService.updateContractSettings(...)`
  - `.from('profiles').update({... 'tracking_start_date': ..., 'opening_flex_minutes': ...})`
  - Reference: `apps/mobile_flutter/lib/services/profile_service.dart:145`, `apps/mobile_flutter/lib/services/profile_service.dart:165`, `apps/mobile_flutter/lib/services/profile_service.dart:169`, `apps/mobile_flutter/lib/services/profile_service.dart:170`

### Local storage
- SharedPreferences keys:
  - `tracking_start_date`
  - `opening_flex_minutes`
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:36`, `apps/mobile_flutter/lib/providers/contract_provider.dart:37`
- Read/write in provider local cache:
  - load: `prefs.getString(_trackingStartDateKey)`, `prefs.getInt(_openingFlexMinutesKey)`
  - save: `prefs.setString(_trackingStartDateKey, ...)`, `prefs.setInt(_openingFlexMinutesKey, ...)`
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:343`, `apps/mobile_flutter/lib/providers/contract_provider.dart:360`, `apps/mobile_flutter/lib/providers/contract_provider.dart:397`, `apps/mobile_flutter/lib/providers/contract_provider.dart:402`

### Units
- Starting balance is integer minutes (`int`), signed:
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:57`, `apps/mobile_flutter/lib/providers/contract_provider.dart:28`

### Create flow, default, edit flow
- Defaults:
  - opening balance defaults to `0`
  - tracking start defaults to Jan 1 current year when unset
  - Reference: `apps/mobile_flutter/lib/providers/contract_provider.dart:28`, `apps/mobile_flutter/lib/providers/contract_provider.dart:50`
- UI create/edit flow (same screen):
  - read initial values from provider in `initState`
  - save via:
    - `setTrackingStartDate(_trackingStartDate)`
    - `setOpeningFlexMinutes(signedMinutes)`
  - Reference: `apps/mobile_flutter/lib/screens/contract_settings_screen.dart:51`, `apps/mobile_flutter/lib/screens/contract_settings_screen.dart:57`, `apps/mobile_flutter/lib/screens/contract_settings_screen.dart:164`, `apps/mobile_flutter/lib/screens/contract_settings_screen.dart:165`

## 3) How starting balance is used in calculations

## 3.1 Home yearly balance
- Function: `computeHomeYearlyBalanceMinutes(...)`
- Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:47`

Formula implemented:
1. `yearRange = TimeRange.thisYear(now)`  
   Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:57`
2. `adjustmentMinutesYear = sum(adjustment.deltaMinutes where effectiveDate in [yearRange.startInclusive, yearRange.endExclusive))`  
   Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:29`, `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:39`, `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:40`
3. `periodSummaryYear = PeriodSummaryCalculator.compute(..., startBalanceMinutes: openingBalanceMinutes, manualAdjustmentMinutes: adjustmentMinutesYear)`  
   Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:63`, `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:71`, `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:72`
4. Returned value:
   - `yearlyBalanceMinutes = periodSummaryYear.startBalanceMinutes + periodSummaryYear.manualAdjustmentMinutes + periodSummaryYear.differenceMinutes`
   - Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:75`

Where used:
- Home card headline "yearly" line reads this value:
  - `final balanceTodayMinutes = computeHomeYearlyBalanceMinutes(...)`
  - Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:140`

## 3.2 Time Balance screen/tab

### Reports > Time Balance tab
- Uses `TimeProvider.currentYearNetMinutes` plus opening balance for display:
  - `yearNetMinutes = timeProvider.currentYearNetMinutes`
  - `openingBalanceMinutes = contractProvider.openingFlexMinutes`
  - dashboard computes displayed balance today from these
  - Reference: `apps/mobile_flutter/lib/screens/reports/time_balance_tab.dart:139`, `apps/mobile_flutter/lib/screens/reports/time_balance_tab.dart:142`, `apps/mobile_flutter/lib/screens/reports/time_balance_tab.dart:163`
- In `YearlyBalanceCard`, displayed "Balance Today" is:
  - `balanceTodayMinutes = yearNetMinutes + openingBalanceMinutes` (unless explicit override provided)
  - Reference: `apps/mobile_flutter/lib/widgets/time_balance_dashboard.dart:367`, `apps/mobile_flutter/lib/widgets/time_balance_dashboard.dart:370`

### Dedicated Time Balance screen
- Same pattern:
  - `yearNetMinutes = timeProvider.currentYearNetMinutes`
  - `contractBalanceMinutes = yearNetMinutes + openingBalanceMinutes`
  - Reference: `apps/mobile_flutter/lib/screens/time_balance_screen.dart:150`, `apps/mobile_flutter/lib/screens/time_balance_screen.dart:152`

### Year net source formula (inside `TimeProvider`)
- `currentYearNetMinutes = yearActualMinutesToDate - yearTargetMinutesToDate + yearAdjustmentMinutesToDate`
- Opening balance is not included in `currentYearNetMinutes`; it is added in UI-level balance composition.
- Reference: `apps/mobile_flutter/lib/providers/time_provider.dart:788`, `apps/mobile_flutter/lib/providers/time_provider.dart:793`, `apps/mobile_flutter/lib/providers/time_provider.dart:796`

## 3.3 Reports > Overview tab (Balance adjustments section)

- Overview composes one `PeriodSummary`:
  - `startBalanceMinutes: summary.startingBalanceMinutes`
  - `manualAdjustmentMinutes: summary.balanceAdjustmentMinutesInRange`
  - Reference: `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:130`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:138`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:139`
- `PeriodSummary` formulas:
  - `trackedTotalMinutes = workMinutes + travelMinutes`
  - `accountedMinutes = trackedTotalMinutes + paidLeaveMinutes`
  - `differenceMinutes = accountedMinutes - targetMinutes`
  - `endBalanceMinutes = startBalanceMinutes + manualAdjustmentMinutes + differenceMinutes`
  - Reference: `apps/mobile_flutter/lib/reporting/period_summary.dart:34`, `apps/mobile_flutter/lib/reporting/period_summary.dart:35`, `apps/mobile_flutter/lib/reporting/period_summary.dart:36`, `apps/mobile_flutter/lib/reporting/period_summary.dart:38`
- Displayed in "Balance adjustments" section:
  - opening event
  - time adjustments total
  - balance at period start/end
  - Reference: `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:642`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:670`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:703`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:720`

## 3.4 Export (Summary Easy + Balance Events)

- Export uses the same `PeriodSummary` object passed from Overview:
  - `_buildPeriodSummary(summary)` then `ExportService.exportReportSummaryTo...`
  - Reference: `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:940`, `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:959`
- Summary (Easy) sheet rows include:
  - tracked total, paid leave, accounted, planned, difference, balance after period
  - `balance after period` uses `periodSummary.endBalanceMinutes`
  - Reference: `apps/mobile_flutter/lib/services/export_service.dart:389`, `apps/mobile_flutter/lib/services/export_service.dart:424`, `apps/mobile_flutter/lib/services/export_service.dart:425`
- Balance Events sheet rows include:
  - opening balance row (if present)
  - adjustments
  - adjustments total
  - period start balance
  - period end balance
  - Reference: `apps/mobile_flutter/lib/services/export_service.dart:455`, `apps/mobile_flutter/lib/services/export_service.dart:469`, `apps/mobile_flutter/lib/services/export_service.dart:483`, `apps/mobile_flutter/lib/services/export_service.dart:495`, `apps/mobile_flutter/lib/services/export_service.dart:506`

## 4) Range rules for starting balance

### Effective date rule
- Opening balance is represented as an event effective on `trackingStartDate`.
  - Reference: `apps/mobile_flutter/lib/reports/report_aggregator.dart:290`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:291`
- Practical rule from implementation:
  - if `trackingStartDate <= periodStart`: opening is part of period start balance
  - if `periodStart < trackingStartDate <= periodEnd`: opening appears as an in-period balance event
  - if `trackingStartDate > periodEnd`: opening is not applied in that period
  - Reference: `apps/mobile_flutter/lib/reports/report_aggregator.dart:315`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:316`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:325`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:346`

### Period-start / in-period semantics in reports
- Aggregator semantics:
  - events with `effectiveDate <= periodStart` are included in start balance
  - events with `effectiveDate > periodStart && <= periodEnd` are in-period events
  - Reference: `apps/mobile_flutter/lib/reports/report_aggregator.dart:255`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:258`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:265`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:329`
- Query layer explicitly excludes start-date adjustments from "in period":
  - `date.isAfter(startDate) && !date.isAfter(endDate)`
  - Reference: `apps/mobile_flutter/lib/reports/report_query_service.dart:195`, `apps/mobile_flutter/lib/reports/report_query_service.dart:197`

### Home yearly range
- Home yearly uses `TimeRange.thisYear(now)`:
  - start at local Jan 1
  - endExclusive = (today date-only) + 1 day
  - Reference: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:57`, `apps/mobile_flutter/lib/reporting/time_range.dart:76`, `apps/mobile_flutter/lib/reporting/time_range.dart:79`

### Tracking start clipping behavior
- `PeriodSummaryCalculator` clips target calculation start to `max(range.startInclusive, trackingStartDate)`.
  - Reference: `apps/mobile_flutter/lib/reporting/period_summary_calculator.dart:37`, `apps/mobile_flutter/lib/reporting/period_summary_calculator.dart:39`
- `TrackedTimeCalculator` itself filters only by `TimeRange.contains(entry.date)` and does not separately clip by tracking start date.
  - Reference: `apps/mobile_flutter/lib/reporting/tracked_time_calculator.dart:16`
- `TimeProvider` month/year target/actual/credit methods do clip by tracking start date.
  - Reference: `apps/mobile_flutter/lib/providers/time_provider.dart:820`, `apps/mobile_flutter/lib/providers/time_provider.dart:859`, `apps/mobile_flutter/lib/providers/time_provider.dart:911`, `apps/mobile_flutter/lib/providers/time_provider.dart:993`

## 5) What is NOT affected by starting balance

- Starting balance does not change tracked work/travel totals:
  - `TrackedTimeCalculator` sums only `entry.workDuration` and `entry.travelDuration`
  - Reference: `apps/mobile_flutter/lib/reporting/tracked_time_calculator.dart:21`, `apps/mobile_flutter/lib/reporting/tracked_time_calculator.dart:27`
- Report tracked totals are entries-only:
  - `workMinutes` and `travelMinutes` are folded from `sortedEntries`
  - Reference: `apps/mobile_flutter/lib/reports/report_aggregator.dart:283`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:287`, `apps/mobile_flutter/lib/reports/report_aggregator.dart:340`
- Trends buckets are entry-duration buckets and do not read opening balance:
  - monthly bucket accumulation uses `_workMinutesForEntry` / `_travelMinutesForEntry`
  - Reference: `apps/mobile_flutter/lib/viewmodels/customer_analytics_viewmodel.dart:475`, `apps/mobile_flutter/lib/viewmodels/customer_analytics_viewmodel.dart:483`, `apps/mobile_flutter/lib/viewmodels/customer_analytics_viewmodel.dart:491`

## 6) UX wording recommendation (to reduce confusion)

Option A:
- Label: `Starting balance (carry-over)`
- Help text: `Your flex saldo at the tracking start date. Not hours worked in this app.`

Option B:
- Label: `Balance brought forward`
- Help text: `Carry-over plus/minus at start date. Tracked work/travel totals are unchanged.`

Both options align with current code behavior and existing l10n wording that treats this as saldo credit/deficit, not tracked work.

## Example timeline

Example (same numbers as test):
- Tracking start date: `2026-01-01`
- Starting balance: `+600 min` (`+10h 0m`)
- Manual adjustment in year: `-120 min` (`-2h 0m`)
- Year period difference (accounted - target): `+315 min` (`+5h 15m`)

Yearly balance:
- `600 + (-120) + 315 = 795 min` (`+13h 15m`)

Code/test proof:
- formula: `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:75`
- test assertion (`795`): `apps/mobile_flutter/test/widgets/flexsaldo_card_test.dart:42`

## Common user mistakes and how UI should prevent them

1. Mistake: Entering "hours already worked this month" as starting balance.
- Why wrong: starting balance is carry-over saldo, not tracked work.
- Prevention: show helper text next to input and in save confirmation.

2. Mistake: Wrong sign (+/-).
- Why wrong: sign flips entire contract balance.
- Prevention: explicit `Credit (+)` / `Deficit (-)` segmented control with preview.
- Existing control: `apps/mobile_flutter/lib/screens/contract_settings_screen.dart:785`

3. Mistake: Expecting starting balance to change Trends work/travel totals.
- Why wrong: trends buckets are entry-only.
- Prevention: add inline note in Trends help/info tooltip: "carry-over saldo not included in tracked totals."

4. Mistake: Confusing adjustment effective date with creation date.
- Why wrong: range math uses `effectiveDate`.
- Prevention: date picker label should say "Effective date (applies to balance on this day)".
- Code uses effective date: `apps/mobile_flutter/lib/models/balance_adjustment.dart:9`, `apps/mobile_flutter/lib/widgets/flexsaldo_card.dart:35`

## Existing tests that already cover starting balance behavior

- Home yearly formula includes starting balance + adjustments + difference:
  - `apps/mobile_flutter/test/widgets/flexsaldo_card_test.dart:10`
- Home monthly status unchanged by starting balance/adjustments:
  - `apps/mobile_flutter/test/widgets/flexsaldo_card_test.dart:47`
- Report aggregator opening-balance-in-range and start-date-adjustment semantics:
  - `apps/mobile_flutter/test/reports/report_aggregator_test.dart:193`
  - `apps/mobile_flutter/test/reports/report_aggregator_test.dart:218`
- PeriodSummary end-balance contract:
  - `apps/mobile_flutter/test/reporting/period_summary_calculator_test.dart:56`
