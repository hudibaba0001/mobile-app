# KvikTime Pre-Launch Audit Report

**Date:** 2026-02-11 (updated)
**Target:** Google Play Store (Android)
**Flutter analyze:** 0 issues
**Branch:** master

---

## Security Fixes (Done)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| S1 | Supabase RLS allowed users to escalate `is_admin`, modify subscription fields | Added `prevent_profile_escalation` BEFORE UPDATE trigger blocking changes to `is_admin`, `subscription_status`, `stripe_customer_id`, `stripe_subscription_id`, `current_period_end`, `email` | `supabase_migrations/002_profiles_subscription.sql`, live DB migration |
| S2 | Billing portal used email-based lookup, no JWT auth | Added JWT verification; lookup now uses authenticated `user.id` | `apps/web/app/api/billing/portal/route.ts` |
| S3 | Account page accessible without re-authentication | Now requires Supabase sign-in before accessing billing | `apps/web/app/account/page.tsx` |
| S4 | CSV formula injection in exports | Added `_sanitizeCsvValue()` prefixing cells starting with `=`, `+`, `-`, `@`, `\t`, `\r` | `apps/mobile_flutter/lib/services/csv_exporter.dart`, `apps/mobile_flutter/lib/services/travel_service.dart` |
| S5 | Admin token stored in localStorage (XSS-prone) | Moved to httpOnly cookie; created `/api/auth/me` and `/api/auth/logout` endpoints; all admin pages now use cookie-based auth | `apps/web_api/app/api/auth/login/route.ts`, `apps/web_api/app/api/auth/me/route.ts`, `apps/web_api/app/api/auth/logout/route.ts`, `apps/web_api/lib/middleware.ts`, `apps/web_api/components/AdminLayout.tsx`, all `apps/web_api/app/admin/*/page.tsx` |
| S6 | SMTP password synced to Supabase in plaintext | Removed `sender_password` from Supabase table and sync; password stays local-only in Hive | `supabase_email_settings.sql`, `apps/mobile_flutter/lib/repositories/supabase_email_settings_repository.dart`, live DB migration |
| S7 | Supabase functions had mutable `search_path` | Recreated all functions with `SET search_path = public` | Live DB migration |
| S8 | `print()` statements visible in release builds | Replaced with `debugPrint()` across 8 files | `profile_service.dart`, `migration_service.dart`, `export_service.dart`, `travel_cache_service.dart`, `local_entry_provider.dart`, `unified_home_screen.dart`, `unified_home_screen2.dart`, `supabase_auth_service.dart` |

## Schema & Data Integrity Fixes (Done)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| D1 | SQL file missing `is_admin`, contract, and feature flag columns | Updated CREATE TABLE and ALTER TABLE blocks to match live DB (24 columns) | `supabase_migrations/002_profiles_subscription.sql` |
| D2 | Admin user creation used nonexistent `full_name` column | Changed to `first_name`/`last_name` in both auth metadata and profile insert | `apps/web_api/app/api/admin/users/route.ts` |
| D3 | `SupabaseEntryService` had zero awareness of `travelLegs` model; travel segments silently lost on create/update | Added multi-leg support to both `addEntry()` and `updateEntry()` — each `TravelLeg` now maps to a `travel_segments` row | `apps/mobile_flutter/lib/services/supabase_entry_service.dart` |
| D4 | `TravelService` used legacy `entry.from`/`entry.to` fields instead of `travelLegs` | Updated to use helper methods `_getOrigin()`/`_getDestination()` that prefer `travelLegs` | `apps/mobile_flutter/lib/services/travel_service.dart` |

## Platform & Build Fixes (Done)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| P1 | INTERNET permission only in debug manifest; release APK would have no network | Added `<uses-permission android:name="android.permission.INTERNET"/>` to main manifest | `AndroidManifest.xml` |
| P2 | Android release signing not configured | Added `key.properties`-based signing config | `build.gradle.kts` |
| P3 | Google Services plugin still in Gradle (Firebase remnant) | Removed from `settings.gradle.kts` | `settings.gradle.kts` |
| P4 | Web app title was "myapp" | Changed to "KvikTime" with correct description and apple-mobile-web-app-title | `web/index.html` |
| P5 | `gradle.user.home` hardcoded to `/home/user/.gradle` (breaks CI/Windows) | Removed from gradle.properties | `gradle.properties` |
| P6 | Password reset deep link `kviktime://` not wired in Android manifest | Added intent-filter for `kviktime://` custom scheme | `AndroidManifest.xml` |

## Networking & Sync Fixes (Done — previously deferred, now fixed)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| N1 | **AnalyticsApi auth token was wrong** (`user?.aud` instead of access token) — guaranteed 401/403 | Now uses `session?.accessToken` with null guard; added 15s timeout | `analytics_api.dart` |
| N2 | **Batch `addEntries` never queued offline creates** — data silently lost | Now queues each failed entry via `_syncQueue.queueCreate()` with timestamp | `entry_provider.dart` |
| N3 | **Travel sync payload dropped `from_location`/`to_location`** when `travelLegs` present — blank travel entries in cloud | `Entry.toJson()` now always includes `from_location`/`to_location` from first/last leg | `entry.dart` |
| N4 | **SyncQueue init race** — enqueue before init could overwrite persisted ops | Replaced fire-and-forget init with `_syncQueueReady` Future; all queue ops await `_ensureSyncQueueReady()` | `entry_provider.dart` |
| N5 | **Push-before-pull** — `setSupabaseDeps()` immediately synced local defaults to cloud, overwriting server settings | Removed auto-push from `setSupabaseDeps()` in Settings, Email, and Location providers; `loadFromCloud()` must be called first | `settings_provider.dart`, `email_settings_provider.dart`, `location_provider.dart` |
| N6 | **`main_prod.dart` missing critical wiring** — no NetworkStatusProvider, no Supabase deps for settings/locations/email, no Hive boxes for absences/adjustments/red days, no auto-sync | Brought to full parity with `main.dart` | `main_prod.dart` |
| N7 | **`queueDelete` left pending updates behind** when removing a pending create | Now removes both pending creates AND updates for the entry | `sync_queue_service.dart` |
| N8 | **No HTTP timeouts** — all Mapbox, Admin, Analytics API calls could hang forever | Added 15s timeout to all HTTP calls | `map_service.dart`, `admin_api_service.dart`, `analytics_api.dart` |
| N9 | **AdminApiService swallowed error codes** — all exceptions re-wrapped as code 500 | Added `on ApiException { rethrow; }` to preserve original status codes | `admin_api_service.dart` |

## Device Compatibility Fixes (Done — previously deferred, now fixed)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| DC1 | Account status gate loading/error states missing SafeArea | Added SafeArea wrapping to both states | `account_status_gate.dart` |
| DC2 | Welcome screen Column not scrollable (overflow in landscape) | Wrapped in SingleChildScrollView | `welcome_screen.dart` |
| DC3 | Admin users screen trailing Row overflow on phone widths | Replaced OutlinedButton/TextButton with compact IconButtons | `admin_users_screen.dart` |
| DC4 | AppBar title Row overflow with long usernames (both home screens) | Added Expanded + TextOverflow.ellipsis to name/subtitle Column | `unified_home_screen.dart`, `unified_home_screen2.dart` |

## Localization Fixes (Done — previously deferred, now fixed)

| # | Issue | Fix | Files Changed |
|---|-------|-----|---------------|
| L1 | Hardcoded English strings in `login_screen.dart` (10 strings) | Added to `app_en.arb` and `app_sv.arb` |
| L2 | Hardcoded English strings in `time_balance_tab.dart` (5 strings) | Added to `app_en.arb` and `app_sv.arb` |
| L3 | Case-insensitive key collision: `export_fileName` vs `export_filename` | Removed unused `export_fileName` from both ARB files | `app_en.arb`, `app_sv.arb` |
| L4 | Time picker forced `en_US` locale + 12-hour format | Removed locale override; time picker now follows system locale; output formatted as 24h `HH:mm` | `edit_entry_screen.dart`, `unified_home_screen.dart`, `unified_home_screen2.dart`, `simple_entry_form.dart` |

## Cleanup (Done)

| # | Item | Action |
|---|------|--------|
| C1 | Legacy Firebase Cloud Functions (`functions/`, `firebase.json`, `.firebaserc`) | Deleted |
| C2 | Firebase JS SDK in `web/index.html` | Removed |
| C3 | `google-services.json` (Android) | Deleted |
| C4 | `GoogleService-Info.plist` (iOS) | Deleted |
| C5 | `public/admin-dashboard.html`, `public/index.html` (Firebase hosting) | Deleted |
| C6 | `register_account_simple.dart` (Firebase account script) | Deleted |

---

## Remaining — Manual Actions Required

| # | Item | Where | Action |
|---|------|-------|--------|
| M1 | **Rotate Stripe secret key** | Stripe Dashboard | Old key exists in git history (commits `b605a88`, `27d9d23`). Rotate on dashboard. |
| M2 | **Generate release keystore** | Terminal | Run `keytool -genkey -v -keystore kviktime-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kviktime` and create `android/key.properties` |
| M3 | **Enable Leaked Password Protection** | Supabase Dashboard > Auth | Toggle on in Auth settings |

## Remaining — Deferred to v1.1

### Performance (from resource consumption audit — 33 findings)

| Severity | Count | Key Items |
|----------|-------|-----------|
| Critical | 6 | TimeProvider listener cascade, FlexsaldoCard over-broad watch, full entry list sort in build, Timer not cancelled in dispose, auth stream subscription leak, missing ListView keys |
| High | 11 | Unbounded Supabase query, unbounded absence/adjustment map growth, Hive O(n*m) delete loop, JSON encode on main thread, heavy sequential init in main(), TrendsTab expensive filtering, SharedPreferences per-persist, fire-and-forget sync, Hive boxes never closed |
| Medium | 12 | DateTime.now() in build, uncached getters, sorting in itemBuilder, nested loops in calculator, MediaQuery.of(), missing RepaintBoundary, no lifecycle pause handling, debugPrint calls, no resume debounce, heavy deps, redundant provider watching |
| Low | 4 | String formatting in Consumer, unnecessary list copies, Hive values copy+filter, hardcoded anon key |

**Rationale for deferral:** None of these cause crashes, data loss, or Play Store rejection. They affect smoothness and battery under load. Fix after launch based on real-user telemetry.

### Still Deferred Items

| Item | Impact | Why Deferred |
|------|--------|-------------|
| iOS build scaffolding incomplete | Can't build iOS | Launching Android first |
| `dart:io` in web export path | Web build fails | Not targeting web |
| Local caches not user-scoped (P0-5) | Cross-account data on shared devices | Requires cache namespace refactor; single-user device for launch |
| Non-transactional multi-table Supabase writes | Partial data on network drop mid-write | Requires RPC/Edge Function |
| Entry local cache doesn't prune server-deleted items | Ghost entries on offline fallback | Needs tombstone strategy |
| Many hardcoded strings (67+ Text(), 45+ InputDecoration) | Swedish users see English in some screens | Incremental fix over v1.1-v1.2 |
| RTL/bidi layout readiness | N/A for en/sv | Only needed if Arabic/Hebrew locale added |
| Date/number formatting inconsistencies | Minor UX issue | Non-blocking; cosmetic |

---

## Commit History (this audit)

| Commit | Description |
|--------|-------------|
| `66b22c9` | Switch to Supabase, secure CSV, Android signing |
| `9103782` | Use httpOnly cookie for admin auth |
| `ea83c5b` | Remove Firebase files and sender_password |
| `8f275da` | Remove legacy Firebase hosting files and registration script |
| *uncommitted* | All networking, device compat, localization, and compliance fixes |
