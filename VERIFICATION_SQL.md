# SQL Verification for Work Shifts Persistence

## Purpose
Verify that timezone conversion and field persistence (unpaid_break_minutes, notes, location) work correctly for work_shifts.

## Steps

1. **Create a new shift in the app:**
   - Date: Any date (e.g., 2025-01-15)
   - Start: 08:00
   - End: 12:00
   - Break: 30 minutes
   - Notes: "DBG"
   - Location: "Office" (optional)

2. **Sync the app data** (ensure entry is saved to Supabase)

3. **Run this SQL query in Supabase SQL Editor:**

```sql
SELECT 
  id,
  entry_id,
  start_time,
  start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Stockholm' AS start_local,
  end_time,
  end_time AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Stockholm' AS end_local,
  unpaid_break_minutes,
  notes,
  location,
  created_at
FROM work_shifts
ORDER BY created_at DESC
LIMIT 5;
```

## Expected Results

For a shift created at 08:00-12:00 local time (Sweden, UTC+1 in winter):

- **start_time**: Should show `2025-01-15T07:00:00Z` (UTC, 1 hour behind local)
- **start_local**: Should show `2025-01-15 08:00:00` (local time preserved)
- **end_time**: Should show `2025-01-15T11:00:00Z` (UTC, 1 hour behind local)
- **end_local**: Should show `2025-01-15 12:00:00` (local time preserved)
- **unpaid_break_minutes**: Should be `30`
- **notes**: Should be `'DBG'`
- **location**: Should be `'Office'` (if provided)

## Alternative Query (Simpler)

If the timezone conversion function doesn't work, use this simpler query:

```sql
SELECT 
  start_time,
  EXTRACT(HOUR FROM start_time AT TIME ZONE 'Europe/Stockholm') AS start_hour_local,
  unpaid_break_minutes,
  notes
FROM work_shifts
WHERE notes = 'DBG'
ORDER BY created_at DESC
LIMIT 1;
```

Expected:
- `start_hour_local` = 8 (08:00 local time)
- `unpaid_break_minutes` = 30
- `notes` = 'DBG'

## Notes

- In **winter** (January), Sweden is **UTC+1**, so 08:00 local = 07:00 UTC
- In **summer** (July), Sweden is **UTC+2**, so 08:00 local = 06:00 UTC
- The app should always store UTC in the database and convert to local when reading
