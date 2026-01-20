# Initial Concept
A Swedish employee “time balance vs employer” app (shadow ledger). It helps field workers log daily work (incl. 2 shifts) + travel minutes in under 30 seconds/day, automatically calculates MTD/YTD plus/minus vs their contract target (calendar-based with Swedish holidays/red days + paid leave credits), and exports simple Excel (XLSX) and CSV reports they can send to payroll/manager to dispute or verify salary hours and travel.

## Primary Users
Hourly field workers in Sweden (home cleaning/home care/maintenance) who must reconcile shifts + travel time against employer targets and payroll reports.

## Critical Features
- **Daily logging in <30 seconds:** Add work shift(s) (support 2 shifts/day) + travel minutes, with smart defaults (copy yesterday, quick time chips).
- **Accurate time balance:** Calendar-based scheduled target minutes per day (Swedish red days), MTD/YTD totals, and paid leave/sick/VAB credits counted toward target (Option A).
- **Clear “plus/minus” payoff:** Home shows “This month (to date): +Xh / −Yh vs target” prominently, including credited hours.
- **Exports (must-have):** One-tap Excel (XLSX) export and CSV export for:
  - (a) time report and (b) travel report
  - audit-like columns: date, worked, travel, absence type, credits, target, variance, running balance
  - output must match across XLSX and CSV (same totals, same rounding rules)
- **Access gating:** Login-only app; account creation + Stripe subscription happens on web; app blocks unless subscription status is trialing/active and terms/privacy accepted.
- **Travel trust rules:** No background GPS tracking. Travel is either manual or an on-demand estimate (“Calculate”) and clearly labeled Auto vs Manual.

## Unique Selling Proposition
It’s not “productivity tracking.” It’s a payroll verification tool for Swedish field workers: a shadow ledger vs employer, with calendar-accurate targets (Swedish red days + leave credits), travel-time reporting, and audit-style Excel (XLSX) + CSV exports. The app’s promise is: log in seconds → see MTD/YTD plus-minus → export proof for payroll disputes, while staying privacy-safe (no background GPS tracking; travel can be manual or on-demand estimate).

## Non-Functional Requirements and Constraints
- **Privacy-first:** No background GPS tracking; if travel time is auto-estimated, it must be on-demand (“Calculate” button) and clearly labeled Auto vs Manual. Addresses are sensitive.
- **Security:** Supabase Auth + RLS so users can only read/write their own data (profiles, entries, reports). No admin surfaces in production employee builds.
- **Reliability & performance:** App must feel instant; compute MTD/YTD locally where possible; paginate history; avoid heavy queries.
- **Offline-first for logging (strongly preferred):** Allow creating/editing entries offline and sync when online (conflict strategy: last-write-wins with timestamps or simple per-entry versioning).
- **Cost-awareness:** If using Maps/autocomplete, cache aggressively and only call APIs on confirm to avoid cost blowups.
- **Accessibility basics:** Readable font sizes, good contrast, tappable controls (field-worker friendly).