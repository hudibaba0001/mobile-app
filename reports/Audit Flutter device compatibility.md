# Fix Status (2026-02-11)

| Finding | Status | Fix |
|---------|--------|-----|
| iOS build scaffolding missing/incomplete | DEFERRED | Launching Android first |
| Android INTERNET permission missing | FIXED (previous session) | Added to main AndroidManifest.xml |
| `dart:io` in web export path | DEFERRED | Not targeting web |
| SafeArea missing in account_status_gate loading/error | FIXED | Added SafeArea wrapping |
| Non-scrollable welcome screen | FIXED | Wrapped in SingleChildScrollView |
| Non-scrollable migration screen | DEFERRED | One-time screen, short content |
| Dialog overflow (date range) | DEFERRED | Edge case in landscape |
| Admin UI trailing Row overflow | FIXED | Replaced buttons with compact IconButtons |
| Fixed-height list in manage_locations | DEFERRED | Cosmetic |
| Dialog keyboard clipping (quick_entry_form) | DEFERRED | Edge case |
| System UI overlay iOS-centric | DEFERRED | Android launch only |
| App text scaling override | DEFERRED | Intentional design choice |
| iPad Share popover crash | DEFERRED | Android launch only |
| AppBar title overflow (both home screens) | FIXED | Added Expanded + TextOverflow.ellipsis |
| Gradle user-home Linux path | FIXED | Removed from gradle.properties |

---

**Plan (original audit)**
- Inventory Flutter app + platform folders (`apps/mobile_flutter/**`)
- Review SDK/deps + platform build configs (Gradle, manifests, iOS scaffolding)
- Scan all UI entry points (`lib/screens/**`) and reusable UI (`lib/widgets/**`, `lib/design/**`) for adaptive layout and overflow risks
- Audit notch/keyboard handling (SafeArea, `viewInsets`, modal sheets/dialogs) and orientation assumptions
- Compare Android/iOS implementation gaps and call out cross-platform compile blockers
- Prioritize findings by “ship-blocking” → “user-facing” → “nice-to-fix”, with concrete file/line evidence

**Scope Covered**
- Dart/UI: `apps/mobile_flutter/lib/**` (config, providers, services, screens, widgets)
- Android: `apps/mobile_flutter/android/**`
- iOS: `apps/mobile_flutter/ios/**`
- Web: `apps/mobile_flutter/web/**`
- No code changes made.

**Critical (Ship-Blockers)**
- iOS build scaffolding appears missing/incomplete: `apps/mobile_flutter/ios/Runner` only contains generated registrant (`apps/mobile_flutter/ios/Runner/GeneratedPluginRegistrant.m:1`), and `Runner.xcodeproj`/`Info.plist`/`AppDelegate` equivalents are not present; plus generated config points at the repo root (`apps/mobile_flutter/ios/Flutter/Generated.xcconfig:3`) which will not work on macOS.
- Android release likely has no network access: INTERNET permission exists only in debug manifest (`apps/mobile_flutter/android/app/src/debug/AndroidManifest.xml:6`) and is absent in the main manifest (`apps/mobile_flutter/android/app/src/main/AndroidManifest.xml:1`), which will break Supabase/HTTP in production.
- Web build is blocked by `dart:io` in the reports export path: `apps/mobile_flutter/lib/services/export_service.dart:1` is imported by `apps/mobile_flutter/lib/screens/reports_screen.dart:11` and pulled into the app via routing (`apps/mobile_flutter/lib/config/app_router.dart:10`), which should fail Flutter web compilation.

**High-Impact (Likely User-Facing Compatibility Issues)**
- Safe-area inconsistencies in modal bottom sheets containing `UnifiedEntryForm` (risk: content under iPhone home indicator / gesture bar, inconsistent padding):
  - No SafeArea: `apps/mobile_flutter/lib/screens/history_screen.dart:695`, `apps/mobile_flutter/lib/screens/unified_home_screen.dart:1013`, `apps/mobile_flutter/lib/widgets/unified_entry_form.dart:1529`
  - SafeArea used in other flows: `apps/mobile_flutter/lib/screens/unified_home_screen.dart:1141`
- Full-screen gate states missing SafeArea/scroll (risk: notch overlap, overflow in landscape/small screens):
  - Loading/error states lack SafeArea: `apps/mobile_flutter/lib/screens/account_status_gate.dart:150`, `apps/mobile_flutter/lib/screens/account_status_gate.dart:168`
  - Other states do use SafeArea: `apps/mobile_flutter/lib/screens/account_status_gate.dart:206`
- Non-scrollable “centered column” layouts that can overflow in landscape/small devices:
  - Welcome: `apps/mobile_flutter/lib/screens/welcome_screen.dart:23`
  - Migration: `apps/mobile_flutter/lib/screens/migration_screen.dart:85`
- Dialog content not constrained for small heights (risk: dialog overflow in landscape/split-screen):
  - Date range dialog uses a fixed-width dialog with no scroll wrapper: `apps/mobile_flutter/lib/screens/reports/date_range_dialog.dart:152`
- Admin UI not adaptive to phone widths (risk: horizontal overflow / clipped controls):
  - Search+filter in a single Row: `apps/mobile_flutter/lib/screens/admin_users_screen.dart:55`
  - Multi-button `ListTile.trailing` Row: `apps/mobile_flutter/lib/screens/admin_users_screen.dart:160`
- Fixed-height list region (risk: wasted space or clipped content in landscape/tablet split):
  - `apps/mobile_flutter/lib/screens/manage_locations_screen.dart:368`
- Dialog sized as screen fractions without safe-area/keyboard awareness (risk: clipped dialog when keyboard opens):
  - `apps/mobile_flutter/lib/widgets/quick_entry_form.dart:233`
- System UI overlay style is Android-centric (risk: iOS status bar contrast issues):
  - Missing iOS `statusBarBrightness` while setting `statusBarIconBrightness`: `apps/mobile_flutter/lib/providers/theme_provider.dart:65`
- App overrides system text scaling (risk: accessibility + device consistency issues; can also mask layout overflows during testing):
  - Clamp: `apps/mobile_flutter/lib/providers/theme_provider.dart:33`
  - Enforced app scaler via MediaQuery: `apps/mobile_flutter/lib/main.dart:308`
- iPad sharing risk: `Share.shareXFiles` without an origin rect (can crash/mis-anchor popover on iPad):
  - `apps/mobile_flutter/lib/screens/reports_screen.dart:271`
- AppBar title row likely to overflow with long names (no `Expanded`/ellipsis around the name block):
  - `apps/mobile_flutter/lib/screens/unified_home_screen.dart:265`

**Medium/Low (Still Notable)**
- Web URL strategy called unconditionally (typically gated to web to avoid non-web surprises across Flutter versions): `apps/mobile_flutter/lib/main.dart:50`
- Web notch/orientation specifics:
  - No `viewport-fit=cover` for iOS PWA notch layouts: `apps/mobile_flutter/web/index.html:22`
  - PWA orientation forced to portrait: `apps/mobile_flutter/web/manifest.json:9`
  - Placeholder theme colors: `apps/mobile_flutter/web/manifest.json:6`
- Android Gradle config forces a Linux-like Gradle home path (may be awkward on Windows/macOS dev machines/CI): `apps/mobile_flutter/android/gradle.properties:4`

**Validation Checklist (Recommended)**
- Devices: small phone + notch phone + iPad; test portrait+landscape; test with keyboard open; test split-screen (Android) if supported.
- Flows to exercise: edit/create entry bottom sheets (`UnifiedEntryForm`), reports export/share (especially iPad), account gate loading/error, admin users screen on phone width, date range dialog in landscape.
- Build matrix: `flutter build apk --release` (confirm networking), `flutter build web` (should currently fail due to `dart:io` import), iOS build on macOS after restoring proper iOS project files.