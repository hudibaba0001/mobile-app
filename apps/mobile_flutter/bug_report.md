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

---

### Bug 12: Lack of Transactionality and Rollback in Batch Submission
**Location:** `EntryProvider` (`addEntries` function) combined with `UnifiedEntryForm`.

**Description:** When saving multi-leg travel entries or chained work shifts, `addEntries` loops over the list of items to push them to Supabase. However, this is not an atomic transaction. If the loop successfully pushes item 1 and item 2, but throws a fatal unhandled backend error on item 3, the loop terminates early and throws an `Exception`. The UI catches this, displays an error message ("Error saving entry"), and aborts. 
Critically, *no rollback* is performed for item 1 and item 2. Even worse, the successfully saved partial items are appended to the local cache, leaving the user with orphaned journey legs that do not accurately represent their submission.

**Impact:** HIGH. Inability to guarantee atomic constraints on complex forms leads directly to silently corrupted sequences (e.g. missing connection legs for travel).

**Suggested Fix:**
Submit batch structures via a dedicated backend RPC endpoint that uses PostgreSQL transactions to commit all operations at once. Alternatively, implement a local saga pattern that actively rolls back previous `Supabase` creates and `Hive` writes if a fatal error occurs halfway through the batch execution array.

---

### Bug 13: Silent Data Loss / Validation Bypass on Multi-Segment Form
**Location:** `MultiSegmentForm` (`_submitJourney` function).

**Description:** When the user fills out a travel segment (e.g., Departure, Arrival) but types invalid or missing travel time (e.g., -5 minutes or empty), clicking the main "Save Journey" button triggers `_submitJourney`. This function correctly flags the current segment as invalid (`_validateCurrentSegment` returns `false` and shows an error snackbar). 
However, if there is already at least 1 *valid* previous segment held in `_segments`, the code silently continues execution, bypassing the `return` statement below it and saving the journey. Instead of halting the form submission to let the user fix their typo, it immediately saves all *previous* valid segments and **silently throws away the invalid segment the user was just typing**, closing the dialog.

**Impact:** MEDIUM. Data truncation condition where actively-edited segments are discarded without blocking form submission, leading to missing timecard components.

**Suggested Fix:**
Halt `_submitJourney` immediately if the active segment has data but fails validation:
```dart
    if (_hasCurrentSegmentData()) {
      if (!_validateCurrentSegment()) {
        return; // Halt form submission completely!
      }
      _addSegment();
    }
```

---

### Bug 14: Auth Guard Bypass Permitting Dead Routes
**Location:** `AppRouter` (`redirect` parameter in `GoRouter`).

**Description:** The main routing guard correctly blocks unauthenticated users from accessing protected views. However, the logic explicitly approves access to `signupPath` and `forgotPasswordPath` bypassing the default redirect logic:
```dart
      if (isForgotPassword || isSigningUp) {
        return null; // meaning stay
      }
```
If an *actively authenticated* user explicitly taps a deep link or back-navigates to the `/signup` or `/forgot-password` routes, the app allows them to render the signup flow instead of intercepting them and redirecting them to the `/` (Home) screen. 

**Impact:** LOW. An authenticated user can render auth gates unnecessarily, potentially causing Supabase token collisions if they attempt to sign up over top of a valid session.

**Suggested Fix:** Ensure that `AppRouter` checks the user's authentication state. If `isAuthenticated` is true, explicitly redirect these users away from auth routes and into the `homePath` (e.g. `if (isForgotPassword || isSigningUp) { return isAuthenticated ? homePath : null; }`).

### Bug 15: Unhandled HTTP 401 Unauthorized Expirations in Custom API Services
**Location:** `AdminApiService`, `ProfileService`, `BillingService` (all files using direct `http` package calls).

**Description:** Several services manually construct `http.post` and `http.get` requests to custom edge functions or backend APIs using the Supabase auth token. When these requests receive a `401 Unauthorized` response (due to token expiry or revocation), they throw generic Exceptions instead of intercepting the 401 to trigger a token refresh or force a logout. The Supabase SDK handles its own 401s automatically, but the custom endpoints operate entirely outside this safety net.
**Impact:** If a user’s token expires in the background and their next action triggers a custom HTTP endpoint (like fetching the admin dashboard or checking legal versions), the app will throw a generic Exception, potentially trapping the user in a broken UI state without redirecting them to log in.
**Fix:** Create a centralized HTTP client or interceptor for all custom API calls that catches `401` responses and invokes `SupabaseAuthService` to refresh the session or log the user out.

### Bug 16: Data Corruption Vulnerability due to Non-Transactional Relational Updates
**Location:** `SupabaseEntryService.updateEntry` and `SupabaseEntryService.deleteEntry` (in `supabase_entry_service.dart`).

**Description:** When updating a complex entry (like a multi-leg travel journey or multi-shift work day), `updateEntry` first deletes all existing child records via `await _supabase.from(_travelSegmentsTable).delete().eq('entry_id', entry.id);`, and then attempts to insert the new child records iteratively over the network. If the network drops, the app crashes, or a backend constraint validation fails during the insert phase, the operation halts.
**Impact:** Severe data corruption. The parent `Entry` will remain in the database entirely stripped of its required children. This permanently corrupts the user’s logged time since there is no transaction rollback mechanism.
**Fix:** Migrate all multi-table or batch operations (like `updateEntry` and `deleteEntry`) to Supabase RPC (Remote Procedure Call) functions to ensure they execute within a single ACID-compliant PostgreSQL transaction.

### Bug 17: Timezone Boundary Drift Vulnerability on Backend Sync
**Location:** `Entry.toJson` and `Shift.toJson` (in `lib/models/entry.dart`).

**Description:** When serializing Local `DateTime` objects to Supabase, the app uses `.toIso8601String()`. For example, a shift starting at `10:00 AM` local time becomes `"2025-02-25T10:00:00.000"`. Because this output lacks a timezone offset indicator (like `+02:00` or `Z`), when PostgREST casts it into a `timestamp with time zone` (timestamptz) column, it implicitly assumes it applies to the server's default timezone (usually UTC). It stores it as `10:00:00 UTC`. 
When the user subsequently fetches this entry, `DateTime.parse()` reads it as `10:00:00 UTC`, and then rendering it converts it *back* to local time, resulting in a time shift. Additionally, for the midnight-anchored `date` field, this shift can inadvertently roll the entry backward or forward by an entire calendar day.
**Impact:** High. Silent modification of user shift boundary times, duration calculations, and entry dates depending on the user's timezone relative to the backend's timezone.
**Fix:** Always standardize serialization. Convert `DateTime` objects to UTC before formatting them, e.g. `start.toUtc().toIso8601String()`, or append `.toUtc()` to ensure the `Z` suffix is present during insertion.

### Bug 18: Race Condition on Purchase Verification during Billing Restorations
**Location:** `BillingService._handlePurchaseUpdates` (in `billing_service.dart`)

**Description:** The Google Play purchase stream uses `listen(_handlePurchaseUpdates)`. `listen` is asynchronous and doesn't `await` its callback. If the system emits multiple purchase details at once (which is very common when restoring past purchases or resolving a backlog of pending transactions), `_handlePurchaseUpdates` fires concurrently. Since `_handlePurchaseUpdates` mutates the shared boolean `_isProcessingPurchase` and triggers parallel HTTP POST requests to `_verifyPurchaseWithBackend`, this leads to observable race conditions.
**Impact:** Medium. This causes the Paywall UI to glitch (flickering loading states), overlapping UI redraws, and unnecessarily spams the backend verification endpoint during wide-scale restoration events.
**Fix:** Use an asynchronous stream queue mapper (like `asyncMap` or the `synchronized` lock pattern) to ensure that incoming purchase restoration events are sequenced and verified one by one.

### Bug 19: Uncached Futures Causing Spurious Re-executions
**Location:** `ProfileScreen.build` (in `profile_screen.dart`), inside `FutureBuilder<PackageInfo>`.

**Description:** In `ProfileScreen` (a StatefulWidget), the `FutureBuilder`'s `future:` parameter is supplied by calling `PackageInfo.fromPlatform()`. Because this is executed directly inside the declarative `build()` method, every time the widget rebuilds (due to keyboard appearance, parent updates, or state changes), a brand new Future is created and fires a call to platform channels. The widget instantly drops the old Future and resets itself to the `waiting` ConnectionState, causing the UI to flicker unnecessarily and spamming the native platform bridge.
**Impact:** Low. Visual flicker during hot-reloads or state updates, and unnecessary strain on the platform channel. (This anti-pattern may also exist in other isolated areas).
**Fix:** For any `FutureBuilder` wrapped inside a `StatefulWidget`, instantiate the `Future<T>` inside `initState()`, store it as a late or nullable class member variable (e.g., `_packageInfoFuture`), and pass that variable to the `FutureBuilder` to safely cache the resolution across rebuilds.

### Bug 20: Race Condition Overwriting Local State on Concurrent Fetches
**Location:** `AbsenceProvider.loadAbsences` combined with `addAbsence`/`removeAbsence` mutations.

**Description:** When a user adds or deletes an absence, the provider performs the mutation against Supabase and immediately calls `await loadAbsences(forceRefresh: true)`. Because `loadAbsences` contains `await` gaps while fetching from the network, it does not lock against parallel executions. If a user rapidly adds/deletes two absences, two `loadAbsences` fetch calls overlap. If the network responds to the *first* underlying fetch request *slower* than the second fetch request, the old state payload will aggressively overwrite the new state payload in `_absencesByYear[year] = absences`.
**Impact:** Medium. The UI state desynchronizes from the backend truth, visually "undoing" the user's latest action until a subsequent manual refresh correctly synchronizes the cache.
**Fix:** Implement a sequence lock, cancellation token constraint, or an asynchronous operation queue for `loadAbsences` to ensure that older overlapping network requests cannot overwrite the state mapped by newer requests.

### Bug 21: Unbounded Query Risk in `BalanceAdjustmentRepository.listAllAdjustments`
**Location:** `BalanceAdjustmentRepository.listAllAdjustments` (in `balance_adjustment_repository.dart`).

**Description:** The method calls `.from('balance_adjustments').select().eq('user_id', userId)` unconditionally without applying a `.limit()` or pagination strategy. If a user accumulates hundreds or thousands of adjustments over multiple years (e.g., daily micro-adjustments or automated corrections), this single query fetches the entire dataset from Supabase into memory at once.
**Impact:** Low/Medium scaling risk. As the dataset grows, this unbounded query could lead to significantly increased latency, a large memory footprint spike, and potential UI stutter/dropped frames on older mobile devices when parsing the JSON tree.
**Fix:** Instead of pulling the entire table history to compute balances, calculate cumulative lifetime balances via a backend PostgreSQL RPC. If the raw rows are needed for UI history, implement `.range(start, end)` pagination or infinite scrolling.

### Bug 22: Midnight Boundaries Misattributing Time to Root Date
**Location:** `TimeProvider.calculateBalances` and `Entry.totalDuration`

**Description:** When calculating variances and tracked hours, `TimeProvider` iterates through entries and groups them rigidly by `entry.date`. However, if an entry has shifts crossing midnight (e.g., from 22:00 on Dec 31st to 06:00 on Jan 1st), the `Entry.totalDuration` (which is 8 hours) is credited entirely to `entry.date` (Dec 31st). 
**Impact:** High data accuracy issue. Because the hours are not linearly split across the midnight barrier into the correct calendar days, end-of-month and end-of-year variance calculations become skewed. Hours genuinely worked on Jan 1st are falsely credited to the previous year, leaving the new year's variance severely negative.
**Fix:** Refactor `TimeProvider`'s aggregation algorithm to iterate over individual `entry.shifts` rather than blindly summing `entry.totalDuration`. If a `shift` crosses midnight, calculate the offset linearly and apply the fractional minutes up to 23:59:59 to the first day, and the remaining minutes to the subsequent day.

### Bug 23: Bottom Sheet Layout Overflow on Dense Entries
**Location:** `EntryDetailSheet.build` (in `entry_detail_sheet.dart`)

**Description:** The modal bottom sheet builds a `Column` with `mainAxisSize: MainAxisSize.min` containing `.addAll(_detailWidgets(context, entry))`. However, the root `Column` is not wrapped in a `SingleChildScrollView`. If an entry contains a long `notes` string or multiple `shifts`, the vertical height exceeds the device viewport.
**Impact:** Medium UI defect. The Flutter rendering engine throws a classic "Bottom overflowed by X pixels" yellow-and-black stripe error, rendering the 'Edit' and 'Delete' buttons unreachable.
**Fix:** Wrap the `Column`'s `children` (or the `Column` itself) inside an `Expanded` + `SingleChildScrollView`, or enclose it in a `ListView` to allow user scrolling when the content height exceeds the available safe area.

### Bug 24: Missing MethodChannel Exception Handling for Android 13+ Downloads
**Location:** `ExportService._saveCopyToDownloads` (in `export_service.dart`)

**Description:** The method `_saveCopyToDownloads` attempts to invoke the native platform channel `se.kviktime.app/file_export`. While the Dart side catches `PlatformException`, the actual Android implementation (`MainActivity.kt`) utilizes `MediaStore.Downloads` but completely lacks runtime permission requests for `WRITE_EXTERNAL_STORAGE` on devices running Android 10-12 (API 29-32) before attempting to write to the public Downloads folder. 
**Impact:** Medium data-availability issue. On many device configurations running older Android operating systems, triggering the "Export" feature will silently fail to place the file in the public Downloads folder due to a `SecurityException` thrown on the native side. The user is told the export succeeded (because the internal app storage write succeeded), but they cannot locate the file in their external Downloads app.
**Fix:** Implement a robust permission check using the `permission_handler` package before invoking the MethodChannel. If the OS version is below Android Q (API 29), explicitly request and await the `Permission.storage` grant before proceeding.
