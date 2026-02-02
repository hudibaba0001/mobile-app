/**
 * System-wide analytics response
 */
export interface SystemAnalytics {
  totalUsers: number;
  totalEntries: number;
  activeUsersLast30Days: number;
  dateRange: {
    start: string | null;
    end: string | null;
  };
}

/**
 * User activity statistics
 */
export interface UserActivityStats {
  userId: string;
  userName: string;
  email: string;
  totalEntries: number;
  totalHours: number;
  lastActivityDate: string | null;
}

/**
 * Time entry trends data
 */
export interface EntryTrends {
  date: string;
  entryCount: number;
  totalHours: number;
}

/**
 * Location usage statistics
 */
export interface LocationStats {
  location: string;
  entryCount: number;
  totalHours: number;
  uniqueUsers: number;
}
