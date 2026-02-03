import { supabaseAdmin } from './supabase';

export interface UserBalances {
  balanceToday: number;      // Current day's net minutes
  monthNet: number;          // Current month variance in minutes
  yearNet: number;           // Yearly running balance in minutes
  openingBalance: number;    // From opening_flex_minutes
}

interface ContractSettings {
  full_time_hours: number | null;
  contract_percent: number | null;
  opening_flex_minutes: number | null;
  tracking_start_date: string | null;
}

/**
 * Calculate user balances for a given year and month.
 * Simplified version for Sprint 1 - excludes holidays, absences, and red days.
 *
 * @param userId - User ID to calculate balances for
 * @param year - Year to calculate (default: current year)
 * @param month - Month to calculate (1-12, default: current month)
 * @returns UserBalances object or null if tracking not configured
 */
export async function calculateUserBalances(
  userId: string,
  year: number = new Date().getFullYear(),
  month: number = new Date().getMonth() + 1
): Promise<UserBalances | null> {
  try {
    // Get user's contract settings
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('full_time_hours, contract_percent, opening_flex_minutes, tracking_start_date')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      console.error('Error fetching profile for balance calculation:', profileError);
      return null;
    }

    const contract = profile as ContractSettings;

    // Validate tracking is configured
    if (!contract.tracking_start_date) {
      return null; // Can't calculate without tracking start date
    }

    // Calculate weekly target minutes
    const fullTimeHours = contract.full_time_hours || 40;
    const contractPercent = contract.contract_percent || 100;
    const weeklyTargetMinutes = (fullTimeHours * 60) * (contractPercent / 100);

    // Calculate monthly target (Mon-Fri weekdays only)
    const monthlyTargetMinutes = calculateMonthlyTarget(year, month, weeklyTargetMinutes);

    // Get actual worked minutes for the month
    const actualWorkedMinutes = await getActualWorkedMinutes(userId, year, month);

    // Calculate month variance
    const monthNet = actualWorkedMinutes - monthlyTargetMinutes;

    // Calculate yearly balance
    const yearNet = await calculateYearlyBalance(userId, year, contract.opening_flex_minutes || 0);

    // Calculate today's balance (simplified - same as current month net for Sprint 1)
    const balanceToday = monthNet;

    return {
      balanceToday,
      monthNet,
      yearNet,
      openingBalance: contract.opening_flex_minutes || 0,
    };
  } catch (error) {
    console.error('Error calculating balances:', error);
    return null;
  }
}

/**
 * Calculate monthly target based on weekdays (Mon-Fri) in the month.
 * Distributes weekly target across work weekdays.
 */
function calculateMonthlyTarget(year: number, month: number, weeklyTargetMinutes: number): number {
  const weekdayCount = countWeekdaysInMonth(year, month);
  return Math.round((weeklyTargetMinutes * weekdayCount) / 5);
}

/**
 * Count weekdays (Monday-Friday) in a given month.
 */
function countWeekdaysInMonth(year: number, month: number): number {
  const daysInMonth = new Date(year, month, 0).getDate();
  let weekdayCount = 0;

  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day);
    const dayOfWeek = date.getDay();
    // 1-5 are Monday-Friday
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      weekdayCount++;
    }
  }

  return weekdayCount;
}

/**
 * Get actual worked minutes for a specific month.
 * Aggregates time from work_shifts (end_time - start_time - unpaid_break_minutes).
 */
async function getActualWorkedMinutes(userId: string, year: number, month: number): Promise<number> {
  // Get date range for the month
  const startDate = new Date(year, month - 1, 1).toISOString().split('T')[0];
  const endDate = new Date(year, month, 0).toISOString().split('T')[0];

  // Query entries for this user and month
  const { data: entries, error: entriesError } = await supabaseAdmin
    .from('entries')
    .select('id, type')
    .eq('user_id', userId)
    .eq('type', 'work') // Only work entries for Sprint 1
    .gte('date', startDate)
    .lte('date', endDate);

  if (entriesError || !entries || entries.length === 0) {
    return 0;
  }

  const entryIds = entries.map(e => e.id);

  // Query work_shifts for these entries
  const { data: shifts, error: shiftsError } = await supabaseAdmin
    .from('work_shifts')
    .select('start_time, end_time, unpaid_break_minutes')
    .in('entry_id', entryIds);

  if (shiftsError || !shifts) {
    return 0;
  }

  // Calculate total worked minutes
  let totalMinutes = 0;
  for (const shift of shifts) {
    const start = new Date(shift.start_time);
    const end = new Date(shift.end_time);
    const durationMinutes = (end.getTime() - start.getTime()) / (1000 * 60);
    const unpaidBreak = shift.unpaid_break_minutes || 0;
    const workedMinutes = Math.max(0, durationMinutes - unpaidBreak);
    totalMinutes += workedMinutes;
  }

  return Math.round(totalMinutes);
}

/**
 * Calculate yearly balance including opening balance and all monthly variances.
 * Simplified for Sprint 1 - calculates all months up to current month.
 */
async function calculateYearlyBalance(userId: string, year: number, openingFlexMinutes: number): Promise<number> {
  const currentMonth = new Date().getMonth() + 1;
  const currentYear = new Date().getFullYear();

  // Only calculate up to current month if it's the current year
  const lastMonth = (year === currentYear) ? currentMonth : 12;

  let yearlyVariance = 0;

  // Get contract settings (we need this for target calculations)
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('full_time_hours, contract_percent')
    .eq('id', userId)
    .single();

  if (!profile) {
    return openingFlexMinutes;
  }

  const fullTimeHours = profile.full_time_hours || 40;
  const contractPercent = profile.contract_percent || 100;
  const weeklyTargetMinutes = (fullTimeHours * 60) * (contractPercent / 100);

  // Calculate variance for each month
  for (let month = 1; month <= lastMonth; month++) {
    const monthlyTarget = calculateMonthlyTarget(year, month, weeklyTargetMinutes);
    const actualWorked = await getActualWorkedMinutes(userId, year, month);
    const monthVariance = actualWorked - monthlyTarget;
    yearlyVariance += monthVariance;
  }

  // Get balance adjustments for the year
  const adjustments = await getBalanceAdjustments(userId, year);

  return openingFlexMinutes + yearlyVariance + adjustments;
}

/**
 * Get sum of balance adjustments for a given year.
 */
async function getBalanceAdjustments(userId: string, year: number): Promise<number> {
  const startDate = `${year}-01-01`;
  const endDate = `${year}-12-31`;

  const { data, error } = await supabaseAdmin
    .from('balance_adjustments')
    .select('delta_minutes')
    .eq('user_id', userId)
    .gte('effective_date', startDate)
    .lte('effective_date', endDate);

  if (error || !data) {
    return 0;
  }

  return data.reduce((sum, adj) => sum + (adj.delta_minutes || 0), 0);
}
