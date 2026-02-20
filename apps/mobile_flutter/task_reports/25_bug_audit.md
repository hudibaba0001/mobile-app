# Bug Audit Report

- **Number:** 25
- **Created:** 2026-02-20T21:45:00
- **Type:** Bug Audit (read-only, no code changes)

## Summary

Static analysis (`flutter analyze`) passes clean with **zero issues**. No stray `print()` statements in production code. `mounted` checks are broadly applied across async-gap callsites. However, manual code review uncovered **10 bugs** across providers, services, and utilities — ranging from data-loss risks to incorrect balance calculations.

---

## 🔴 High Severity

### Bug 1 — `clearDemoEntries()` double-removes entries
**File:** `lib/providers/entry_provider.dart` (lines 606–647)

The method calls `deleteEntry()` in a loop, which **removes the entry from `_entries`** internally (line 550). After the loop it does `_entries.removeWhere(...)` again on the same list. The second removal is harmless only because entries are already gone — but if `deleteEntry()` throws mid-loop, the remaining entries are left orphaned from the local list.

More importantly, the loop is iterating over `demoEntries` (a filtered snapshot), while `deleteEntry()` is mutating `_entries` concurrently. If `deleteEntry()` throws partway through, some entries will be removed from `_entries` but the `_entries.removeWhere(...)` at line 632 tries to remove them again — meaning it could miss entries that were NOT deleted due to the exception.

**Impact:** Inconsistent state between in-memory list and Supabase/cache after partial failure.

---

### Bug 2 — `TravelProvider` mutations don't persist to Supabase
**File:** `lib/providers/travel_provider.dart` (lines 120–171)

`addEntry()`, `updateEntry()`, and `deleteEntry()` in `TravelProvider` only modify the **local in-memory list**. They do NOT delegate to `EntryProvider` (which handles Supabase + Hive persistence). Comment at line 123 confirms this: *"For now, we'll just add to the local list"*.

Any travel entry added, updated, or deleted through `TravelProvider` will be **lost on app restart**.

**Impact:** Data loss — travel entries are not persisted.

---

### Bug 3 — `_WeekKey.hashCode` is inconsistent with `==`
**File:** `lib/providers/time_provider.dart` (lines 1080–1099)

The `==` operator compares `weekNumber`, `weekStart.year`, `weekStart.month`, and `weekStart.day`. But `hashCode` uses `weekNumber.hashCode ^ weekStart.hashCode`, where `weekStart.hashCode` includes the full `DateTime` (with hours/minutes/seconds). Two `_WeekKey` objects that are `==` equal can produce different hash codes if their `weekStart` DateTime objects have different time components.

**Impact:** Entries grouped by week may not be found in the Map, leading to **incorrect weekly balance calculations** (duplicate week groups, missing entries from sums).

---

### Bug 4 — `getDetailedBalance()` ignores tracking start date
**File:** `lib/providers/time_provider.dart` (lines 619–685)

`calculateBalances()` correctly skips days before `trackingStartDate` (line 334). But `getDetailedBalance()` rebuilds monthly target minutes day-by-day (line 647) **without** filtering for `trackingStartDate`. This means the target hours shown in the detailed UI view will be higher than what was actually used for the variance calculation, making the breakdown inconsistent with the summary.

**Impact:** Detailed balance view shows incorrect target hours for partial months.

---

## 🟡 Medium Severity

### Bug 5 — `clearFilters()` bypasses `_applyFilters()`
**File:** `lib/providers/entry_provider.dart` (lines 590–597)

```dart
void clearFilters() {
    _filteredEntries = _entries;  // Direct assignment — shares the reference
    ...
}
```

This assigns `_filteredEntries` to the same reference as `_entries`. Any later call to `_entries.add(...)` or `_entries.removeWhere(...)` will also mutate `_filteredEntries` unexpectedly. In contrast, `_applyFilters()` and `loadEntries()` create a copy with `List.from(_entries)`. This inconsistency can cause the filtered list to drift from expected state.

**Impact:** Stale or unexpected items in `filteredEntries` after mutations following a `clearFilters()` call.

---

### Bug 6 — `SyncQueueService.enqueue()` deduplication matches by `(entryId, type)` but ID changes
**File:** `lib/services/sync_queue_service.dart` (lines 117–136 vs 139–160)

`enqueue()` checks for duplicates by `(entryId, type)` and replaces matching operations. However, `queueCreate()` and `queueUpdate()` generate unique IDs (`create_${entry.id}_${timestamp}`). When an update replaces an existing update in the queue, the **new SyncOperation has a different `.id`** but `enqueue()` replaces the queue item at the found index — this is correct for dedup, but `remove(operationId)` won't find the old ID anymore. If any external code cached the old operation ID, it becomes stale.

Additionally, if you queue a `create` for entry X, then queue another `create` for the same entry X, the second create blindly replaces the first — but both should arguably be collapsed or the second rejected since the entry was already queued for creation.

**Impact:** Potential for phantom sync operations or lost updates in edge cases.

---

### Bug 7 — `_getScheduledMinutesForDate` skips non-red-day personal holidays
**File:** `lib/providers/time_provider.dart` (lines 148–173)

When `_holidayService` is available, the method calls `getRedDayInfo(date)`. If the result is **not** a red day (`isRedDay == false`), it falls through to the basic `SwedenHolidayCalendar`. This means the basic calendar checks are applied **without** consulting `_holidayService` for non-red-day adjustments. If `HolidayService` and `SwedenHolidayCalendar` ever diverge (e.g., updated holiday data), the fallback may give stale results.

More concretely, when `_holidayService` is available, the fallback still uses the static `SwedenHolidayCalendar` instead of going through the service — there is no consistency guarantee between the two.

**Impact:** Possible incorrect scheduled minutes on edge-case dates where the two holiday sources differ.

---

### Bug 8 — `_loadEntriesInternal()` doesn't clear stale Hive entries on full cloud sync
**File:** `lib/providers/entry_provider.dart` (lines 700–721)

`_syncToLocalCache()` iterates over cloud entries and saves them to Hive via `put()`, but never deletes Hive keys that no longer exist on the server. If an entry was deleted on the server (or from another device), the stale entry remains in Hive and will reappear as a "local entry" on the next offline load.

**Impact:** Ghost entries resurface when the app goes offline after cloud-side deletion.

---

## 🟢 Low Severity

### Bug 9 — Hardcoded `'0'` in manage_locations_screen
**File:** `lib/screens/manage_locations_screen.dart` (line 319)

```dart
'0', // TODO: Implement usage tracking
```

Location usage count is always displayed as "0" regardless of actual usage.

**Impact:** UI inaccuracy — purely cosmetic.

---

### Bug 10 — `TravelProvider` initializes with a 30-day filter window
**File:** `lib/providers/travel_provider.dart` (lines 16–17)

```dart
DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
DateTime _filterEndDate = DateTime.now();
```

These are set once in the field initializer and **never updated** when the app runs for extended periods. After 30 days of running, the default filter excludes new entries.

Additionally, `_filterEndDate` is set to `DateTime.now()` at construction time — any entries logged after constructing the provider won't be in the default filter unless the user explicitly resets the date range.

**Impact:** Users may not see recent travel entries without manually adjusting filters.

---

## TODOs / Code-Debt Noted

| Location | Note |
|---|---|
| `travel_provider.dart:9` | `TODO: Migrate consumers to use EntryProvider directly` |
| `manage_locations_screen.dart:319` | `TODO: Implement usage tracking` |
| `manage_locations_screen.dart:345` | `TODO: Implement search functionality` |
| `admin_users_view_model.dart:40` | `TODO: Implement role-based filtering` |

---

## Recommended Priority

1. **Bug 2** (TravelProvider data loss) — most likely to cause user-facing data loss
2. **Bug 3** (`_WeekKey` hashCode) — affects accuracy of weekly balance calculations
3. **Bug 4** (tracking start date in detailed view) — incorrect balance display
4. **Bug 8** (Hive stale entries) — ghost entries after cloud deletion
5. **Bug 1** (clearDemoEntries double-remove) — risk during demo cleanup
6. **Bug 5** (clearFilters reference sharing) — subtle state drift
7. Everything else
