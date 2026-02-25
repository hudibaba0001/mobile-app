# Performance and Logic Issues Report

## Mobile App (Flutter)

### 1. Inefficient Data Fetching (Repositories)
- **Location:** `apps/mobile_flutter/lib/repositories/supabase_location_repository.dart`
- **Issue:** `getAllLocations` fetches all locations for a user without pagination. This will scale poorly as data grows.
- **Issue:** `syncAllLocations` performs a bulk upsert of potentially large lists, which could time out or hit payload limits.
- **Recommendation:** Implement pagination or infinite scrolling. Use batching for bulk operations.

### 2. Redundant Sync Logic and Full Re-reads (Providers)
- **Location:** `apps/mobile_flutter/lib/providers/location_provider.dart`
- **Issue:** `refreshLocations` re-reads all locations from Hive on every single change (add, update, delete).
- **Issue:** `loadFromCloud` fetches all locations, merges them, and then pushes *all* of them back to the cloud via `_syncAllToCloud`. This is redundant and wasteful.
- **Recommendation:** Update local state incrementally instead of re-reading from disk. Only sync changed items to the cloud.

### 3. Loading All Entries into Memory (Providers)
- **Location:** `apps/mobile_flutter/lib/providers/entry_provider.dart`
- **Issue:** `loadEntries` fetches *all* entries from Supabase (`getAllEntries`). There is no date range filtering or pagination. This is a major scalability issue.
- **Issue:** Filtering (`_applyFilters`) happens in-memory on the full dataset.
- **Recommendation:** Fetch entries based on the currently viewed month/week/range. Implement server-side filtering.

### 4. Inefficient Sync Logic (Providers)
- **Location:** `apps/mobile_flutter/lib/providers/entry_provider.dart`
- **Issue:** `addEntries` (batch add) iterates and calls `addEntry` one by one, resulting in N network requests.
- **Issue:** Fallback sync logic iterates and upserts entries individually.
- **Recommendation:** Use Supabase's bulk insert capabilities.

### 5. UI Performance Bottlenecks (Screens)
- **Location:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Issue:** `_loadRecentEntriesInternal` sorts the entire list of entries on the UI thread every time recent entries are loaded.
- **Issue:** Frequent rebuilds due to `Provider` notifications (`_onProviderDataChanged` calls `setState`).
- **Recommendation:** Move sorting to a background isolate or optimize the data structure. Use `Selector` or finer-grained providers to minimize rebuilds.

### 6. Large Build Method
- **Location:** `apps/mobile_flutter/lib/screens/unified_home_screen.dart`
- **Issue:** The `build` method is very large and complex, creating many widgets inline.
- **Recommendation:** Refactor into smaller, `const` widgets to improve readability and performance.

## Web API (Next.js)

### 1. In-Memory Rate Limiting
- **Location:** `apps/web_api/lib/rate-limit.ts`
- **Issue:** Uses an in-memory `Map` for rate limiting. This state is not shared across server instances or serverless function invocations, making it ineffective in a scaled environment.
- **Recommendation:** Use Redis or a database for distributed rate limiting.

### 2. Security/Logic Flaw in Rate Limiting
- **Location:** `apps/web_api/lib/rate-limit.ts`
- **Issue:** `getClientIdentifier` attempts to parse the JWT token to get the user ID *before* verifying the signature. A malicious user could bypass rate limits by sending fake tokens with rotating IDs.
- **Recommendation:** Verify the token before using its claims, or rate limit by IP first.

### 3. N+1 Database Queries (Balance Calculation)
- **Location:** `apps/web_api/lib/balance-calculator.ts`
- **Issue:** `calculateYearlyBalance` iterates through each month and calls `getActualWorkedMinutes`. `getActualWorkedMinutes` performs a database query. This results in at least 12 queries per request for a full year calculation.
- **Recommendation:** Fetch all necessary data for the year in a single query and aggregate in memory or, better yet, use SQL aggregation.

### 4. Inefficient Date/Duration Calculation
- **Location:** `apps/web_api/lib/balance-calculator.ts`
- **Issue:** Fetches raw start/end times and calculates duration in JavaScript loop.
- **Recommendation:** Use SQL `SUM` and date difference functions to calculate total worked minutes directly in the database.

### 5. Synchronous Database Check in Middleware
- **Location:** `apps/web_api/lib/middleware.ts`
- **Issue:** `withAdminAuth` queries the `profiles` table to check for `is_admin` on every request. This adds latency and load to the database.
- **Recommendation:** Cache the admin status (e.g., in Redis or the JWT itself as a custom claim) or use a session store.

### 6. Redundant Profile Fetching
- **Location:** `apps/web_api/lib/balance-calculator.ts`
- **Issue:** `calculateUserBalances` fetches the profile, and then calls `calculateYearlyBalance` which fetches the profile again.
- **Recommendation:** Pass the profile object to `calculateYearlyBalance`.

## Business Logic Deep Dive

### 1. Single Source of Truth Violation (Calculations)
- **Location:** `apps/mobile_flutter/lib/utils/target_hours_calculator.dart` (Mobile) vs `apps/web_api/lib/balance-calculator.ts` (Web API)
- **Issue:** The Mobile App uses a robust, holiday-aware calculation for target minutes (respecting public holidays and personal red days). The Web API, however, explicitly **ignores holidays and red days** (as noted in its comments: "Simplified version for Sprint 1 - excludes holidays, absences, and red days").
- **Impact:** The Web API will consistently report a balance deficit for any month containing holidays, as it expects work on those days, whereas the Mobile App will correctly report 0 variance (or credit). This leads to inconsistent data between the app and the admin dashboard.
- **Recommendation:** Port the `TargetHoursCalculator` logic (specifically `scheduledMinutesForDate` and holiday handling) to the Web API or move the calculation logic to a shared Supabase Edge Function to ensure a single source of truth.

### 2. Custom Red Days Logic Consistency
- **Location:** `apps/mobile_flutter/lib/services/holiday_service.dart` vs `apps/web_api/lib/balance-calculator.ts`
- **Issue:** The Mobile App fully supports "Custom Red Days" (personal holidays/half-days) via `HolidayService` and `UserRedDayRepository`. The Web API has **no knowledge** of these tables or logic.
- **Impact:** Any personal red days defined by the user in the app will be treated as normal workdays by the Web API, causing further discrepancies in balance calculations.
- **Recommendation:** The Web API must be updated to query the `user_red_days` table and factor these into its target calculation.

### 3. Contract Percentage & Leave Credit
- **Location:** `apps/mobile_flutter/lib/providers/contract_provider.dart` & `apps/mobile_flutter/lib/providers/absence_provider.dart`
- **Finding:** The Mobile App logic appears correct. `ContractProvider` manages `contractPercent`, which scales `weeklyTargetMinutes`. This flows into `TimeProvider` → `scheduled_minutes_resolver.dart`, reducing the daily scheduled minutes. `AbsenceProvider` uses this reduced scheduled amount to calculate paid leave credits.
- **Result:** A user with a 75% contract who takes a full day of leave will correctly be credited for 75% of a full-time day (matching their scheduled obligation).

### 4. Core Formulas
- **Location:** `apps/mobile_flutter/lib/utils/target_hours_calculator.dart`
- **Finding:** The formula `((weeklyTargetMinutes * weekdayCount) / 5.0).round()` is used in both the Mobile App and Web API (for the base calculation). This prevents rounding drift and is correct for standard Monday-Friday schedules.
- **Note:** The divergence lies entirely in the *exceptions* to this formula (holidays/red days), not the base formula itself.
