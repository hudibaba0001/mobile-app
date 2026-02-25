# Bug Report: Application Logic

After analyzing the application's source code static analysis, automated test results, and manually reviewing core logic modules (especially around time calculation and data fetching), I've discovered three specific logic bugs that should be addressed:

## 1. Silent Error Swallowing in `UserRedDayRepository`
**Location:** `lib/repositories/user_red_day_repository.dart`, inside the `getForDate` method.
**The Bug:** The method is wrapped in a `try/catch` block where any exception (such as a Supabase timeout, offline mode, or network failure) is caught and silently handled by returning `null`.
**The Impact:** Returning `null` signals to the calling logic that *no red day exists* for that date. If the user calculates their balance while offline or experiencing transient network errors, the app will falsely attribute regular working hours to a public/personal holiday, silently corrupting time sheet calculations. Proper behaviour would be to rethrow the error so the UI can show an "offline" or "error calculating" state instead of lying about the result.

## 2. Daylight Saving Time (DST) Infinite Loop Risk
**Location:** `lib/utils/target_hours_calculator.dart`, inside the `scheduledMinutesInRange` method.
**The Bug:** The method calculates the total scheduled minutes in a date range by looping through each day, incrementing the current date using:
```dart
current = current.add(const Duration(days: 1));
```
**The Impact:** Under the hood, `Duration(days: 1)` adds exactly 24 hours. Because the date is a local `DateTime` object, adding exactly 24 hours when crossing a DST transition where the clock goes backwards (e.g., 3:00 AM to 2:00 AM) can result in the same calendar date but a different hour. If the new `current` time does not advance to the next day (`current.isAfter(endNormalized)` stays false), this triggers an infinite loop and crashes the app. The proper way to add days to a local `DateTime` object is `DateTime(current.year, current.month, current.day + 1)`.

## 3. Flawed Cumulative Balance Calculations
**Location:** `lib/utils/time_balance_calculator.dart`, specifically in methods like `calculateYearlyBalance`.
**The Bug:** The method calculates the yearly balance by looping through a list of `MonthlySummary` and doing:
```dart
final monthlyVariance = summary.actualWorkedHours - targetHours;
```
**The Impact:** `targetHours` is passed as a flat parameter (defaulting to 160.0). This means the exact same flat target is applied to *every single month* in the loop, completely ignoring the fact that actual target hours vary month-by-month depending on the number of weekdays and holidays (as correctly established in `TargetHoursCalculator`). This results in cumulative yearly balances drifting and being mathematically incorrect unless the caller is intentionally attempting an unweighted average.

## 4. State Wipe on Unmounted Context
**Location:** `lib/providers/travel_provider.dart`, inside the `_getEntryProvider` method.
**The Bug:** The travel provider attempts to fetch the `EntryProvider` from the navigator key's current context. If the context is unmounted or `Provider.of` throws an exception, it silently catches the error and returns `null`. Later in `_loadEntries`, if `_getEntryProvider()` returns null, it completely wipes out `_entries = []` instead of retaining the existing entries.
**The Impact:** If the app triggers a refresh while the navigator is briefly unavailable or transitioning (e.g., during app startup from a deep link or background fetch), all Travel entries disappear from the UI without any error message or loading indication. The state is destroyed due to a failed context lookup.

## 5. Vulnerability to DST Phase Shifts in ISO Week Calculation
**Location:** `lib/providers/time_provider.dart`, inside the `_getISOWeekNumber` method.
**The Bug:** The app calculates the number of weeks elapsed since the first week of the year using `date.difference(week1Start).inDays ~/ 7`.
**The Impact:** `Duration.inDays` evaluates to `inHours ~/ 24`. If the user passes a DST boundary (e.g., the 'Spring Forward' clock change where an hour is lost), a full 7-day calendar week will mathematically contain only 167 hours, not 168. 167 divided by 24 evaluates to 6 days instead of 7. Thus, for *every week* that occurs after the spring DST time change, the week number calculation will be off by exactly 1 week. Date math across calendar days must never be performed via exact hours/milliseconds differences on local `DateTime` objects.

## 6. Fire-and-Forget Floating Async Operations 
**Location:** Multiple files, but prominently `lib/screens/unified_home_screen.dart` (e.g., `entryProvider.loadEntries().then(...)`).
**The Bug:** Important initialization and background processes (syncing, data loading) are triggered using `Future.then` or simply called asynchronously without `await` and without `catchError` handlers attached to the top-level future. 
**The Impact:** Since these futures are floating, any unhandled exceptions occurring inside the asynchronous tree will be completely swallowed or thrown into the void, preventing the UI from responding to failures. If `loadEntries` fails due to network or timeout, the `.then` block might never execute or might execute in an invalid state, leaving the home screen loading indefinitely or missing vital user data without any visual indication of failure.

### Bug 7: Permanent Silent Data Loss on Sync Timeout
**Location:** `SyncQueueService` (`removeOperation`, `processQueue`) combined with `EntryProvider` (`_loadEntries` cache synchronization).

**Description:** When an offline entry fails to upload (e.g. 500 error or network flap), it is put in the queue. If it fails standard retry mechanisms and is ultimately wiped from the queue through `removeOperation` by an internal fail-safe or bounds limit, the offline entry remains in the local Hive cache. 
However, the next time `_loadEntries` fires and effectively queries the active server sync queue (where the item doesn't exist), the `EntryProvider` performs a forced cache synchronization and **deletes the offline entry from Hive** because it is not mapped against the cloud data. The user loses their entry permanently without any UI notification.

**Impact:** **CRITICAL**. Silent data loss of user entries under a very realistic edge condition (network flapping or prolonged instability).

**Suggested Fix:**
Entries originating from the offline cache should be tagged (e.g. `is_synced: false`), and cache-truncation logic inside `_loadEntries` shouldn't blindly delete untracked entries unless they match specific synchronization criteria.

---

### Bug 8: Missing Double-Submission / Race Condition Prevention in Absence Form
**Location:** `AbsenceEntryDialog` (`_saveAbsence` function).

**Description:** The absence logging dialog does not manage a busy state or loading mechanism while the absence entry saves. Because `_saveAbsence` is an async function calling the `AbsenceProvider`, the user can rapidly tap the "Save" button multiple times. Since Flutter dialogs don't block interaction by default on async operations, the sequence `_saveAbsence()` will enqueue multiple identical absence creations to the backend before the `Navigator.pop(context)` finishes executing.

**Impact:** MEDIUM. Allows duplicate entries to be pushed up to the provider state, polluting the timeline.

**Suggested Fix:**
Add an `_isLoading` flag to the dialog's state. When `_saveAbsence` is tapped, set `_isLoading = true;` and `setState`. Disable the save button or show a `CircularProgressIndicator` while saving.

---

### Bug 9: Localization-Dependent Export Totals Corruption
**Location:** `ExportService` (`_isEntryExportTotalsRow` function vs `_prepareReportEntriesExportData`).

**Description:** `ExportService` checks if a row is the total summary block using `row[_colType].toString().trim().toUpperCase() == 'TOTAL'`. However, earlier in the process, the totals row sets this column using the localized AppLocalizations string (`t.export_total`). If the user’s language is set to Swedish, `export_total` translates to `"Totalt"`. The `.toUpperCase()` == 'TOTAL' condition evaluates to `false`. 
Instead of dropping out, the row progresses into the normal format builder which processes it as an entry, assigning `_formatEntryTypeForReport`. Afterwards, the export logic injects a *second* separate totals row, creating duplicate corrupted tally rows at the bottom of the export for non-English speakers.

**Impact:** HIGH. Broken export output generation heavily dependent on locale choice.

**Suggested Fix:**
Replace the hardcoded `'TOTAL'` string search with a robust condition:
```dart
bool _isEntryExportTotalsRow(List<dynamic> row, AppLocalizations t) {
  return row.length > _colType &&
      row[_colType].toString().trim() == t.export_total;
}
```

---

### Bug 10: UI DST Day Count Undercounting Vulnerability
**Location:** `DateRangePickerWidget` (`build` function).

**Description:** When showing the selected date gap length in the calendar UI, the application computes `_endDate!.difference(_startDate!).inDays + 1;`.
Because `_startDate` and `_endDate` are selected at `00:00:00` in Local Time by the Material date picker, any timespan stretching across the "Spring Forward" transition will have an internal difference of 23 hours instead of 24. Dart's `.difference().inDays` relies strictly on integer duration division. `(23 hours).inDays` evaluates to `0`. Consequently, `0 + 1` leads to an undercount in the displayed calendar length (1 day instead of 2 days represented).

**Impact:** LOW. Causes visual confusion and inaccurate day spans represented to the user during DST edge cases.

**Suggested Fix:**
Date boundaries purely for calendar counts should be calculated using math logic disregarding time gap representation, or using UTC:
```dart
DateTime d1 = DateTime.utc(_startDate!.year, _startDate!.month, _startDate!.day);
DateTime d2 = DateTime.utc(_endDate!.year, _endDate!.month, _endDate!.day);
int days = d2.difference(d1).inDays + 1;
```

---

### Bug 11: SetState Race Conditions on Unmounted Forms
**Location:** `UnifiedEntryForm` (`_saveEntry` function) and various other UI Dialogs calling long-running backend providers (e.g. `_loadRecentLocations` in `LocationSelector`).

**Description:** Forms handling asynchronous data fetches, location retrieval (via `await _locationProvider.fetch...`), or heavy database operations (via `await _entryProvider.addEntries(...)`) routinely wrap UI updates inside `setState(() { ... })` *after* an `await` gap. However, the majority of these callbacks are missing the critical `if (!mounted) return;` check.

**Impact:** HIGH. If the user navigates away from a form (e.g. presses the back button or home tab) *while* a save or location fetch operation is pending globally, the `await` finishes execution and immediately attempts to call `setState` on a disposed widget. Flutter will throw a `FlutterError: setState() called after dispose()` which crashes the rendering pipeline or causes unhandled promise rejections on the screen. 

**Suggested Fix:**
Enforce strict `if (!mounted) return;` safety checks directly after *every* `await` statement inside any `StatefulWidget` prior to accessing context, modifying local variable state, or calling `setState`.
