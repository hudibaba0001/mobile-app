# Static Analysis Bug Report

**Project:** mobile-app (Flutter time-tracking)  
**Scope:** `apps/mobile_flutter/lib` (and related tests)  
**Method:** Code reading and pattern search only — no runtime instrumentation.  
**Date:** 2026-01-29  

This file logs all potential bugs and robustness issues found via static analysis. Severity is approximate; confirm with runtime evidence before fixing.

---

## Table of contents

1. [firstWhere / .single / .last / .first](#1-firstwhere--single--last--first-crash-risk)
2. [Supabase .single()](#2-supabase-single-crash-risk)
3. [Empty or silent catch blocks](#3-empty-or-silent-catch-blocks)
4. [int.parse / DateTime.parse / cast](#4-intparse--datetimeparse--cast-malformed-data)
5. [setState after async / dispose](#5-setstate-after-async--dispose)
6. [SegmentedButton / selection.first](#6-segmentedbutton--selectionfirst)
7. [Date string split and parts[]](#7-date-string-split-and-parts-index-out-of-range--parse)
8. [Substring / string bounds](#8-substring--string-bounds)
9. [UI / data binding](#9-ui--data-binding)
10. [Listener / lifecycle](#10-listener--lifecycle)
11. [RegExp / time parsing](#11-regexp--time-parsing)
12. [Other](#12-other)
13. [Timer / debounce – context or setState after dispose](#13-timer--debounce--context-or-setstate-after-dispose)
14. [Assert in production](#14-assert-in-production)
15. [Navigator / ScaffoldMessenger without mounted](#15-navigator--scaffoldmessenger-without-mounted)
16. [Async started in initState / context after await](#16-async-started-in-initstate--context-after-await)
17. [Dynamic / untyped map access](#17-dynamic--untyped-map-access)
18. [FormState / GlobalKey.currentState](#18-formstate--globalkeycurrentstate)
19. [indexOf / index edge cases](#19-indexof--index-edge-cases)
20. [Extension on dynamic / unsafe map access](#20-extension-on-dynamic--unsafe-map-access)
21. [Hive / box access](#21-hive--box-access)
22. [Persisted JSON type / decode](#22-persisted-json-type--decode)
23. [Equality / hashCode with nullable id](#23-equality--hashcode-with-nullable-id)
24. [Nullable id used with ! when editing](#24-nullable-id-used-with--when-editing)

---

## Summary

| Category | Count | Severity focus |
|----------|-------|----------------|
| firstWhere / .single / .last / .first | 8 | High (crashes) |
| Empty or silent catch | 6+ | Medium (debugging) |
| int.parse / DateTime.parse / cast | 15+ | Medium (malformed data) |
| setState after async / dispose | 4 | Medium |
| Null assertion / index without check | 5 | Low–Medium |
| Date string split / parts[] | 6 | Medium |
| Supabase .single() | 4 | High |
| Timer / debounce after dispose | 2 | Medium |
| Assert (debug-only) | 2 | Low |
| Navigator / context after async | 3 | Medium |
| Async in initState / context after await | 2 | Medium |
| Dynamic / map access | 2 | Low |
| FormState currentState! | 4+ | Low |
| indexOf / index edge cases | 2 | Low |
| Extension on dynamic / Hive / JSON / equality | 4 | Low–Medium |
| Nullable id! when editing (BalanceAdjustment) | 1 | Medium |
| Other (arrow char, substring, API cast) | 5 | Low |

---

## 1. firstWhere / .single / .last / .first (crash risk)

### 1.1 LeaveEntry.fromJson – firstWhere without orElse (HIGH)
- **File:** `apps/mobile_flutter/lib/models/leave_entry.dart`
- **Lines:** 97–99
- **Code:** `LeaveType.values.firstWhere((e) => e.toString().split('.').last == json['type'])`
- **Issue:** No `orElse`. If API returns unknown or misspelled `type`, throws `StateError: No element` and can crash the app when loading leave entries.
- **Contrast:** `Entry.fromJson` and `SyncOperation.fromJson` use `orElse` for the same pattern.

### 1.2 LocationProvider – firstWhere without orElse (MEDIUM)
- **File:** `apps/mobile_flutter/lib/providers/location_provider.dart`
- **Lines:** 314–315, 332–333
- **Code:** `_repository.getAll().firstWhere((loc) => loc.id == locationId)`
- **Issue:** If `locationId` is invalid (deleted location, stale ID), `firstWhere` throws. Wrapped in try/catch so no crash, but error is generic; implementation is brittle.

### 1.3 TimeProvider – getCurrentMonthSummary / getCurrentWeekSummary return type (LOW)
- **File:** `apps/mobile_flutter/lib/providers/time_provider.dart`
- **Lines:** 620–631, 1085–1097
- **Issue:** Return type is `MonthlySummary?` / `WeeklySummary?` but `orElse` always supplies a value, so return is never null. Type is misleading; could be simplified to non-nullable.

### 1.4 unified_home_screen – firstWhere in try/catch (MEDIUM)
- **File:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Lines:** 1426, 1432, 1466, 1476
- **Issue:** `provider.entries.firstWhere((e) => e.id == summary.id)` and similar. Exceptions caught and ignored (or set to null). Failure is silent; UI may show nothing or stale data.

### 1.5 entry_provider – getEntry for delete (MEDIUM)
- **File:** `apps/mobile_flutter/lib/providers/entry_provider.dart`
- **Lines:** 523–526
- **Issue:** `_entries.firstWhere((e) => e.id == id)` in try/catch; if not found, throws then sets entry = null and later throws "Entry not found". Correct flow but relies on catch; easy to break.

### 1.6 SyncQueueService.fromJson (LOW – has orElse)
- **File:** `apps/mobile_flutter/lib/services/sync_queue_service.dart`
- **Lines:** 51–53
- **Note:** Uses `orElse: () => SyncOperationType.create`. Safe.

### 1.7 HolidayService getPersonalRedDay (LOW – has orElse)
- **File:** `apps/mobile_flutter/lib/services/holiday_service.dart`
- **Lines:** 262–264
- **Note:** Uses `orElse: () => null`. Safe.

### 1.8 Test – report_query_service_test .single (LOW)
- **File:** `apps/mobile_flutter/test/reports/report_query_service_test.dart`
- **Lines:** 120, 124
- **Issue:** `requestedEntryRanges.single` — if test data yields 0 or 2+ elements, throws. Test can become flaky.

---

## 2. Supabase .single() (crash risk)

### 2.1 user_red_day_repository
- **File:** `apps/mobile_flutter/lib/repositories/user_red_day_repository.dart`
- **Lines:** 105–109
- **Code:** `upsert(...).select().single()`
- **Issue:** PostgREST `.single()` throws if 0 or 2+ rows. RLS or triggers could cause unexpected result set.

### 2.2 supabase_absence_service
- **File:** `apps/mobile_flutter/lib/services/supabase_absence_service.dart`
- **Lines:** 52–53
- **Code:** `insert(data).select().single()`
- **Issue:** Same as above.

### 2.3 supabase_entry_service
- **File:** `apps/mobile_flutter/lib/services/supabase_entry_service.dart`
- **Lines:** 322–323
- **Code:** `insert(entryData).select().single()`
- **Issue:** Same as above.

### 2.4 balance_adjustment_repository
- **File:** `apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart`
- **Lines:** 96–98 (insert), 130–132 (update + select)
- **Issue:** Insert: same .single() risk. Update: if no row matches (e.g. wrong id), .single() throws.

---

## 3. Empty or silent catch blocks

### 3.1 unified_home_screen
- **File:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Lines:** 1427, 1433
- **Code:** `} catch (_) {}`
- **Issue:** Exceptions from firstWhere (entry not found) are swallowed. No log; hard to debug.

### 3.2 unified_home_screen – edit flow
- **Lines:** 1467, 1477
- **Code:** `} catch (_) { existing = null; }` and similar for refreshed
- **Issue:** Same; failure is silent.

### 3.3 signup_screen
- **File:** `apps/mobile_flutter/lib/screens/signup_screen.dart`
- **Line:** 159
- **Code:** `} catch (_) {}` (around signOut after legal error)
- **Issue:** Sign-out failure is ignored.

### 3.4 travel_provider
- **File:** `apps/mobile_flutter/lib/providers/travel_provider.dart`
- **Line:** 31
- **Code:** `} catch (_) {}`
- **Issue:** Error during some travel operation is swallowed.

### 3.5 profile_screen
- **File:** `apps/mobile_flutter/lib/screens/profile_screen.dart`
- **Line:** 483
- **Code:** `} catch (_) {}`
- **Issue:** Sign-out or related failure is ignored.

### 3.6 account_status_gate
- **File:** `apps/mobile_flutter/lib/screens/account_status_gate.dart`
- **Lines:** 189–190
- **Code:** `} catch (_) { /* Keep prior required versions */ }`
- **Issue:** Legal versions fetch failure is silent; no log.

### 3.7 legal_document_dialog
- **File:** `apps/mobile_flutter/lib/widgets/legal_document_dialog.dart`
- **Lines:** 87–88
- **Code:** `} catch (_) { response = null; }`
- **Issue:** Load failure is swallowed; no log.

---

## 4. int.parse / DateTime.parse / cast (malformed data)

### 4.1 quick_entry_form
- **File:** `apps/mobile_flutter/lib/widgets/quick_entry_form.dart`
- **Line:** 163
- **Code:** `travelMinutes: int.parse(_minutesController.text)`
- **Issue:** If validation is bypassed or validator bug, empty or non-numeric input causes FormatException. Prefer int.tryParse with fallback.

### 4.2 multi_segment_form
- **File:** `apps/mobile_flutter/lib/widgets/multi_segment_form.dart`
- **Line:** 117
- **Code:** `durationMinutes: int.parse(_minutesController.text)`
- **Issue:** Same as 4.1. Guarded by _validateCurrentSegment() but still fragile if logic changes.

### 4.3 contract_settings_screen
- **File:** `apps/mobile_flutter/lib/screens/contract_settings_screen.dart`
- **Lines:** 151–152
- **Code:** `int.parse(_contractPercentController.text.trim())`, `int.parse(_fullTimeHoursController.text.trim())`
- **Issue:** Only called when _isFormValid; if validators allow invalid text, throws.

### 4.4 contract_provider – tracking start date
- **File:** `apps/mobile_flutter/lib/providers/contract_provider.dart`
- **Lines:** 447–454
- **Code:** `final parts = savedStartDate.split('-'); if (parts.length == 3) { ... int.parse(parts[0]), ... }` in try/catch
- **Note:** Length check and try/catch present. If parts.length != 3 but parts has 3+ elements with non-numeric content, int.parse can still throw inside try — acceptable.

### 4.5 DateTime.parse / cast in models and services
- **Files:** user_profile.dart, entry.dart, leave_entry.dart, supabase_entry_service.dart, sync_queue_service.dart, user_red_day.dart, location.dart, balance_adjustment.dart, admin_user.dart, contract_settings.dart, user_entitlement.dart, travel_cache_service.dart, analytics_models.dart, billing_service.dart, profile_service.dart, admin_api_service.dart, analytics_api.dart
- **Issue:** Many uses of `DateTime.parse(...)` or `map['key'] as String` without tryParse or null-safe cast. Backend sending null, wrong type, or invalid string can cause crash.

### 4.6 jsonDecode / response body cast
- **Files:** profile_service.dart (86, 119), billing_service.dart (210), admin_api_service.dart (127, 174, 284), analytics_api.dart (45)
- **Code:** `jsonDecode(response.body) as Map<String, dynamic>`
- **Issue:** If body is not a JSON object (e.g. error HTML or array), cast throws.

---

## 5. setState after async / dispose

### 5.1 overview_tab
- **File:** `apps/mobile_flutter/lib/screens/reports/overview_tab.dart`
- **Line:** 174–175 (onRefresh)
- **Issue:** If setState is used after await without `if (!mounted) return`, risk of setState after dispose.

### 5.2 export_dialog
- **File:** `apps/mobile_flutter/lib/widgets/export_dialog.dart`
- **Lines:** 371, 379–380, 391, 403–408
- **Issue:** setState in export flow; ensure all async branches guard with `if (mounted)` before setState.

### 5.3 legal_document_dialog
- **File:** `apps/mobile_flutter/lib/widgets/legal_document_dialog.dart`
- **Lines:** 93–95, 103–108, 109–111
- **Issue:** Some paths check mounted; verify every setState after async has guard.

### 5.4 login_screen
- **File:** `apps/mobile_flutter/lib/screens/login_screen.dart`
- **Line:** 94
- **Code:** `_formKey.currentState!.validate()`
- **Issue:** If _signIn is ever called before first frame, currentState can be null; ! throws. Prefer currentState?.validate() ?? false.

---

## 6. SegmentedButton / selection.first

### 6.1 settings_screen
- **File:** `apps/mobile_flutter/lib/screens/settings_screen.dart`
- **Line:** 104
- **Code:** `themeProvider.setThemeMode(selection.first)`
- **Issue:** If onSelectionChanged is ever called with empty set, .first throws.

### 6.2 welcome_setup_screen
- **File:** `apps/mobile_flutter/lib/screens/welcome_setup_screen.dart`
- **Lines:** 373–374
- **Code:** `_mode = selection.first`
- **Issue:** Same as 6.1.

---

## 7. Date string split and parts[] (index out of range / parse)

### 7.1 user_red_day_adapter
- **File:** `apps/mobile_flutter/lib/models/user_red_day_adapter.dart`
- **Lines:** 19–23
- **Code:** `dateStr.split('-'); DateTime(int.parse(dateParts[0]), ...)`
- **Issue:** No check that dateParts.length >= 3. Malformed dateStr (e.g. "2024" or "2024-01") causes index error or wrong parse.

### 7.2 balance_adjustment fromMap
- **File:** `apps/mobile_flutter/lib/models/balance_adjustment.dart`
- **Lines:** 27–32
- **Code:** `dateStr.split('-'); int.parse(dateParts[0]), ...`
- **Issue:** Same as 7.1.

### 7.3 absence fromMap
- **File:** `apps/mobile_flutter/lib/models/absence.dart`
- **Lines:** 56–61
- **Issue:** Same pattern; no length check on dateParts.

### 7.4 balance_adjustment_adapter / absence_entry_adapter
- **Files:** `apps/mobile_flutter/lib/models/balance_adjustment_adapter.dart`, `absence_entry_adapter.dart`
- **Issue:** Same dateStr.split('-') and dateParts[0..2] without length check.

### 7.5 edit_entry_screen _parseTimeOfDay
- **File:** `apps/mobile_flutter/lib/screens/edit_entry_screen.dart`
- **Lines:** 413–416
- **Code:** `text.split(':'); if (parts.length != 2) return null; int.tryParse(parts[0])...`
- **Note:** Length check present; safe.

---

## 8. Substring / string bounds

### 8.1 export_service
- **File:** `apps/mobile_flutter/lib/services/export_service.dart`
- **Lines:** 722–723
- **Code:** `if (cleaned.length > 31) return cleaned.substring(0, 31);`
- **Note:** Bounds check present; safe.

### 8.2 xlsx_exporter
- **File:** `apps/mobile_flutter/lib/services/xlsx_exporter.dart`
- **Line:** 34
- **Similar:** substring(0, 31) with length check; safe.

### 8.3 profile_screen _friendlyError
- **File:** `apps/mobile_flutter/lib/screens/profile_screen.dart`
- **Lines:** 28–30
- **Code:** `if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);`
- **Note:** substring is safe; length is fixed.

---

## 9. UI / data binding

### 9.1 app_message_banner – message map cast
- **File:** `apps/mobile_flutter/lib/widgets/app_message_banner.dart`
- **Lines:** 131, 139–141
- **Code:** `msg['id'] as String`, `msg['title'] as String`, `msg['body'] as String`
- **Issue:** If API returns message with null id/title/body, cast throws.

### 9.2 unified_home_screen – full! after async
- **File:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Lines:** 1447–1451
- **Issue:** ensureAndOpen() uses full! in sheet builder; guarded by `if (!mounted || full == null) return` so currently safe. Fragile if guard is removed.

### 9.3 quick_entry_form – route split character
- **File:** `apps/mobile_flutter/lib/widgets/quick_entry_form.dart`
- **Line:** 129
- **Code:** `route.split(' â†' ')`  (Unicode arrow)
- **Issue:** If display or data uses different arrow (e.g. ' → ' U+2192 or ASCII '->'), split gives wrong parts and _useRecentRoute may not fill fields. Localization/encoding could vary.

---

## 10. Listener / lifecycle

### 10.1 TimeProvider / unified_home_screen / paywall_screen / main
- **Note:** removeListener is called in dispose for EntryProvider, HolidayService, ContractProvider, BillingService, AuthService. No leak identified.

### 10.2 export_dialog – late TextEditingController
- **File:** `apps/mobile_flutter/lib/widgets/export_dialog.dart`
- **Lines:** 34, 45
- **Code:** `late TextEditingController _fileNameController;` set in initState.
- **Note:** _updateDefaultFileName (e.g. from didChangeDependencies) uses _fileNameController; it is only called after initState, so safe. Build does not read it before init.

---

## 11. RegExp / time parsing

### 11.1 unified_home_screen _parseTimeOfDay
- **File:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Lines:** 4085–4116
- **Note:** firstMatch checked for null; group(1)/group(2) use ?? ''; int.tryParse and range checks present. Safe.

### 11.2 welcome_setup_screen baseline parsing
- **File:** `apps/mobile_flutter/lib/screens/welcome_setup_screen.dart`
- **Lines:** 105–134
- **Note:** firstMatch null checks; safe.

---

## 12. Other

### 12.1 Future.wait – account_status_gate
- **File:** `apps/mobile_flutter/lib/screens/account_status_gate.dart`
- **Lines:** 117–125
- **Code:** `results[1]`, `results[2]` after Future.wait([...]) with 5 futures.
- **Note:** results.length is 5; indices 1 and 2 are safe.

### 12.2 overview_tab / entry_compact_tile – travelLegs / shifts
- **Files:** overview_tab.dart (1287–1290), entry_compact_tile.dart (224–229, 237–241)
- **Note:** Both check isNotEmpty before .first/.last. Safe.

### 12.3 time_provider _monthlySummaries.last
- **File:** `apps/mobile_flutter/lib/providers/time_provider.dart`
- **Line:** 399
- **Note:** Used inside loop that has just done _monthlySummaries.add(...), so list is non-empty. Safe.

### 12.4 multi_segment_form _segments.last
- **File:** `apps/mobile_flutter/lib/widgets/multi_segment_form.dart`
- **Lines:** 105, 168
- **Note:** Guarded by _segments.isNotEmpty. Safe.

### 12.5 Entry.toJson / supabase_entry_service travel legs
- **Files:** entry.dart (331–341), supabase_entry_service.dart (328–354)
- **Note:** travelLegs used only when travelLegs != null && travelLegs!.isNotEmpty. Safe.

### 12.6 locations_screen – late Hive box (LOW)
- **File:** `apps/mobile_flutter/lib/locations_screen.dart`
- **Lines:** 19, 23
- **Code:** `late Box<Location> _locationsBox;` and `_locationsBox = Hive.box<Location>(AppConstants.locationsBox);` in initState.
- **Issue:** If this screen is ever shown before the locations box is opened (e.g. alternate entry point or test), `Hive.box` can throw. App normally opens the box at startup, so risk is low.

---

## 13. Timer / debounce – context or setState after dispose

### 13.1 unified_home_screen – Timer callback without mounted check (MEDIUM)
- **File:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Lines:** 152–161
- **Code:** `_recentLoadDebounce = Timer(const Duration(milliseconds: 150), () { ... _loadRecentEntriesInternal(); });`
- **Issue:** Callback does not check `mounted` before calling `_loadRecentEntriesInternal()`. That method immediately uses `AppLocalizations.of(context)` and `context.read<...>()`. If the user navigates away before 150 ms, the widget may be disposed and context invalid, leading to "use after dispose" or incorrect state. Timer is cancelled in dispose (line 67) but the callback can already be scheduled.
- **Fix:** Start the callback with `if (!mounted) return;` before any work.

### 13.2 location_selector – Timer callback calls setState without mounted (MEDIUM)
- **File:** `apps/mobile_flutter/lib/widgets/location_selector.dart`
- **Lines:** 102–105, 126–138
- **Code:** `_debounceTimer = Timer(const Duration(milliseconds: 500), () { _loadMapboxSuggestions(query); });` and inside `_loadMapboxSuggestions`, immediate `setState(() { ... });` at start (empty query path and loading path).
- **Issue:** When the timer fires after 500 ms, `_loadMapboxSuggestions` runs and performs `setState` before any `await`. If the widget was disposed (e.g. user left the screen), this can cause "setState() called after dispose()". Later in the method there are `if (mounted)` guards after the async call, but the initial synchronous setState calls are not guarded.
- **Fix:** At the start of the Timer callback, check `if (!mounted) return;`. At the start of `_loadMapboxSuggestions`, guard the initial setState with `if (!mounted) return;`.

### 13.3 time_provider – debounce (LOW)
- **File:** `apps/mobile_flutter/lib/providers/time_provider.dart`
- **Lines:** 127–130
- **Note:** Timer callback calls `calculateBalances()` which uses provider state and notifyListeners. Provider dispose cancels the timer. If timer fires after dispose, the callback could run; worth checking that calculateBalances does not touch disposed resources. Risk is lower than StatefulWidget context/setState.

---

## 14. Assert in production

### 14.1 entry.dart – assert for atomic entry invariants (LOW)
- **File:** `apps/mobile_flutter/lib/models/entry.dart`
- **Lines:** 621–622, 672–673
- **Code:** `assert(entry.shifts!.length == 1, ...);` and `assert(entry.travelLegs!.length == 1, ...);`
- **Issue:** In debug mode, violation throws AssertionError. In release/profile, asserts are stripped, so invalid data would not throw and could propagate. Relying on assert for correctness is fragile; consider runtime check or documentation that callers must ensure single shift/leg.

### 14.2 standard_app_bar – assert for title (LOW)
- **File:** `apps/mobile_flutter/lib/widgets/standard_app_bar.dart`
- **Lines:** 22–25
- **Code:** `assert(title != null || titleWidget != null, 'Provide either title or titleWidget');`
- **Issue:** Debug-only; in release, both could be null and _buildTitle() would use `title!` and throw. Low risk if call sites always provide one.

---

## 15. Navigator / ScaffoldMessenger without mounted

### 15.1 reports_screen – Navigator.pop after async (LOW–MEDIUM)
- **File:** `apps/mobile_flutter/lib/screens/reports_screen.dart`
- **Lines:** 354–370
- **Code:** After `showDialog` / export flow, `Navigator.of(context, rootNavigator: true).pop()` is used; some paths check `mounted` before pop, others may not in all branches.
- **Note:** Line 368 checks `mounted && Navigator...canPop()` before pop. Ensure every async branch that pops or shows SnackBar checks `mounted` or `context.mounted`.

### 15.2 overview_tab – showDialog / navigator (LOW)
- **File:** `apps/mobile_flutter/lib/screens/reports/overview_tab.dart`
- **Lines:** 963–965, 970, 985
- **Code:** `if (!context.mounted) return;` used before async continuation; `navigator = Navigator.of(context, rootNavigator: true)` and `showDialog`. Verify all code paths after await use context.mounted where required.

### 15.3 overview_tab _exportSummary – catch block without context.mounted (MEDIUM)
- **File:** `apps/mobile_flutter/lib/screens/reports/overview_tab.dart`
- **Lines:** 1043–1053
- **Code:** In the `catch (e)` block, `navigator.pop()` and `scaffold.showSnackBar(...)` are called without checking `context.mounted`. If the user navigates away during export, the context may be invalid when the catch runs.
- **Fix:** Add `if (!context.mounted) return;` at the start of the catch block before using navigator or scaffold.

---

## 16. Async started in initState / context after await

### 16.1 overview_tab – _loadSummary() uses context (LOW)
- **File:** `apps/mobile_flutter/lib/screens/reports/overview_tab.dart`
- **Lines:** 51, 88–95
- **Code:** `_summaryFuture = _loadSummary();` in initState. `_loadSummary()` immediately uses `context.read<SupabaseAuthService>()` and other context reads. If the widget were disposed before the first await (unlikely), context would be invalid. When the future completes, FutureBuilder runs in the widget’s context. Risk is low but worth noting for consistency.

### 16.2 legal_document_dialog – _loadDocument() in initState (noted in 5.3)
- **File:** `apps/mobile_flutter/lib/widgets/legal_document_dialog.dart`
- **Lines:** 47–50, 76–80
- **Code:** initState calls `_loadDocument()` which does setState at start. After await, some paths check `if (!mounted) return;`; ensure every setState and context use after await is guarded.

### 16.3 account_status_gate – _loadProfile() in initState (LOW)
- **File:** `apps/mobile_flutter/lib/screens/account_status_gate.dart`
- **Lines:** 57–61, 78–85
- **Code:** initState calls `_loadProfile()`. That method does setState (if !silent) and then awaits. Later it checks `mounted` before setState in catch/success. Ensure no context or setState is used after await without a mounted check.

---

## 17. Dynamic / untyped map access

### 17.1 customer_analytics_viewmodel – locationsList sort (LOW)
- **File:** `apps/mobile_flutter/lib/viewmodels/customer_analytics_viewmodel.dart`
- **Lines:** 679, 694–695
- **Code:** `locationsList.sort((a, b) => b['totalHours'].compareTo(a['totalHours']));` and `locationsList[i]['color'] = colors[i % colors.length];`. Maps are `List<Map<String, dynamic>>`. If `totalHours` is null or not a num, compareTo can throw. If a map is missing `totalHours`, same risk.
- **Fix:** Use typed model or null-safe access, e.g. `(a['totalHours'] as num?)?.compareTo(b['totalHours'] as num?) ?? 0`, or ensure the list is always populated with the right shape.

### 17.2 time_balance_tab – dynamic adjustment (LOW)
- **File:** `apps/mobile_flutter/lib/screens/reports/time_balance_tab.dart`
- **Lines:** 335, 340, 369–378, 412
- **Code:** `_buildAdjustmentItem(BuildContext context, dynamic adjustment, ...)` and `_showEditAdjustmentDialog(..., dynamic adjustment)`. Code accesses `adjustment.deltaMinutes`, `adjustment.effectiveDate`, `adjustment.note`. If a non-BalanceAdjustment object is passed, runtime errors. Using a typed parameter (e.g. BalanceAdjustment) would be safer.

---

## 18. FormState / GlobalKey.currentState

### 18.1 currentState! without null check (LOW)
- **Files:** login_screen.dart (94), manage_locations_screen.dart (191), unified_entry_form.dart (1856), simple_entry_form.dart (360), forgot_password_screen.dart (175)
- **Code:** `_formKey.currentState!.validate()` or `!_formKey.currentState!.validate()`. If validate is ever called before the first frame (e.g. from a test or odd callback), currentState can be null and the `!` throws.
- **Note:** login_screen already listed in 5.4; this generalizes to all FormState! usages. Prefer `_formKey.currentState?.validate() ?? false` or guard with a null check.

### 18.2 quick_entry_form / signup – currentState?.validate (OK)
- **Files:** quick_entry_form.dart (139), signup_screen.dart (118)
- **Code:** Uses `currentState?.validate()`. Safe.

---

## 19. indexOf / index edge cases

### 19.1 edit_entry_screen – indexOf can return -1 (LOW)
- **File:** `apps/mobile_flutter/lib/screens/edit_entry_screen.dart`
- **Lines:** 876, 1083
- **Code:** `edit_trip(_travelEntries.indexOf(travelEntry) + 1)` and `edit_shift(_shifts.indexOf(shift) + 1)`. If the entry is not in the list (e.g. list was rebuilt or reference is stale), indexOf returns -1, so the label becomes edit_trip(0) / edit_shift(0), which is wrong or confusing.
- **Fix:** Use the actual index from the list iteration (e.g. pass index from the parent that builds the list) or clamp to at least 1.

---

## 20. Extension on dynamic / unsafe map access

### 20.1 TravelTimeEntryToEntry extension on dynamic (MEDIUM if used)
- **File:** `apps/mobile_flutter/lib/models/entry.dart`
- **Lines:** 698–711
- **Code:** `extension TravelTimeEntryToEntry on dynamic { Entry toEntry(String userId) { ... DateTime.parse(this['date']), ... } }`. If the receiver is not a Map or is a Map with null/missing/invalid 'date', DateTime.parse or access can throw. Any caller that invokes .toEntry(userId) on a non-map or malformed map will crash.
- **Fix:** Restrict the extension to `Map<String, dynamic>` (or a typed type) and use null-safe/parse with fallback, or document and validate at call sites.

---

## 21. Hive / box access

### 21.1 locations_screen – box.getAt(index)! (LOW)
- **File:** `apps/mobile_flutter/lib/locations_screen.dart`
- **Lines:** 98–100
- **Code:** `itemCount: box.values.length`, `final location = box.getAt(index)!;`. If the box is modified (e.g. item deleted) during build or before getAt, index could be out of range or getAt could return null (e.g. if the box is lazy and the key was removed). The `!` would then throw.
- **Fix:** Use box.values.toList() and index into the list so the list is stable for the build, or handle null from getAt.

### 21.2 locations_screen – late box (already in 12.6)
- **Note:** See 12.6 for Hive box not opened before use.

---

## 22. Persisted JSON type / decode

### 22.1 sync_queue_service – decoded type not checked (LOW)
- **File:** `apps/mobile_flutter/lib/services/sync_queue_service.dart`
- **Lines:** 94–99
- **Code:** `final List<dynamic> decoded = jsonDecode(queueJson);` and `for (final item in decoded) { _queue.add(SyncOperation.fromJson(item as Map<String, dynamic>)); }`. If the stored JSON is not a list (e.g. corrupted or old format was an object), decoded is not a List; iterating with `for (final item in decoded)` over a Map would yield keys (strings), and the cast to Map would throw (caught by inner catch). Queue could end up empty or partially loaded. No crash but fragile.
- **Fix:** Check `if (decoded is! List)` and handle (e.g. clear queue, log, or migrate).

---

## 23. Equality / hashCode with nullable id

### 23.1 UserRedDay – id can be null (LOW)
- **File:** `apps/mobile_flutter/lib/models/user_red_day.dart`
- **Lines:** 169–175
- **Code:** `return other is UserRedDay && other.id == id;` and `int get hashCode => id.hashCode;`. If id is null, two UserRedDays with null id are considered equal and have the same hashCode (null.hashCode). If these are used in a Set or for distinctness, all "unsaved" items could collapse to one. Document or use a different identity for unsaved items.

---

## 24. Nullable id used with ! when editing

### 24.1 add_adjustment_dialog – existingAdjustment!.id! (MEDIUM)
- **File:** `apps/mobile_flutter/lib/widgets/add_adjustment_dialog.dart`
- **Lines:** 114, 167
- **Code:** When `_isEditing` is true: `widget.existingAdjustment!.id!` is passed to `updateAdjustment(id: ...)` and `deleteAdjustment(widget.existingAdjustment!.id!, ...)`. `BalanceAdjustment.id` is `String?`. If the dialog is ever opened in edit mode with an adjustment that has no id (e.g. in-memory or legacy data), `id!` throws.
- **Fix:** When _isEditing, check `widget.existingAdjustment?.id != null` before calling update/delete, or use `widget.existingAdjustment!.id ?? (throw StateError('Cannot update/delete adjustment without id'))`, or disable save/delete when id is null.

---

## Recommended priority

1. **High:** LeaveEntry.fromJson orElse (1.1); Supabase .single() handling (2.1–2.4).
2. **Medium:** Silent catch blocks (3.x) — add logging; int.parse → tryParse where appropriate (4.1–4.3); dateParts length checks (7.1–7.4); setState/mounted (5.x); **Timer/debounce mounted checks (13.1, 13.2)**; **overview_tab export catch block context.mounted (15.3)**; Navigator/ScaffoldMessenger mounted (15.x); async in initState / context after await (16.x); **add_adjustment_dialog id! when id is null (24.1)**.
3. **Low:** Return type cleanup (1.3); SegmentedButton .first (6.x); app_message_banner casts (9.1); route split character (9.3); assert-only invariants (14.x); **FormState currentState! (18.1)**; dynamic map/sort (17.x); **indexOf edge cases (19.1)**; **extension on dynamic (20.1)**; **Hive getAt (21.1)**; **sync queue JSON type (22.1)**; **UserRedDay null id (23.1)**.

---

---

## Coverage note

This report reflects multiple passes of static analysis (firstWhere/single/last, catch blocks, parse/cast, setState/mounted, Timer/debounce, assert, Navigator/context, async in initState, dynamic/map, FormState, indexOf, extension on dynamic, Hive, persisted JSON, equality/hashCode). It is not guaranteed to be exhaustive; new code or refactors may introduce issues. Re-run analysis or add runtime instrumentation to confirm and fix specific items. Prioritize High, then Medium, then Low.

*End of report.*
