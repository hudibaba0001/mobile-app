# Reporting Audit (PR1)

## 1) History logic to reuse

### Date range filtering (start/end inclusive)
- `apps/mobile_flutter/lib/screens/history_screen.dart:818` `DateTimeRange? _getDateRangeFilter()`
  - Builds ranges for `today`, `yesterday`, `lastWeek`, `custom`.
- `apps/mobile_flutter/lib/screens/history_screen.dart:267` `_buildDateChip(...)`
  - Applies date range by calling `EntryProvider.filterEntries(startDate, endDate, ...)`.
- `apps/mobile_flutter/lib/screens/history_screen.dart:770` `_showDateRangePicker(...)`
  - Sets custom range and calls `EntryProvider.filterEntries(...)`.
- `apps/mobile_flutter/lib/providers/entry_provider.dart:560` `filterEntries(...)`
- `apps/mobile_flutter/lib/providers/entry_provider.dart:575` `_applyFilters()`
  - Inclusive behavior: entry is removed only if `entry.date.isBefore(startDate)` or `entry.date.isAfter(endDate)`, so boundaries are included.

### Type filtering (work/travel/all)
- `apps/mobile_flutter/lib/screens/history_screen.dart:172` `_buildSegmentButton(...)`
  - Calls `EntryProvider.filterEntries(selectedType: EntryType.work/travel/null)`.
- `apps/mobile_flutter/lib/providers/entry_provider.dart:575` `_applyFilters()`
  - Applies type filter with `_selectedType`.

### Ordering and pagination
- Ordering:
  - `apps/mobile_flutter/lib/providers/entry_provider.dart:155` local cached entries sorted `date DESC`.
  - `apps/mobile_flutter/lib/providers/entry_provider.dart:261` Supabase entries sorted `date DESC`.
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:33` DB query orders by `date DESC`.
- Pagination:
  - `apps/mobile_flutter/lib/screens/history_screen.dart:63` `_loadMoreEntries()`
    - Currently reloads entries; comment says pagination is client-side.
  - Server-side pagination primitive exists:
    - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:22` `getAllEntries(userId, {limit, offset})`
    - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:163` `getEntryCount(userId)`

### Timezone handling (UTC vs local)
- History screen itself does not convert timezone; it depends on fetch/save layer.
- Read path (UTC -> local):
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:147` `_mapShiftFromDb(...)`
  - Parses `start_time/end_time` and calls `.toLocal()`.
- Write path (local -> UTC):
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:393` (insert shifts)
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:564` (update shifts)
  - Converts local shift DateTime to UTC before storing.
- Entry `date` itself is stored as date-only (`YYYY-MM-DD`):
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:306` `entryData` for insert (`date` date-only)
  - `apps/mobile_flutter/lib/services/supabase_entry_service.dart:497` `entryData` for update (`date` date-only)

## 2) Export logic to reuse

### Where export fetches entries today
- `apps/mobile_flutter/lib/screens/reports_screen.dart:45` `_showExportDialog(...)`
  - Calls `_getAllEntries()`.
- `apps/mobile_flutter/lib/screens/reports_screen.dart:102` `_getAllEntries()`
  - Ensures `EntryProvider.loadEntries()` if needed.
  - Uses `EntryProvider.entries`.
  - Sorts by `date DESC`, tie-break `updatedAt/createdAt`.

### Where export calculates totals
- Preview totals in dialog:
  - `apps/mobile_flutter/lib/widgets/export_dialog.dart:292` `_getFilteredEntries()`
  - `apps/mobile_flutter/lib/widgets/export_dialog.dart:329` `_calculateTotalHours(...)` (uses `entry.totalDuration`).
- Final export totals:
  - `apps/mobile_flutter/lib/services/export_service.dart:25` `prepareExportData(...)`
  - Computes `totalTravelMinutes`, `totalTravelDistanceKm`, `totalWorkedMinutes`.
  - Appends totals row.

### Where CSV/XLSX formatting happens
- CSV formatting:
  - `apps/mobile_flutter/lib/services/csv_exporter.dart:4` `CsvExporter.export(...)`
  - Uses `ListToCsvConverter` and formula-injection sanitization.
- XLSX formatting:
  - `apps/mobile_flutter/lib/services/xlsx_exporter.dart:4` `XlsxExporter.export(...)`
  - Uses `Excel.createExcel()` and typed cells.
- Export entry points:
  - `apps/mobile_flutter/lib/services/export_service.dart:221` `exportEntriesToCSV(...)`
  - `apps/mobile_flutter/lib/services/export_service.dart:268` `exportEntriesToExcel(...)`

## 3) Opening balance + time adjuster model

### Opening balance storage and usage
- Active cloud storage is `profiles` table columns:
  - `tracking_start_date` (DATE)
  - `opening_flex_minutes` (INTEGER)
  - See `supabase/migrations/add_contract_settings_to_profiles.sql:8` and `supabase/migrations/add_contract_settings_to_profiles.sql:9`.
- App model:
  - `apps/mobile_flutter/lib/models/user_profile.dart:20` `trackingStartDate`
  - `apps/mobile_flutter/lib/models/user_profile.dart:21` `openingFlexMinutes`
- Fetch path:
  - `apps/mobile_flutter/lib/providers/contract_provider.dart:125` `loadFromSupabase()`
  - `apps/mobile_flutter/lib/services/profile_service.dart:31` `fetchProfile()`
- Balance usage:
  - `apps/mobile_flutter/lib/providers/time_provider.dart:257` reads `trackingStartDate` and `openingFlexMinutes`.
  - `apps/mobile_flutter/lib/providers/time_provider.dart:299` filters out entries before tracking start.
  - `apps/mobile_flutter/lib/providers/time_provider.dart:393` adds opening balance once to running/year balance.

### Effective date rule for opening balance
- There is no separate `opening_balance_effective_from` field.
- Effective date is `tracking_start_date` (start of balance timeline).
- Operational rule in code:
  - entries before `tracking_start_date` are excluded
  - `opening_flex_minutes` is added once as initial offset.

### Time Adjuster storage format
- Stored as a separate model/table, not as normal time entries:
  - Model: `apps/mobile_flutter/lib/models/balance_adjustment.dart`
  - Table: `balance_adjustments` in `supabase_migrations/005_balance_adjustments.sql:4`
- Fields (confirmed):
  - `effective_date` (date)
  - `delta_minutes` (signed int)
  - `note` (text)
  - plus `id`, `user_id`, `created_at`, `updated_at`
- Repository/API:
  - `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart:14` `listAdjustmentsRange(...)`
  - `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart:80` `createAdjustment(...)`
  - `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart:110` `updateAdjustment(...)`
- Provider usage:
  - `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:111` `loadAdjustments(...)`
  - `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:200` `adjustmentMinutesForDate(...)`
  - `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:183` `totalAdjustmentMinutesInRange(...)`

## 4) Settings/rules affecting totals and balance

### `countTravelAsWork`
- No runtime setting/function found in app code for `countTravelAsWork`.
- Current behavior effectively includes travel in many totals by default via `Entry.totalDuration`:
  - `apps/mobile_flutter/lib/models/entry.dart:481` `Duration get totalDuration`
  - `apps/mobile_flutter/lib/providers/time_provider.dart:580` `_calculateTotalHours(...)`
  - `apps/mobile_flutter/lib/providers/time_provider.dart:967` `yearActualMinutesToDate(...)`
  - `apps/mobile_flutter/lib/widgets/export_dialog.dart:329` `_calculateTotalHours(...)`

### Break handling
- Work break deduction is built into shift math:
  - `apps/mobile_flutter/lib/models/entry.dart:165` `Shift.workedMinutes` subtracts `unpaidBreakMinutes`.
  - `apps/mobile_flutter/lib/models/entry.dart:467` `Entry.totalWorkDuration` sums worked minutes.
- Export includes break/worked fields:
  - `apps/mobile_flutter/lib/services/export_service.dart:130` uses `shift.unpaidBreakMinutes` and `shift.workedMinutes`.

### Red days / half-days / custom red days
- Toggle auto holiday marking:
  - `apps/mobile_flutter/lib/services/holiday_service.dart:219` `setAutoMarkHolidays(...)`
  - `apps/mobile_flutter/lib/screens/settings_screen.dart:858` switch hook.
- Custom personal red days:
  - `apps/mobile_flutter/lib/services/holiday_service.dart:269` `upsertPersonalRedDay(...)`
  - `apps/mobile_flutter/lib/services/holiday_service.dart:293` `deletePersonalRedDay(...)`
  - Storage repository: `apps/mobile_flutter/lib/repositories/user_red_day_repository.dart`
  - DB table: `supabase_migrations/004_user_red_days.sql`
- Target/balance impact:
  - `apps/mobile_flutter/lib/services/holiday_service.dart:337` `getRedDayInfo(...)`
  - `apps/mobile_flutter/lib/utils/target_hours_calculator.dart:189` `scheduledMinutesWithRedDayInfo(...)` (full day -> 0, half day -> 50%)
  - `apps/mobile_flutter/lib/providers/time_provider.dart:148` `_getScheduledMinutesForDate(...)` applies the red-day logic.

### Contract % / expected hours logic
- Contract settings source:
  - `apps/mobile_flutter/lib/providers/contract_provider.dart`
  - `contractPercent` + `fullTimeHours` -> `weeklyTargetMinutes` (`apps/mobile_flutter/lib/providers/contract_provider.dart:83`)
- Balance math source:
  - `apps/mobile_flutter/lib/providers/time_provider.dart:244` uses `weeklyTargetMinutes`.
  - Day-by-day scheduled targets drive month/year target and variance.

## 5) Exact functions/classes to reuse

- History-equivalent entry filtering:
  - `EntryProvider.filterEntries(...)` in `apps/mobile_flutter/lib/providers/entry_provider.dart:560`
  - `EntryProvider.filteredEntries` in `apps/mobile_flutter/lib/providers/entry_provider.dart:66`
- Export totals/serialization:
  - `ExportService.prepareExportData(...)` in `apps/mobile_flutter/lib/services/export_service.dart:25`
  - `CsvExporter.export(...)` in `apps/mobile_flutter/lib/services/csv_exporter.dart:5`
  - `XlsxExporter.export(...)` in `apps/mobile_flutter/lib/services/xlsx_exporter.dart:5`
- Absence retrieval:
  - `AbsenceProvider.loadAbsences(...)` in `apps/mobile_flutter/lib/providers/absence_provider.dart:115`
  - `AbsenceProvider.absencesForYear(...)` in `apps/mobile_flutter/lib/providers/absence_provider.dart:254`
- Opening balance retrieval:
  - `ContractProvider.loadFromSupabase()` in `apps/mobile_flutter/lib/providers/contract_provider.dart:125`
  - `ProfileService.fetchProfile()` in `apps/mobile_flutter/lib/services/profile_service.dart:31`
- Time adjustments retrieval:
  - `BalanceAdjustmentProvider.loadAdjustments(...)` in `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:111`
  - `BalanceAdjustmentRepository.listAdjustmentsForYear(...)` in `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart:45`

## 6) Required direct answer

Where do we fetch entries, absences, opening balance, and time adjustments today?

- Entries:
  - `EntryProvider.loadEntries()` -> `EntryProvider._loadEntriesInternal()` -> `SupabaseEntryService.getAllEntries(...)`
  - Files: `apps/mobile_flutter/lib/providers/entry_provider.dart`, `apps/mobile_flutter/lib/services/supabase_entry_service.dart`
- Absences:
  - `AbsenceProvider.loadAbsences(year)` -> `SupabaseAbsenceService.fetchAbsencesForYear(userId, year)`
  - Files: `apps/mobile_flutter/lib/providers/absence_provider.dart`, `apps/mobile_flutter/lib/services/supabase_absence_service.dart`
- Opening balance:
  - `ContractProvider.loadFromSupabase()` -> `ProfileService.fetchProfile()` reading `profiles.opening_flex_minutes` + `profiles.tracking_start_date`
  - Files: `apps/mobile_flutter/lib/providers/contract_provider.dart`, `apps/mobile_flutter/lib/services/profile_service.dart`, `apps/mobile_flutter/lib/models/user_profile.dart`
- Time adjustments:
  - `BalanceAdjustmentProvider.loadAdjustments(year)` -> `BalanceAdjustmentRepository.listAdjustmentsForYear(...)` on `balance_adjustments`
  - Files: `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart`, `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart`, `apps/mobile_flutter/lib/models/balance_adjustment.dart`
