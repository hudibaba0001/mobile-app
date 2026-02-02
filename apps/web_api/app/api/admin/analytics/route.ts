import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (req, adminUserId) => {
    try {
      const { searchParams } = new URL(request.url);
      const startDate = searchParams.get('start_date');
      const endDate = searchParams.get('end_date');

      // Get user count
      const { count: userCount, error: userError } = await supabaseAdmin
        .from('user_profiles')
        .select('*', { count: 'exact', head: true });

      if (userError) {
        console.error('Error fetching user count:', userError);
        return NextResponse.json(
          { error: 'Failed to fetch analytics' },
          { status: 500 }
        );
      }

      // Get entry count for date range
      let entryQuery = supabaseAdmin
        .from('travel_time_entries')
        .select('*', { count: 'exact', head: true });

      if (startDate) {
        entryQuery = entryQuery.gte('date', startDate);
      }
      if (endDate) {
        entryQuery = entryQuery.lte('date', endDate);
      }

      const { count: entryCount, error: entryError } = await entryQuery;

      if (entryError) {
        console.error('Error fetching entry count:', entryError);
        return NextResponse.json(
          { error: 'Failed to fetch analytics' },
          { status: 500 }
        );
      }

      // Get active users (users with entries in the last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const { data: activeUsers, error: activeError } = await supabaseAdmin
        .from('travel_time_entries')
        .select('user_id')
        .gte('date', thirtyDaysAgo.toISOString().split('T')[0])
        .limit(1000);

      if (activeError) {
        console.error('Error fetching active users:', activeError);
        return NextResponse.json(
          { error: 'Failed to fetch analytics' },
          { status: 500 }
        );
      }

      const activeUserCount = new Set(activeUsers?.map((e) => e.user_id)).size;

      return NextResponse.json({
        totalUsers: userCount,
        totalEntries: entryCount,
        activeUsersLast30Days: activeUserCount,
        dateRange: {
          start: startDate,
          end: endDate,
        },
      });
    } catch (error) {
      console.error('Unexpected error:', error);
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    }
  });
}
