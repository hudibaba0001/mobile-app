# Fix Status (2026-02-11)

| Finding | Status | Fix |
|---------|--------|-----|
| P0-1: AnalyticsApi auth token wrong (`user?.aud`) | FIXED | Uses `session?.accessToken` with null guard + 15s timeout |
| P0-2: `addEntries` never queues offline creates | FIXED | Now queues via `_syncQueue.queueCreate()` with timestamp |
| P0-3: Travel sync payload drops `from/to` | FIXED | `Entry.toJson()` always includes `from_location`/`to_location` |
| P0-4: SyncQueue init race | FIXED | `_syncQueueReady` Future; all ops await `_ensureSyncQueueReady()` |
| P0-5: Local caches not user-scoped | DEFERRED | Requires cache namespace refactor |
| P0-6: Push-before-pull overwrites cloud settings | FIXED | Removed auto-push from `setSupabaseDeps()` |
| P0-7: `main_prod.dart` missing critical wiring | FIXED | Brought to full parity with `main.dart` |
| P1-1: SyncQueue not filtered by user | DEFERRED | Queue stores userId; RLS prevents cross-account writes |
| P1-2: `queueDelete` leaves pending updates | FIXED | Now removes both creates AND updates |
| P1-3: Ops dropped after max retries silently | DEFERRED | Needs user-visible notification |
| P1-4: Non-atomic multi-table writes | DEFERRED | Needs RPC/Edge Function |
| P1-5: Connectivity only interface-level | DEFERRED | Quality improvement |
| P1-6: Auto-sync callback not unregistered | DEFERRED | Quality improvement |
| P2-1: No HTTP timeouts | FIXED | 15s timeout on all MapService, AdminApiService, AnalyticsApi calls |
| P2-2: AdminApiService wraps all exceptions as 500 | FIXED | `on ApiException { rethrow; }` preserves original codes |
| P2-3: Retry helper logs as "storage" errors | DEFERRED | Cosmetic logging issue |
| P2-4: Entry loading not reentrancy-guarded | DEFERRED | Performance improvement |
| P2-5: Local cache doesn't prune deleted entries | DEFERRED | Needs tombstone strategy |
| P2-6: Redundant profile fetch at startup | DEFERRED | Performance improvement |
| P3-1 to P3-4: Debug PII, hardcoded tokens/keys, public URLs | DEFERRED | Low priority |

---

**Scope (No Code Changes — original audit)**
- Analyzed network-related code in `apps/mobile_flutter` (Supabase, HTTP APIs, connectivity, offline caches, sync queue, async lifecycle).
- Ran `flutter analyze` in `apps/mobile_flutter` (no analyzer findings; runtime/logic issues remain).

**Network Surface Map (All Endpoints)**
- **Supabase (PostgREST tables)**
  - `entries` + related: `travel_segments`, `work_shifts` via `SupabaseEntryService` (`apps/mobile_flutter/lib/services/supabase_entry_service.dart:11`)
  - `profiles` via `ProfileService`, `SettingsProvider`, `SupabaseAuthService.isAdmin` (`apps/mobile_flutter/lib/services/profile_service.dart:11`, `apps/mobile_flutter/lib/providers/settings_provider.dart:57`, `apps/mobile_flutter/lib/services/supabase_auth_service.dart:220`)
  - `absences` via `SupabaseAbsenceService` (`apps/mobile_flutter/lib/services/supabase_absence_service.dart:15`)
  - `locations` via `SupabaseLocationRepository` (`apps/mobile_flutter/lib/repositories/supabase_location_repository.dart:7`)
  - `email_settings` via `SupabaseEmailSettingsRepository` (`apps/mobile_flutter/lib/repositories/supabase_email_settings_repository.dart:7`)
  - `balance_adjustments` via `BalanceAdjustmentRepository` (`apps/mobile_flutter/lib/repositories/balance_adjustment_repository.dart:7`)
  - `user_red_days` via `UserRedDayRepository` (`apps/mobile_flutter/lib/repositories/user_red_day_repository.dart:9`)
- **Supabase Storage buckets**
  - `attachments`, `avatars` via `StorageService` (`apps/mobile_flutter/lib/services/storage_service.dart:6`)
- **HTTP (custom backend)**
  - Admin/edge functions: `/users`, `/analytics/dashboard`, `/users/{uid}/enable|disable`, `/users/{uid}` via `AdminApiService` (`apps/mobile_flutter/lib/services/admin_api_service.dart:109`)
  - “Server analytics” GET `/analytics/dashboard` via `AnalyticsApi` (base from `KVIKTIME_API_BASE`) (`apps/mobile_flutter/lib/services/analytics_api.dart:13`, `apps/mobile_flutter/lib/config/app_config.dart:3`)
- **HTTP (Mapbox)**
  - Directions: `https://api.mapbox.com/directions/...` and Geocoding: `https://api.mapbox.com/geocoding/...` via `MapService` (`apps/mobile_flutter/lib/services/map_service.dart:13`)

**Async Operations Inventory (All Major Async/Stream/Background Flows)**
- Supabase auth stream listener: `_supabase.auth.onAuthStateChange.listen(...)` (`apps/mobile_flutter/lib/services/supabase_auth_service.dart:57`)
- Connectivity stream listener: `_connectivity.onConnectivityChanged.listen(...)` (`apps/mobile_flutter/lib/providers/network_status_provider.dart:49`)
- Connectivity-restored callbacks list + execution loop (`apps/mobile_flutter/lib/providers/network_status_provider.dart:16`, `apps/mobile_flutter/lib/providers/network_status_provider.dart:99`)
- Auto-sync hook registered from widget lifecycle (post-frame callback) (`apps/mobile_flutter/lib/main.dart:351`)
- Offline sync queue persistence + processing with retry (`apps/mobile_flutter/lib/services/sync_queue_service.dart:81`, `apps/mobile_flutter/lib/services/sync_queue_service.dart:186`)
- Retry helper (exponential backoff) used across entry CRUD + queue processing (`apps/mobile_flutter/lib/utils/retry_helper.dart:11`)
- Heavy “load everything” entry fetch used from many screens/widgets (`apps/mobile_flutter/lib/providers/entry_provider.dart:73`, `apps/mobile_flutter/lib/widgets/app_scaffold.dart:27`)

---

## **Exhaustive Findings (Issues + Effects)**

### **P0 / Critical — Data Loss, Cross-Account Leakage, or Core Feature Breakage**

- **P0-1: “Server analytics” auth token is wrong (almost guaranteed 401/403)**
  - `AnalyticsApi` uses `Supabase.instance.client.auth.currentUser` then sets `token = user?.aud` and sends `Authorization: Bearer $token`. `aud` is not an access token. (`apps/mobile_flutter/lib/services/analytics_api.dart:27`, `apps/mobile_flutter/lib/services/analytics_api.dart:28`, `apps/mobile_flutter/lib/services/analytics_api.dart:32`)
  - **Effect:** server analytics endpoint will reject requests; error handling shows “Access denied” even for valid sessions; may also send `Bearer null`. Customer/admin reporting becomes unreliable.

- **P0-2: Offline creation via `EntryProvider.addEntries` never queues for later sync**
  - In `addEntries`, on Supabase failure it saves locally but does **not** call `_syncQueue.queueCreate(...)` (unlike `addEntry`). (`apps/mobile_flutter/lib/providers/entry_provider.dart:264`, `apps/mobile_flutter/lib/providers/entry_provider.dart:296`)
  - **Effect:** any multi-entry create (your canonical “atomic per shift/leg” flow) done offline stays local forever; cloud never receives it unless there’s a separate “migrate/sync local” action that catches it (and current logic is incomplete).

- **P0-3: Even when queueing a travel Entry, the queued payload drops `from/to` and breaks later Supabase travel segment writes**
  - `Entry.makeTravelAtomicFromLeg` sets both legacy `from/to/travelMinutes` and also sets `travelLegs` (length 1). (`apps/mobile_flutter/lib/models/entry.dart:624`, `apps/mobile_flutter/lib/models/entry.dart:654`)
  - `Entry.toJson()` prefers `travel_legs` when present and **does not include** `from_location` / `to_location` in that branch. (`apps/mobile_flutter/lib/models/entry.dart:331`, `apps/mobile_flutter/lib/models/entry.dart:334`, `apps/mobile_flutter/lib/models/entry.dart:341`)
  - Sync queue stores `entry.toJson()` (`apps/mobile_flutter/lib/services/sync_queue_service.dart:134`, `apps/mobile_flutter/lib/services/sync_queue_service.dart:140`) and later reconstructs via `Entry.fromJson` (`apps/mobile_flutter/lib/providers/entry_provider.dart:831`), which reads `from_location`/`to_location` (now missing) so `entry.from` and `entry.to` become null. (`apps/mobile_flutter/lib/models/entry.dart:365`, `apps/mobile_flutter/lib/models/entry.dart:370`)
  - `SupabaseEntryService.addEntry` inserts travel segment only if `entry.from != null && entry.to != null`. (`apps/mobile_flutter/lib/services/supabase_entry_service.dart:327`, `apps/mobile_flutter/lib/services/supabase_entry_service.dart:328`)
  - **Effect:** queued travel create/update can sync an `entries` row but fail to create `travel_segments` rows, producing “blank” travel entries in cloud (or deleting segments on update and not recreating them). This is direct data loss.

- **P0-4: SyncQueue initialization race can overwrite persisted operations**
  - `EntryProvider` calls `_initSyncQueue()` from constructor without awaiting; `_syncQueue.init()` loads persisted ops asynchronously. (`apps/mobile_flutter/lib/providers/entry_provider.dart:40`, `apps/mobile_flutter/lib/providers/entry_provider.dart:44`)
  - If a user performs an offline operation before init finishes, `enqueue()` persists the in-memory `_queue` (missing loaded ops), potentially wiping previously persisted pending operations. (`apps/mobile_flutter/lib/services/sync_queue_service.dart:81`, `apps/mobile_flutter/lib/services/sync_queue_service.dart:272`)
  - **Effect:** silent loss of pending offline ops across restarts (worst-case: user loses offline work history).

- **P0-5: Local caches are not user-scoped for multiple user-specific datasets (cross-account data exposure)**
  - **Absences**: `AbsenceEntry` has no `userId` field; Hive cache is global and `AbsenceProvider._loadFromHive()` loads all values into memory without filtering by user. (`apps/mobile_flutter/lib/models/absence.dart:13`, `apps/mobile_flutter/lib/providers/absence_provider.dart:34`)
  - **Balance adjustments**: model has `userId`, but provider loads all cached values and doesn’t filter by current user. (`apps/mobile_flutter/lib/models/balance_adjustment.dart:8`, `apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:37`)
  - **Personal red days**: model has `userId`, but `HolidayService._loadFromHive()` doesn’t filter by `_userId`. (`apps/mobile_flutter/lib/models/user_red_day.dart:26`, `apps/mobile_flutter/lib/services/holiday_service.dart:105`)
  - **Locations**: `Location` has no `userId`, but cloud sync uses per-user `user_id`. Local store is global. (`apps/mobile_flutter/lib/models/location.dart:6`, `apps/mobile_flutter/lib/repositories/supabase_location_repository.dart:14`)
  - **Email settings**: local Hive box stores one shared settings object; cloud is per-user. (`apps/mobile_flutter/lib/providers/email_settings_provider.dart:38`, `apps/mobile_flutter/lib/repositories/supabase_email_settings_repository.dart:52`)
  - **Contract settings**: stored in SharedPreferences with global keys (no userId namespace). (`apps/mobile_flutter/lib/providers/contract_provider.dart:32`, `apps/mobile_flutter/lib/providers/contract_provider.dart:304`)
  - **Effect:** sign-out/sign-in on shared devices can show previous user’s sensitive data and/or sync previous user’s local data into the next user’s cloud (locations/email settings are especially dangerous because local is global but cloud is per-user).

- **P0-6: Cloud preference “push before pull” can overwrite server state with defaults/stale local**
  - `SettingsProvider.setSupabaseDeps` immediately calls `_syncToCloud()` (write) (`apps/mobile_flutter/lib/providers/settings_provider.dart:26`, `apps/mobile_flutter/lib/providers/settings_provider.dart:30`)
  - In `main.dart`, `settingsProvider.setSupabaseDeps(...)` is called **before** `await settingsProvider.loadFromCloud();` (`apps/mobile_flutter/lib/main.dart:112`, `apps/mobile_flutter/lib/main.dart:116`, `apps/mobile_flutter/lib/main.dart:119`)
  - Same pattern for `EmailSettingsProvider`: `setSupabaseDeps` calls `_syncToCloud()` then `loadFromCloud()` is called afterward. (`apps/mobile_flutter/lib/providers/email_settings_provider.dart:23`, `apps/mobile_flutter/lib/main.dart:184`)
  - Location provider also immediately pushes local to cloud on deps set. (`apps/mobile_flutter/lib/providers/location_provider.dart:20`, `apps/mobile_flutter/lib/main.dart:217`)
  - **Effect:** on a fresh install or second device, cloud settings can be overwritten by local defaults; user loses server-side preferences/settings.

- **P0-7: `main_prod.dart` is missing critical network wiring compared to `main.dart` (production parity risk)**
  - `main_prod.dart` does not set Supabase deps for `SettingsProvider` and does not call `loadFromCloud()`. (`apps/mobile_flutter/lib/main_prod.dart:91`)
  - `main_prod.dart` also doesn’t wire Supabase repos for locations/email settings, doesn’t provide `NetworkStatusProvider`, and doesn’t initialize Hive caches for absences/adjustments/red days. (`apps/mobile_flutter/lib/main_prod.dart:10`, `apps/mobile_flutter/lib/main.dart:177`)
  - **Effect:** production build may have fundamentally different behavior: no cloud sync for settings, no offline caching for several datasets, no auto-sync of queued entry operations.

---

### **P1 / High — Severe Reliability/Correctness Risks**

- **P1-1: SyncQueue is not filtered by current user**
  - Queue entries store `userId`, but `processPendingSync` processes the entire queue and executes operations using the operation payload, regardless of who is currently logged in. (`apps/mobile_flutter/lib/services/sync_queue_service.dart:20`, `apps/mobile_flutter/lib/providers/entry_provider.dart:827`)
  - **Effect:** attempts to sync previous user’s operations while a new user is logged in; may fail due to RLS (best case) or cause unintended writes (worst case if backend policies are misconfigured).

- **P1-2: `queueDelete` removes a pending create but can leave pending updates behind**
  - If a pending create exists, it removes it and returns early, without removing updates for the same entry. (`apps/mobile_flutter/lib/services/sync_queue_service.dart:159`)
  - **Effect:** later queue processing attempts “update non-existent entry”, increasing retries/noise and potentially dropping unrelated ops due to retry limits.

- **P1-3: Operations are dropped after max retries with no durable user-visible remediation**
  - After `retryCount >= maxRetries`, op is removed. (`apps/mobile_flutter/lib/services/sync_queue_service.dart:231`)
  - **Effect:** silent permanent data loss (user thinks “it will sync later”, but it can be discarded).

- **P1-4: Entry create/update/delete across normalized tables is non-atomic**
  - `SupabaseEntryService.addEntry` inserts `entries` then inserts `travel_segments`/`work_shifts` separately. (`apps/mobile_flutter/lib/services/supabase_entry_service.dart:321`, `apps/mobile_flutter/lib/services/supabase_entry_service.dart:327`)
  - `updateEntry` deletes segments/shifts then reinserts. (`apps/mobile_flutter/lib/services/supabase_entry_service.dart:484`, `apps/mobile_flutter/lib/services/supabase_entry_service.dart:506`)
  - **Effect:** partial writes during transient failures can leave orphaned base entries (missing segments/shifts), or wipe segments/shifts on update if insert fails.

- **P1-5: Connectivity “online” is only interface-level, not “internet reachable”**
  - `NetworkStatusProvider` sets online if any `ConnectivityResult != none`. (`apps/mobile_flutter/lib/providers/network_status_provider.dart:61`)
  - **Effect:** “online” state may trigger sync attempts on captive portals / no-internet Wi-Fi; repeated failures inflate retries and can lead to operations being dropped.

- **P1-6: Auto-sync callback registration is not removed, risking duplicated sync triggers**
  - `_NetworkSyncSetup` registers a callback but never unregisters on widget disposal. (`apps/mobile_flutter/lib/main.dart:356`, `apps/mobile_flutter/lib/main.dart:361`)
  - **Effect:** multiple registrations (hot reloads, rebuild patterns, route reparenting) can run multiple `processPendingSync()` concurrently/serially, increasing load and race probability.

---

### **P2 / Medium — Incorrect/Misleading Errors, Performance, Maintainability**

- **P2-1: HTTP calls lack timeouts and consistent retry/backoff**
  - `MapService` uses `http.get` without `.timeout`. (`apps/mobile_flutter/lib/services/map_service.dart:92`, `apps/mobile_flutter/lib/services/map_service.dart:163`)
  - `AdminApiService` uses `_client.get/post/delete` without timeouts. (`apps/mobile_flutter/lib/services/admin_api_service.dart:121`, `apps/mobile_flutter/lib/services/admin_api_service.dart:207`)
  - `AnalyticsApi` uses `_client.get` without timeout. (`apps/mobile_flutter/lib/services/analytics_api.dart:29`)
  - `ApiConfig.timeoutSeconds` exists but is unused. (`apps/mobile_flutter/lib/config/api_config.dart:12`)
  - **Effect:** hanging requests can stall UX; retries are inconsistent across modules.

- **P2-2: `AdminApiService` loses status fidelity by wrapping all exceptions as code 500**
  - Catch block wraps even `ApiException` into a new `ApiException(code: 500, ...)`. (`apps/mobile_flutter/lib/services/admin_api_service.dart:132`, `apps/mobile_flutter/lib/services/admin_api_service.dart:136`)
  - **Effect:** callers cannot distinguish 401 vs 500 vs parsing failures; UI error handling and telemetry become noisy/incorrect.

- **P2-3: Retry helper logs network retries as “storage” errors**
  - `RetryHelper.executeWithRetry` calls `ErrorHandler.handleStorageError(...)` even for network retries. (`apps/mobile_flutter/lib/utils/retry_helper.dart:38`)
  - **Effect:** misclassified logs/telemetry; harder to triage production incidents.

- **P2-4: Entry loading is called from many places and is not reentrancy-guarded**
  - `loadEntries()` sets `_isLoading` but does not early-return if already loading. (`apps/mobile_flutter/lib/providers/entry_provider.dart:73`)
  - Called from `AppScaffold.didChangeDependencies`, home screens, history/reports/time balance. (`apps/mobile_flutter/lib/widgets/app_scaffold.dart:27`, `apps/mobile_flutter/lib/screens/unified_home_screen.dart:49`, `apps/mobile_flutter/lib/screens/history_screen.dart:73`)
  - **Effect:** overlapping Supabase fetches (3 queries each) + local cache writes; wasted bandwidth, flicker, race-y final state.

- **P2-5: Entry local cache sync does not remove server-deleted entries**
  - `_syncToLocalCache` only `put`s entries; no reconciliation/removal of missing ones. (`apps/mobile_flutter/lib/providers/entry_provider.dart:633`)
  - **Effect:** “ghost” entries can reappear when offline fallback loads from Hive after a server delete (especially if delete happened on another device).

- **P2-6: `ProfileService.fetchProfile()` is called in gate + also `ContractProvider.loadFromSupabase()` is called immediately after**
  - `AccountStatusGate._loadProfile()` does `fetchProfile()` and then also calls `contractProvider.loadFromSupabase()` which fetches profile again. (`apps/mobile_flutter/lib/screens/account_status_gate.dart:73`, `apps/mobile_flutter/lib/screens/account_status_gate.dart:78`)
  - **Effect:** redundant network calls at app start/resume; increases latency and error frequency.

---

### **P3 / Low — Observability/Privacy Hygiene, Minor Correctness**

- **P3-1: Debug logging includes PII (addresses, entry notes, full entry JSON)**
  - Mapbox logs origin/destination text. (`apps/mobile_flutter/lib/services/map_service.dart:89`)
  - EntryProvider logs `entry.toJson()` on sync failures. (`apps/mobile_flutter/lib/providers/entry_provider.dart:128`)
  - **Effect:** sensitive user data may appear in device logs / crash reports.

- **P3-2: Mapbox token is hard-coded**
  - (`apps/mobile_flutter/lib/config/map_config.dart:18`)
  - **Effect:** token rotation/segmentation by environment is harder; exposure if repo is public.

- **P3-3: Supabase URL and anon key are hard-coded**
  - (`apps/mobile_flutter/lib/config/supabase_config.dart:6`)
  - **Effect:** environment separation harder; key rotation requires app update (anon key is “public”, but still operationally undesirable).

- **P3-4: StorageService returns public URLs**
  - Uses `getPublicUrl` for attachments/avatars. (`apps/mobile_flutter/lib/services/storage_service.dart:48`, `apps/mobile_flutter/lib/services/storage_service.dart:92`)
  - **Effect:** if buckets are public (or misconfigured), user content may be broadly accessible; consider signed URLs if privacy required.

---

## **Concrete Failure Scenarios (How These Issues Manifest)**

- **Offline create from Unified Entry Form**
  - Unified form creates multiple entries and calls `EntryProvider.addEntries(...)`. (`apps/mobile_flutter/lib/widgets/unified_entry_form.dart:1907`)
  - If offline, Supabase insert fails; entries are saved to Hive but **not queued**; app may show error; cloud never receives them. (`apps/mobile_flutter/lib/providers/entry_provider.dart:296`, `apps/mobile_flutter/lib/providers/entry_provider.dart:320`)
  - If a single entry is created via `addEntry` offline, it is queued—but queued travel entries can lose `from/to` and sync without travel segments (data loss). (`apps/mobile_flutter/lib/models/entry.dart:331`, `apps/mobile_flutter/lib/services/supabase_entry_service.dart:327`)

- **User A logs out, User B logs in**
  - Absences/adjustments/red days/locations/email settings/contract settings can show User A’s cached data and/or get pushed to User B’s cloud because caches are global and/or not filtered. (See P0-5 references)

- **Fresh install on second device**
  - App pushes local defaults to `profiles` before pulling cloud settings; cloud preferences can be overwritten immediately. (`apps/mobile_flutter/lib/providers/settings_provider.dart:26`, `apps/mobile_flutter/lib/main.dart:116`)

---

# **Phased Remediation Plan (All Endpoints + Async Ops Covered)**

## **Phase 0 — Parity + Inventory Lock (Stop drift)**
- Align app entrypoints so production uses the same provider wiring and sync behavior as development:
  - Compare/merge `apps/mobile_flutter/lib/main.dart:170` and `apps/mobile_flutter/lib/main_prod.dart:105` responsibilities (network status, cache init, Supabase deps for settings/locations/email, auto-sync).
- Define a single source of truth for all network configuration:
  - Supabase URL/keys, function base URL, API base, Mapbox token (environment-based).
  - Ensure `apps/mobile_flutter/lib/config/api_config.dart:12` is actually enforced in all HTTP calls.
- Deliverable: “Network Contract” doc listing every endpoint/table/bucket and its offline policy (read-only cache vs offline-write+sync).

## **Phase 1 — Auth & HTTP Foundations (Make calls correct + bounded)**
- Fix token sourcing and header strategy:
  - `AnalyticsApi` must use Supabase session access token, not `user.aud` (`apps/mobile_flutter/lib/services/analytics_api.dart:28`).
  - Standardize behavior when token/session is null/expired (fail fast with actionable error vs silent null).
- Add timeouts + consistent retry policies for:
  - Mapbox (`apps/mobile_flutter/lib/services/map_service.dart:92`)
  - Admin API (`apps/mobile_flutter/lib/services/admin_api_service.dart:121`)
  - Analytics API (`apps/mobile_flutter/lib/services/analytics_api.dart:29`)
- Ensure `SupabaseAuthService.ensureValidSession()` is actually used before calls that require auth (`apps/mobile_flutter/lib/services/supabase_auth_service.dart:120`).

## **Phase 2 — Data Safety on Supabase (Atomicity + correctness per table)**
- **`entries` / `travel_segments` / `work_shifts`**
  - Replace multi-step “insert base then insert related” with an atomic server-side operation (transaction/RPC) or a robust compensation strategy.
  - Prevent “delete segments then fail to reinsert” on update (`apps/mobile_flutter/lib/services/supabase_entry_service.dart:484`).
- **`profiles`**
  - Enforce pull-before-push semantics for settings/contract/email sync to avoid overwriting cloud (`apps/mobile_flutter/lib/providers/settings_provider.dart:26`, `apps/mobile_flutter/lib/providers/email_settings_provider.dart:23`).
- **`locations`, `email_settings`**
  - Decide authoritative source + conflict strategy (cloud wins vs local wins vs timestamp wins). Current best-effort fire-and-forget is unsafe for real sync.

## **Phase 3 — Offline Persistence Hardening (Per-user scoping + privacy)**
- Namespace every local cache by user (or clear on logout) for:
  - Absences (`apps/mobile_flutter/lib/providers/absence_provider.dart:34`)
  - Balance adjustments (`apps/mobile_flutter/lib/providers/balance_adjustment_provider.dart:37`)
  - Red days (`apps/mobile_flutter/lib/services/holiday_service.dart:105`)
  - Locations (`apps/mobile_flutter/lib/models/location.dart:6`)
  - Email settings (`apps/mobile_flutter/lib/providers/email_settings_provider.dart:38`)
  - Contract settings (SharedPreferences keys in `apps/mobile_flutter/lib/providers/contract_provider.dart:32`)
- Sensitive-at-rest review:
  - Sync queue JSON (`apps/mobile_flutter/lib/services/sync_queue_service.dart:68`)
  - Travel route cache keys include address strings (`apps/mobile_flutter/lib/services/travel_cache_service.dart:41`)
  - Email sender password in Hive (in `EmailSettings` via `apps/mobile_flutter/lib/providers/email_settings_provider.dart:144`)
- Add eviction/limits:
  - Travel cache size cap + LRU; sync queue cap/backpressure; entry cache reconciliation.

## **Phase 4 — Sync Engine Overhaul (Correctness first, then UX)**
- Fix entry sync correctness end-to-end:
  - `EntryProvider.addEntries` must behave like `addEntry` in offline mode (queue creates) (`apps/mobile_flutter/lib/providers/entry_provider.dart:264`).
  - Sync payload must be stable and compatible with server writes:
    - Either ensure `Entry.toJson()` always includes `from_location/to_location` even when `travel_legs` exists, or stop using `Entry.toJson()` as the wire payload for sync (create a dedicated sync DTO).
  - Ensure queue init completes before enqueue/persist to avoid wiping stored ops (`apps/mobile_flutter/lib/providers/entry_provider.dart:44`).
  - Make queue user-scoped or filter on processing (`apps/mobile_flutter/lib/providers/entry_provider.dart:827`).
  - Improve queue compaction rules:
    - create+update collapse; create+delete removes both; delete removes pending update too (`apps/mobile_flutter/lib/services/sync_queue_service.dart:159`).
  - On successful create/update, refresh local cache with server canonical version (IDs, timestamps) to avoid divergence.
- Connectivity improvements:
  - Add “actual internet reachable” checks (not just connectivity type) before auto-sync.
  - Debounce and ensure callback registration/removal symmetry (`apps/mobile_flutter/lib/main.dart:361`).

## **Phase 5 — Validation (Per-endpoint test matrix + failure injection)**
- Add integration tests for:
  - Offline create (single and batch) -> queued -> online sync -> server contains full data (including travel segments and work shifts).
  - Offline update travel entry -> does not delete segments without reinsert.
  - User switch: cached data never leaks across accounts.
  - Captive portal: connectivity says online but internet unreachable -> no destructive sync behavior.
- Observability:
  - Standard error taxonomy (network vs auth vs schema vs offline) and structured logging without PII.

---

**Top “Fix-First” Order (Fastest risk reduction)**
- Fix `AnalyticsApi` token (`apps/mobile_flutter/lib/services/analytics_api.dart:28`)
- Make `EntryProvider.addEntries` queue offline creates (`apps/mobile_flutter/lib/providers/entry_provider.dart:264`)
- Fix travel sync payload mismatch (`apps/mobile_flutter/lib/models/entry.dart:331`)
- Eliminate sync queue init race (`apps/mobile_flutter/lib/providers/entry_provider.dart:44`)
- User-scope or clear local caches on logout (Absences/Adjustments/RedDays/Locations/Email/Contract) (see P0-5 refs)
- Prevent push-before-pull for cloud settings (`apps/mobile_flutter/lib/providers/settings_provider.dart:26`, `apps/mobile_flutter/lib/main.dart:116`)
- Bring `main_prod.dart` wiring to parity (`apps/mobile_flutter/lib/main_prod.dart:91`)

If you want, I can also produce a per-endpoint “current state vs desired offline policy” matrix (read-only cache vs offline-write+sync vs online-only) to make the implementation plan executable sprint-by-sprint.