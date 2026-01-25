# User Verification Guide: Work Shifts Persistence

## How to Verify the Fix Works

### Step 1: Create a Test Work Entry in the App

1. **Open the app** and navigate to the home screen
2. **Tap "Add Work Entry"** or "Log Work"
3. **Fill in the form**:
   - **Date**: January 15, 2025 (or today's date)
   - **Start Time**: 08:00
   - **End Time**: 12:00
   - **Unpaid Break Minutes**: 30
   - **Notes**: "DBG" (or any test text)
   - **Location**: "Office" (or any location)
4. **Save the entry**

### Step 2: Check the Debug Console

After saving, check your debug console/logs. You should see:

```
UnifiedEntryForm: Shift 1 before save - break=30, notes=DBG, location=Office
SupabaseEntryService: Shift timezone conversion - 
  start local: 2025-01-15T08:00:00, UTC: 2025-01-15T07:00:00Z, 
  break: 30, notes: DBG
SupabaseEntryService: ✅ 1 work shift(s) inserted
```

**What to verify**:
- ✅ Break minutes = 30
- ✅ Notes = "DBG"
- ✅ Location = "Office"
- ✅ Start local = 08:00 (your local time)
- ✅ Start UTC = 07:00Z (UTC time, 1 hour earlier for Sweden in January)

### Step 3: Verify in the App UI

1. **Go to History/Reports screen**
2. **Find your entry** (should show today's date)
3. **Tap on the entry** to view details
4. **Verify**:
   - ✅ Start time shows **08:00** (local time)
   - ✅ End time shows **12:00** (local time)
   - ✅ Break shows **30 minutes**
   - ✅ Notes shows **"DBG"**
   - ✅ Location shows **"Office"**

### Step 4: Verify in Supabase Database

#### Option A: Using Supabase Dashboard

1. **Open Supabase Dashboard** → Your Project → Table Editor
2. **Select `work_shifts` table**
3. **Find your entry** (sort by `created_at` DESC)
4. **Check the columns**:

| Column | Expected Value | What It Means |
|--------|---------------|---------------|
| `start_time` | `2025-01-15 07:00:00+00` | UTC time (1 hour earlier) |
| `end_time` | `2025-01-15 11:00:00+00` | UTC time (1 hour earlier) |
| `unpaid_break_minutes` | `30` | Break minutes persisted ✅ |
| `notes` | `"DBG"` | Notes persisted ✅ |
| `location` | `"Office"` | Location persisted ✅ |

#### Option B: Using SQL Query

Run this query in Supabase SQL Editor:

```sql
SELECT 
  start_time,
  start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Stockholm' AS start_local,
  end_time,
  end_time AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Stockholm' AS end_local,
  unpaid_break_minutes,
  notes,
  location,
  created_at
FROM work_shifts
WHERE notes = 'DBG'  -- Or use your test notes
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results**:

```
start_time: 2025-01-15 07:00:00+00
start_local: 2025-01-15 08:00:00
end_time: 2025-01-15 11:00:00+00
end_local: 2025-01-15 12:00:00
unpaid_break_minutes: 30
notes: "DBG"
location: "Office"
```

### Step 5: Test Round-Trip (Edit and Re-read)

1. **Edit the entry** you just created
2. **Change**:
   - Break: 45 minutes
   - Notes: "Updated DBG"
3. **Save**
4. **Verify in database** that changes persisted
5. **Re-open the entry** in the app
6. **Verify** it shows the updated values

### Step 6: Test Multiple Shifts

1. **Create a new work entry** with **multiple shifts**:
   - Shift 1: 08:00-12:00, break=30, notes="Morning"
   - Shift 2: 13:00-17:00, break=15, notes="Afternoon"
2. **Save**
3. **Verify in database** that **both shifts** are saved as **separate entries** (atomic entries)
4. **Check** that each shift has:
   - ✅ Correct timezone conversion
   - ✅ Correct break minutes
   - ✅ Correct notes

## What Success Looks Like

### ✅ All Tests Pass

- **App UI**: Shows correct times, breaks, notes, location
- **Database**: Stores UTC times correctly, preserves all fields
- **Round-trip**: Edit and re-read works correctly
- **Timezone**: Local times preserved (08:00 local → 07:00 UTC → 08:00 local)

### ❌ If Something Fails

**If times are wrong**:
- Check timezone conversion logs
- Verify `start_time` in DB is UTC (1 hour earlier for Sweden in January)
- Verify `start_local` calculation shows correct local time

**If break/notes are missing**:
- Check debug logs for "before save" message
- Verify `unpaid_break_minutes` and `notes` columns in DB
- Check that `Entry.makeWorkAtomicFromShift` is being used

**If location is missing**:
- Verify location is set in the form
- Check `location` column in DB
- Verify shift has location set before save

## Quick Test Checklist

- [ ] Create entry: 08:00-12:00, break=30, notes="DBG"
- [ ] Check debug logs show correct values
- [ ] Verify in app UI shows correct values
- [ ] Verify in database: `start_local` = 08:00, `unpaid_break_minutes` = 30, `notes` = "DBG"
- [ ] Edit entry and verify changes persist
- [ ] Create entry with multiple shifts and verify all persist

## Troubleshooting

### Debug Logs Not Showing?

Make sure you're running in **debug mode** (not release mode):
```bash
flutter run --debug
```

### Database Query Not Working?

If timezone conversion in SQL doesn't work, try:
```sql
SELECT 
  start_time,
  unpaid_break_minutes,
  notes,
  location
FROM work_shifts
ORDER BY created_at DESC
LIMIT 5;
```

Then manually verify:
- `start_time` is UTC (should be 1 hour earlier than local)
- `unpaid_break_minutes` matches what you entered
- `notes` matches what you entered

### Times Showing Wrong in UI?

1. Check that `SupabaseEntryService` is converting UTC → local on read
2. Verify `toLocal()` is being called in read methods
3. Check debug logs for timezone conversion messages

## Summary

**To claim/verify the fix works**:

1. ✅ Create a test entry with known values (08:00-12:00, break=30, notes="DBG")
2. ✅ Check debug logs confirm values before save
3. ✅ Verify in app UI shows correct values
4. ✅ Run SQL query to verify database has:
   - `start_local` = 08:00 (local time preserved)
   - `unpaid_break_minutes` = 30
   - `notes` = "DBG"
5. ✅ Edit and re-read to verify round-trip works

**If all steps pass → Fix is working! ✅**
