# Fix Status (2026-02-11)

| Finding | Status | Fix |
|---------|--------|-----|
| App title not sourced from localization | DEFERRED | Cosmetic; "KvikTime" is brand name |
| Screens with no `AppLocalizations` usage (admin, analytics, location search, migration) | DEFERRED | Incremental localization in v1.1 |
| Partially localized screens (settings, edit entry, home, leaves) | DEFERRED | Incremental localization in v1.1 |
| Accessibility/semantics/tooltips not localized | DEFERRED | v1.1 |
| Error/status strings in providers hardcoded | DEFERRED | v1.1 |
| Fixed-pattern date formatting (`MMM dd, yyyy`, `h:mm a`) | DEFERRED | Cosmetic |
| Manual non-locale date formatting | DEFERRED | Cosmetic |
| **Time picker locale hardcoded to `en_US`** | **FIXED** | Removed `Locale('en', 'US')` override and `alwaysUse24HourFormat: false`; time picker now follows system locale; output formatted as 24h `HH:mm` |
| Time parsing assumes `AM`/`PM` tokens | DEFERRED | Partially mitigated by 24h format fix |
| Numbers/units not locale-formatted | DEFERRED | v1.1 |
| Casing transforms on localized strings | DEFERRED | Low risk for en/sv |
| **Case-insensitive key collision (`export_fileName` / `export_filename`)** | **FIXED** | Removed unused `export_fileName` from both ARB files |
| 8 extra keys in sv not in en template | DEFERRED | Non-breaking; keys unreachable from generated API |
| Physical left/right layout (RTL readiness) | DEFERRED | Only en/sv (LTR) supported |
| Directional icons hardcoded | DEFERRED | Only en/sv (LTR) supported |

---

**Multi-Phase Plan (original audit)**
- Phase 1: Inventory localization wiring/config
- Phase 2: Scan for non-externalized user-facing strings across `lib/`
- Phase 3: Audit date/time/number formatting and any locale hard-coding
- Phase 4: Audit bidi/RTL readiness (directional layout + directional icons)
- Phase 5: Validate ARB bundle parity (keys/placeholders/collisions)
- Phase 6: Compile findings with locations + impacts

**Scope Reviewed**
- `apps/mobile_flutter/lib/**` (excluding `lib/l10n/generated/**` and `*.g.dart`)
- `apps/mobile_flutter/lib/l10n/app_en.arb` and `apps/mobile_flutter/lib/l10n/app_sv.arb`
- Localization config + app entrypoints

**Localization Baseline**
- Gen-l10n is configured (`apps/mobile_flutter/l10n.yaml:4`) and Flutter codegen is enabled (`apps/mobile_flutter/pubspec.yaml:102`).
- App delegates + supported locales are wired into `MaterialApp.router` (`apps/mobile_flutter/lib/main.dart:320`, `apps/mobile_flutter/lib/main_prod.dart:236`).
- Supported locales appear to be English + Swedish only (LTR languages), via generated `AppLocalizations.supportedLocales` (`apps/mobile_flutter/lib/main.dart:321`).

---

## Findings: String Externalization Gaps (Hard-coded UI/UX Text)

**High-level signal (repo-wide, non-generated Dart)**
- `Text('...')` occurrences: 67
- InputDecoration `labelText/hintText/helperText/errorText` string literals: 45
- `tooltip/message/label` string literals: 37

**App title not sourced from localization**
- Hard-coded app title despite `appTitle` existing in ARB (`apps/mobile_flutter/lib/l10n/app_en.arb:5`).
  - `apps/mobile_flutter/lib/main.dart:302` (MaterialApp title)
  - `apps/mobile_flutter/lib/main_prod.dart:218`
- Impact: OS-level surfaces (task switcher/app title) can remain fixed-language even when the app locale changes.

**Screens with no `AppLocalizations` usage (entire UI text remains hard-coded)**
- Admin UI strings: `apps/mobile_flutter/lib/screens/admin_users_screen.dart:45`, `apps/mobile_flutter/lib/screens/admin_users_screen.dart:228`, `apps/mobile_flutter/lib/screens/admin_users_screen.dart:256`.
- Analytics UI strings: `apps/mobile_flutter/lib/screens/analytics_screen.dart:57`, `apps/mobile_flutter/lib/screens/analytics_screen.dart:72`, `apps/mobile_flutter/lib/screens/analytics_screen.dart:134`.
- Location search strings: `apps/mobile_flutter/lib/screens/location_search_screen.dart:14`, `apps/mobile_flutter/lib/screens/location_search_screen.dart:54`, `apps/mobile_flutter/lib/screens/location_search_screen.dart:111`.
- Migration strings: `apps/mobile_flutter/lib/screens/migration_screen.dart:220`, `apps/mobile_flutter/lib/screens/migration_screen.dart:228`, `apps/mobile_flutter/lib/screens/migration_screen.dart:291`.
- Locations management (non-`screens/` entry): `apps/mobile_flutter/lib/locations_screen.dart:65`, `apps/mobile_flutter/lib/locations_screen.dart:82`, `apps/mobile_flutter/lib/locations_screen.dart:90`.
- Impact: locale switching cannot affect these areas; Swedish users will see English-only flows.

**Partially localized screens with remaining hard-coded strings**
- Settings has a localized `t` but still includes hard-coded title/subtitle copy:
  - `apps/mobile_flutter/lib/screens/settings_screen.dart:447`
  - `apps/mobile_flutter/lib/screens/settings_screen.dart:448`
- Edit entry has localized `t` but still uses hard-coded SnackBars/UI labels:
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:181`
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:751`
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:770`
- Unified home screens have localized `t` but still include hard-coded labels/hints:
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:130`, `apps/mobile_flutter/lib/screens/unified_home_screen.dart:2104`, `apps/mobile_flutter/lib/screens/unified_home_screen.dart:2116`
  - `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:129`, `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:2060`, `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:2072`
- Leaves report uses localized strings for some content, but leave-type labels are hard-coded:
  - `apps/mobile_flutter/lib/screens/reports/leaves_tab.dart:158`, `apps/mobile_flutter/lib/screens/reports/leaves_tab.dart:176`, `apps/mobile_flutter/lib/screens/reports/leaves_tab.dart:430`
- Impact: mixed-language UI and incomplete translation coverage even where localization is generally in use.

**Accessibility/semantics/tooltips not localized**
- Dark mode semantics labels/hints are hard-coded:
  - `apps/mobile_flutter/lib/widgets/dark_mode_toggle.dart:25`, `apps/mobile_flutter/lib/widgets/dark_mode_toggle.dart:135`, `apps/mobile_flutter/lib/widgets/dark_mode_toggle.dart:136`, `apps/mobile_flutter/lib/widgets/dark_mode_toggle.dart:95`
- History filter semantics label is hard-coded English:
  - `apps/mobile_flutter/lib/screens/history_screen.dart:183`
- Tooltips in multiple widgets are hard-coded:
  - `apps/mobile_flutter/lib/widgets/date_range_picker_widget.dart:270`
  - `apps/mobile_flutter/lib/widgets/travel_segment_card.dart:73`, `apps/mobile_flutter/lib/widgets/travel_segment_card.dart:79`
- Impact: screen-reader output and tooltip text remains English, undermining accessibility parity across locales.

**User-facing error/status strings outside UI layer (providers/services/utils)**
- SnackBar label + user-friendly error text are hard-coded:
  - `apps/mobile_flutter/lib/utils/error_handler.dart:78`
  - `apps/mobile_flutter/lib/utils/error_handler.dart:91`, `apps/mobile_flutter/lib/utils/error_handler.dart:95`, `apps/mobile_flutter/lib/utils/error_handler.dart:99`
- Providers set `_error` strings in English that are likely surfaced in UI:
  - `apps/mobile_flutter/lib/providers/entry_provider.dart:195`
  - `apps/mobile_flutter/lib/providers/location_provider.dart:294`, `apps/mobile_flutter/lib/providers/location_provider.dart:312`
  - `apps/mobile_flutter/lib/providers/absence_provider.dart:103`
- Service exception messages are hard-coded:
  - `apps/mobile_flutter/lib/services/admin_api_service.dart:139`
  - `apps/mobile_flutter/lib/services/import_service.dart:49`
- Impact: even “localized” screens can still display English error states depending on where the error originates.

---

## Findings: Locale-Aware Formatting (Dates/Times/Numbers)

**Fixed-pattern date formatting used in user-visible UI**
- Month/day ordering and separators are hard-coded in patterns:
  - `apps/mobile_flutter/lib/widgets/export_dialog.dart:69` (e.g., `MMM dd, yyyy`)
  - `apps/mobile_flutter/lib/screens/history_screen.dart:862` (e.g., `MMM dd, yyyy`)
  - `apps/mobile_flutter/lib/screens/history_screen.dart:870` / `apps/mobile_flutter/lib/screens/history_screen.dart:871` (e.g., `h:mm a`)
  - `apps/mobile_flutter/lib/widgets/travel_entry_card.dart:543` / `apps/mobile_flutter/lib/widgets/travel_entry_card.dart:558` (“Logged/Updated” + `MMM dd, HH:mm`)
- Impact: date order/12–24 hour conventions can conflict with locale expectations (especially Swedish vs US-style formats), even if month/day names localize.

**Manual (non-locale) date formatting**
- ISO-like date strings are constructed manually:
  - `apps/mobile_flutter/lib/screens/reports/date_range_dialog.dart:382` (`YYYY-MM-DD`)
  - `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:131` (uses `date.toString().split(' ')[0]`)
- Manual numeric date display:
  - `apps/mobile_flutter/lib/widgets/simple_entry_form.dart:293` (`day/month/year` string interpolation)
- Impact: formatting stays fixed regardless of locale, and can produce inconsistent formatting across different screens.

**Time picker locale hard-coded to `en_US`**
- Time picker overrides locale and forces 12-hour formatting:
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:1222`
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:3335`
  - `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:3298`
  - `apps/mobile_flutter/lib/widgets/simple_entry_form.dart:354`
- Impact: time-picker language/format becomes decoupled from app locale; Swedish UI can still show AM/PM, and time parsing logic becomes locale-fragile.

**Time parsing/formatting assumes specific string shapes**
- Hard-coded `HH:mm` formatting:
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:397`
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:241`
- Parsing expects specific AM/PM tokens:
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:3427` (expects `'AM'/'PM'`)
  - `apps/mobile_flutter/lib/screens/unified_home_screen2.dart:3390` (same pattern)
- Impact: any locale/time setting that doesn’t match these assumptions can lead to incorrect parsing and downstream time calculations/display.

**Numbers and units are not locale-formatted**
- Extensive `toStringAsFixed()` + concatenated units (no `NumberFormat` usage found):
  - `apps/mobile_flutter/lib/widgets/time_balance_dashboard.dart:163` (`...toStringAsFixed(1)}h`)
  - `apps/mobile_flutter/lib/screens/reports/overview_tab.dart:63` (hours + `h`)
  - `apps/mobile_flutter/lib/screens/reports/leaves_tab.dart:265` (`days`)
  - `apps/mobile_flutter/lib/providers/contract_provider.dart:474` (`hours/day`)
- Impact: decimal separator and digit shapes don’t follow locale conventions (e.g., Swedish typically uses comma for decimals), and unit placement can’t be reordered per language.

**Casing transforms on localized strings**
- Uppercasing localized strings directly:
  - `apps/mobile_flutter/lib/screens/reports/trends_tab.dart:172`
  - `apps/mobile_flutter/lib/screens/reports/trends_tab.dart:201`
- Impact: locale-specific casing rules can be violated when additional locales are introduced (and can produce unexpected results even within Latin-script locales).

---

## Findings: Bidirectional Text & RTL Readiness

**Current locale set is LTR-only**
- Supported locales in-app are English and Swedish (LTR). This reduces immediate RTL risk, but the codebase shows limited RTL readiness.

**Physical left/right layout primitives**
- Explicit left/right padding/margins (non-directional):
  - `apps/mobile_flutter/lib/widgets/entry_detail_sheet.dart:26`
  - `apps/mobile_flutter/lib/screens/edit_entry_screen.dart:444`
  - `apps/mobile_flutter/lib/screens/history_screen.dart:1021`
  - One-sided padding likely to be direction-sensitive:
    - `apps/mobile_flutter/lib/widgets/unified_entry_form.dart:418` (right-only)
    - `apps/mobile_flutter/lib/screens/reports/trends_tab.dart:432` (left-only)
- Impact: if RTL locales are added later, these layouts won’t naturally mirror, producing “backwards” spacing/indentation.

**Directional icon usage**
- Chevron/arrow icons are hard-coded in multiple navigation affordances:
  - `apps/mobile_flutter/lib/screens/settings_screen.dart:416`
  - `apps/mobile_flutter/lib/services/navigation_service.dart:257`
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:731`
- Impact: in RTL contexts, directional affordances can point the wrong way depending on icon mirroring behavior.

**Bidi-sensitive inline symbols and ordering**
- Arrow glyph `→` embedded in UI strings:
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:130`
  - `apps/mobile_flutter/lib/widgets/travel_entry_card.dart:195`
- Impact: mixed-direction strings (numbers + arrows + translated text) can render with unintuitive ordering without careful locale-aware composition.

---

## Findings: Resource Bundle Completeness (ARB)

**Key parity (template vs Swedish)**
- `app_en.arb` contains 672 message keys; `app_sv.arb` contains 680.
- Swedish includes all English keys but also has 8 extra keys not present in the template:
  - Example locations: `apps/mobile_flutter/lib/l10n/app_sv.arb:548`, `apps/mobile_flutter/lib/l10n/app_sv.arb:600`
- Impact: keys not in the template are not generated into `AppLocalizations`, so they are effectively unreachable from code via the generated API (and indicate bundle drift).

**Case-insensitive key collisions**
- Both locales contain `export_fileName` and `export_filename` (distinct keys, but collide in case-insensitive tooling):
  - `apps/mobile_flutter/lib/l10n/app_en.arb:333`, `apps/mobile_flutter/lib/l10n/app_en.arb:609`
  - `apps/mobile_flutter/lib/l10n/app_sv.arb:207`, `apps/mobile_flutter/lib/l10n/app_sv.arb:397`
- Impact: external tooling or scripts that treat keys case-insensitively can fail or drop one of the messages, complicating automation/QA.

**Placeholders**
- Placeholder name sets match between en and sv (no placeholder mismatches detected).
- Impact: reduces risk of runtime formatting exceptions for translated strings that use placeholders/plurals.

---

## Overall Impact Summary
- Users switching to Swedish can still encounter substantial English-only UI (not just copy, but also error states and tooltips), reducing perceived localization completeness.
- Date/time/number formatting is inconsistent across screens and frequently fixed-pattern/manual, which can conflict with locale conventions (ordering, separators, 12/24h).
- Time picker locale overrides and hard-coded parsing assumptions introduce locale-fragility in several entry flows (`apps/mobile_flutter/lib/screens/edit_entry_screen.dart:1222`, `apps/mobile_flutter/lib/screens/unified_home_screen.dart:3335`).
- RTL/bidi support is not exercised by current supported locales but would face layout and icon-mirroring risks if RTL locales are introduced.