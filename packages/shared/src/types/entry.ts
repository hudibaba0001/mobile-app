/**
 * Travel time entry from travel_time_entries table
 */
export interface TravelTimeEntry {
  id: string;
  user_id: string;
  date: string;
  start_time: string | null;
  end_time: string | null;
  location: string | null;
  hours: number | null;
  notes: string | null;
  is_absence: boolean;
  absence_type: string | null;
  created_at: string;
  updated_at: string | null;
}

/**
 * Leave entry from leave_entries table
 */
export interface LeaveEntry {
  id: string;
  user_id: string;
  start_date: string;
  end_date: string;
  leave_type: string;
  status: 'pending' | 'approved' | 'rejected';
  notes: string | null;
  created_at: string;
  updated_at: string | null;
}

/**
 * Contract settings for a user
 */
export interface ContractSettings {
  id: string;
  user_id: string;
  target_hours_per_week: number;
  target_hours_per_day: number;
  start_date: string;
  end_date: string | null;
  created_at: string;
  updated_at: string | null;
}
