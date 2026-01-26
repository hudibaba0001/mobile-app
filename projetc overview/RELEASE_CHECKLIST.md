<!-- docs/RELEASE_CHECKLIST.md -->

# Release Checklist — “Ready for Play Store”

This is a pragmatic checklist to reach a safe first Play Store release.

---

## 0) Absolute blockers (must be green)
### ✅ Build + analyze
- `flutter pub get`
- `flutter analyze` **must have 0 errors**
- `flutter test` **must pass**

> Right now you have analyzer errors like:
> `Undefined name '_startTime' / '_endTime'` in `unified_entry_form.dart`.
> Fix these first — Play Store is impossible with compile/analyze errors.

### ✅ Release build
- Android:
  - `flutter build appbundle --release`
- Ensure it completes without errors.

---

## 1) Core flows manual test (must be verified on device)
Do this on at least **2 physical Android devices** (different OS versions) + 1 emulator.

### Account & access
- [ ] login works
- [ ] AccountStatusGate correctly blocks unsubscribed user
- [ ] logout works

### Work logging
- [ ] create single shift
- [ ] create shift with unpaid break (break affects worked minutes)
- [ ] create two shifts same date (stored as two entries, shows as two rows)
- [ ] shift 2 different location + notes works
- [ ] edit an entry updates correct row only

### Travel logging
- [ ] create one travel leg
- [ ] create two legs A→B, B→C (stored as two entries, shows two rows)
- [ ] travel caching works (second time does not re-call maps unnecessarily)
- [ ] offline travel entry saves locally

### History consistency
- [ ] history lines match saved entries exactly
- [ ] daily total shown matches sum of rows

### Export verification (must match history)
- [ ] export CSV
- [ ] export XLSX
- [ ] verify a sample day: exported rows equal history rows (same minutes, locations, notes)

### Offline + sync
- [ ] enable airplane mode
- [ ] create work + travel entries
- [ ] disable airplane mode
- [ ] verify sync pushes to Supabase and entries still appear correctly

---

## 2) Calculation correctness smoke pack (quick)
Pick 3 known scenarios and verify balances:

### Scenario A — Break
- shift 08:00–17:30, break 30
- expected worked = 540 min
- verify daily variance vs target

### Scenario B — Two shifts same day
- shift 08–12 + 13–17, target 480
- total worked = 480
- variance should be 0 (target applied once)

### Scenario C — Red day
- pick a red day
- expected target = 0
- if worked logged, variance positive

> If you support absence now:
- Scenario D — Full day VAB/Sick/Vacation => variance 0 (credited minutes)

---

## 3) Codebase hygiene (minimum for first release)
### Analyzer warnings triage
You don’t need 0 warnings for Play Store, but fix these categories:

#### Must fix (stability)
- `use_build_context_synchronously` (can cause crashes)
- web-only imports used incorrectly (`dart:html`) if they break Android builds
- any “dead code” impacting correctness

#### Should fix (quality)
- `avoid_print` => replace with logger or guard debug prints
- deprecated APIs used in hot paths (`withOpacity`, Share deprecated calls)

---

## 4) Security & privacy
- [ ] Supabase RLS verified for entries (per-user access)
- [ ] Maps API key restricted (Android package + SHA-1, and/or server-side where possible)
- [ ] No background GPS tracking
- [ ] Privacy policy drafted (even minimal)

---

## 5) Play Store packaging
- [ ] App name, icon, splash screen
- [ ] Versioning:
  - update `version:` in `pubspec.yaml`
- [ ] Signing:
  - upload keystore configured for release
- [ ] Required Store listing:
  - screenshots
  - short/long description
  - privacy policy link

---

## 6) “Go / No-go” gate
**NO-GO** if any:
- analyzer errors
- failing tests
- release build fails
- core flows not manually verified

**GO** when:
- 0 analyzer errors
- all tests pass
- release appbundle builds
- manual flows verified on devices
- exports match history
- offline sync verified

---

## Recommended command pack (copy/paste)
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
