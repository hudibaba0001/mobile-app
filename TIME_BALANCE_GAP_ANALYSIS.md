# Time Balance Calculation Engine - Gap Analysis

## Current Status Assessment

### ✅ **IMPLEMENTED** (But May Need Verification)

#### 1. **Time Balance Calculation Engine** ✅
**Location:** `lib/providers/time_provider.dart`
- **Status:** FULLY IMPLEMENTED
- **Features:**
  - Day-by-day calculation in `calculateBalances()`
  - Monthly/yearly rollups with calendar logic
  - Opening balance support (`openingFlexMinutes`)
  - Tracking start date filtering
  - Balance adjustments integration
- **Potential Issues:**
  - May not be called automatically on entry changes
  - Error handling could be improved
  - Debug logging is extensive but may hide issues

#### 2. **Red Day (Holiday) Handling** ✅
**Location:** `lib/utils/target_hours_calculator.dart`
- **Status:** IMPLEMENTED for auto holidays
- **Features:**
  - `SwedenHolidayCalendar` integration
  - `scheduledMinutesForDate()` respects holidays (returns 0 for red days)
  - Half-day red day support via `scheduledMinutesWithRedDayInfo()`
- **MISSING:**
  - ❌ **Personal red days NOT integrated** - Only auto holidays are used
  - ❌ **User red days from `HolidayService` not passed to calculator**
  - ❌ **Half-day red days not used in time balance calculations**

**Fix Needed:**
```dart
// In time_provider.dart, line 178-182:
// Currently only uses _holidays (auto holidays)
// Need to also check HolidayService for personal red days
final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
  date: date,
  weeklyTargetMinutes: weeklyTargetMinutes,
  holidays: _holidays, // ❌ Missing personal red days
);
```

#### 3. **Absence/VAB Integration** ✅
**Location:** `lib/providers/time_provider.dart` (lines 189-192)
- **Status:** IMPLEMENTED
- **Features:**
  - `paidAbsenceMinutesForDate()` called for each day
  - Credit minutes added to variance calculation
  - Monthly/yearly credit tracking
- **Potential Issues:**
  - May not handle all absence types correctly
  - VAB might need special handling

#### 4. **Daily Target Computation** ✅
**Location:** `lib/utils/target_hours_calculator.dart`
- **Status:** FULLY IMPLEMENTED
- **Features:**
  - `scheduledMinutesForDate()` calculates per-day targets
  - Deterministic distribution (no drift)
  - Weekday-aware (Mon-Fri default)
  - Holiday-aware (returns 0 for red days)
- **Working Correctly:** ✅

#### 5. **Month/Year Rollups with Calendar Logic** ✅
**Location:** `lib/providers/time_provider.dart` (lines 160-229)
- **Status:** FULLY IMPLEMENTED
- **Features:**
  - Day-by-day iteration through each month
  - Proper calendar month boundaries
  - Year-to-date calculations
  - Month-to-date calculations
- **Working Correctly:** ✅

#### 6. **Unpaid Break Handling** ✅
**Location:** `lib/models/entry.dart` (Shift class)
- **Status:** IMPLEMENTED
- **Features:**
  - `Shift.workedMinutes` subtracts `unpaidBreakMinutes` from span
  - `Entry.totalWorkDuration` uses `shift.workedMinutes`
  - `Entry.totalDuration` uses `totalWorkDuration` for work entries
- **Working Correctly:** ✅

---

## ❌ **MISSING OR BROKEN**

### 1. **Personal Red Days Not Integrated** ❌
**Problem:** Only auto holidays (Swedish public holidays) are considered, not user-defined personal red days.

**Current Code:**
```dart
// time_provider.dart:178
final scheduled = TargetHoursCalculator.scheduledMinutesForDate(
  date: date,
  weeklyTargetMinutes: weeklyTargetMinutes,
  holidays: _holidays, // Only auto holidays
);
```

**Fix Required:**
- Integrate `HolidayService` into `TimeProvider`
- Check both auto holidays AND personal red days
- Use `scheduledMinutesWithRedDayInfo()` for half-day support

### 2. **Time Balance Engine Not Auto-Refreshing** ❌
**Problem:** `calculateBalances()` may not be called automatically when entries change.

**Fix Required:**
- Add listener to `EntryProvider` in `TimeProvider`
- Auto-calculate when entries are added/updated/deleted
- Debounce calculations to avoid performance issues

### 3. **Red Day Half-Day Logic Not Used** ❌
**Problem:** `TargetHoursCalculator.scheduledMinutesWithRedDayInfo()` exists but is never called.

**Current:** Only full red days (0 minutes) are handled.

**Fix Required:**
- Check `HolidayService.getRedDayInfo()` for half-day status
- Use `scheduledMinutesWithRedDayInfo()` when half-day detected

### 4. **Absence Provider Integration May Be Incomplete** ⚠️
**Problem:** `_absenceProvider` is optional and may be null.

**Current Code:**
```dart
final credit = _absenceProvider?.paidAbsenceMinutesForDate(date, scheduled) ?? 0;
```

**Fix Required:**
- Ensure `AbsenceProvider` is always provided to `TimeProvider`
- Verify all absence types (VAB, sick leave, vacation) are handled correctly

---

## 🔧 **RECOMMENDED FIXES**

### Priority 1: Critical (Core Value Prop)

1. **Integrate Personal Red Days**
   - Add `HolidayService` to `TimeProvider`
   - Use `getRedDayInfo()` to check for personal red days
   - Apply half-day logic when needed

2. **Auto-Refresh Time Balance**
   - Listen to `EntryProvider` changes
   - Auto-calculate on entry CRUD operations
   - Add debouncing for performance

### Priority 2: Important (Accuracy)

3. **Verify Absence Integration**
   - Ensure all absence types are counted
   - Check VAB special handling if needed
   - Verify credit minutes calculation

4. **Add Error Handling**
   - Better error messages
   - Validation of calculations
   - Debug mode for troubleshooting

### Priority 3: Enhancement (Polish)

5. **Performance Optimization**
   - Cache calculations
   - Incremental updates
   - Background calculation

6. **Testing**
   - Unit tests for edge cases
   - Integration tests for full flows
   - Validation against known scenarios

---

## 📋 **IMPLEMENTATION CHECKLIST**

- [ ] Add `HolidayService` to `TimeProvider` constructor
- [ ] Integrate personal red day checking in `calculateBalances()`
- [ ] Use `scheduledMinutesWithRedDayInfo()` for half-day support
- [ ] Add `EntryProvider` listener for auto-refresh
- [ ] Ensure `AbsenceProvider` is always provided
- [ ] Add comprehensive error handling
- [ ] Add unit tests for red day calculations
- [ ] Add integration tests for full balance calculation
- [ ] Verify unpaid breaks are used everywhere
- [ ] Add debug logging for troubleshooting

---

## 📝 **CODE LOCATIONS**

| Feature | File | Line Range |
|---------|------|------------|
| Time Balance Engine | `lib/providers/time_provider.dart` | 86-360 |
| Target Calculator | `lib/utils/target_hours_calculator.dart` | 124-326 |
| Red Day Service | `lib/services/holiday_service.dart` | 1-256 |
| Unpaid Breaks | `lib/models/entry.dart` | 164-170 |
| Absence Integration | `lib/providers/time_provider.dart` | 189-192 |

---

## 🎯 **SUMMARY**

**What Works:**
- ✅ Core calculation engine
- ✅ Daily target computation
- ✅ Month/year rollups
- ✅ Unpaid break handling
- ✅ Auto holiday integration
- ✅ Absence credit minutes (if provider available)

**What's Missing:**
- ❌ Personal red day integration
- ❌ Half-day red day support in calculations
- ❌ Auto-refresh on entry changes
- ❌ Comprehensive error handling

**Critical Gap:** Personal red days are the main missing piece. The infrastructure exists (`HolidayService`), but it's not connected to the time balance calculations.
