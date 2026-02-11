# KvikTime Weekly Status — 2026-02-11

**Target:** Google Play Store (Android)
**Flutter analyze:** 0 issues
**Branch:** master

---

## FIXED (53)

**Security (8)**
S1 — RLS profile escalation blocked via DB trigger
S2 — Billing portal now uses JWT auth
S3 — Account page requires Supabase sign-in
S4 — CSV formula injection sanitized
S5 — Admin token moved to httpOnly cookie
S6 — SMTP password removed from Supabase sync
S7 — DB functions locked to `search_path = public`
S8 — `print()` → `debugPrint()` across 8 files

**Schema & Data Integrity (4)**
D1 — SQL migration aligned to live DB (24 columns)
D2 — Admin user creation uses `first_name`/`last_name`
D3 — SupabaseEntryService now supports `travelLegs`
D4 — TravelService uses `travelLegs` instead of legacy fields

**Platform & Build (6)**
P1 — INTERNET permission added to main manifest
P2 — Android release signing via `key.properties`
P3 — Firebase Google Services plugin removed
P4 — Web app title → "KvikTime"
P5 — `gradle.user.home` hardcoded path removed
P6 — `kviktime://` deep link intent-filter added

**Networking & Sync (9)**
N1 — AnalyticsApi auth: `session?.accessToken` + 15s timeout
N2 — Batch `addEntries` now queues offline creates
N3 — `Entry.toJson()` always includes `from/to_location`
N4 — SyncQueue init race fixed (`_syncQueueReady` Future)
N5 — Push-before-pull removed from 3 providers
N6 — `main_prod.dart` brought to full parity
N7 — `queueDelete` removes creates AND updates
N8 — 15s HTTP timeout on all API calls
N9 — AdminApiService preserves original error codes

**Device Compatibility (4)**
DC1 — SafeArea added to account status gate
DC2 — Welcome screen wrapped in scroll view
DC3 — Admin users trailing buttons → IconButtons
DC4 — AppBar title overflow: Expanded + ellipsis

**Localization (4)**
L1 — login_screen strings added to ARB files
L2 — time_balance_tab strings added to ARB files
L3 — Duplicate `export_fileName` key removed
L4 — Time picker locale override removed; 24h `HH:mm`

**Crash Prevention (13)**
C-01 — Export dialog: setState before pop, mounted guard in catch
C-02 — Home screen: timer cancelled in dispose
C-03 — Home recent entries: mounted guards on setState
C-04 — Edit Entry time picker: HH:mm output matches parser
C-05 — Absence delete: null check on id before delete
C-06 — Mounted guards on 4 picker→setState patterns
C-07 — AccountStatusGate: mounted guards on async setState
C-08 — Location selector: mounted guard on delayed focus check
C-09 — Location selector: mounted guards on Mapbox async
C-10 — Migration screen: mounted guard on delayed animation
C-11 — Admin users: mounted guard inside microtask
C-12 — NavigationService: context.mounted before go()
C-13 — AnalyticsViewModel: hasListeners guard in delayed mock

**Cleanup (5)**
Deleted: Firebase Cloud Functions, firebase.json, .firebaserc, google-services.json, GoogleService-Info.plist, public/*.html, register_account_simple.dart

---

## MANUAL ACTIONS REQUIRED (3)

M1 — **Rotate Stripe secret key** (Stripe Dashboard — old key in git history)
M2 — **Generate release keystore** (`keytool` → `key.properties`)
M3 — **Enable Leaked Password Protection** (Supabase Dashboard > Auth)

---

## DEFERRED (v1.1+)

**Performance (39 findings)**
6 critical, 11 high, 12 medium, 4 low + P-01 to P-06 from crash audit
None cause crashes or data loss; affects smoothness under load.

**Data Scoping (6)**
D-01 to D-06: Caches/queue not user-scoped. Single-user device for launch.

**Localization**
67+ hardcoded Text(), 45+ InputDecoration across admin/analytics/locations/profile.

**Other**
iOS build scaffolding incomplete (Android-first launch)
`dart:io` in web export (not targeting web)
Non-transactional Supabase writes (needs RPC)
Local cache doesn't prune server-deleted entries
Mixed theming (Colors.* vs theme)
Duplicate home screen + Location model
Hive typeId collisions (3, 5, 9) — latent, not co-registered

---

## COMMITS

`66b22c9` — Switch to Supabase, secure CSV, Android signing
`9103782` — Use httpOnly cookie for admin auth
`ea83c5b` — Remove Firebase files and sender_password
`8f275da` — Remove legacy Firebase hosting files
*uncommitted* — Networking, device compat, localization, compliance, crash fixes
