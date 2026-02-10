import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';

export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (req, adminUserId) => {
    try {
      const { searchParams } = new URL(request.url);
      const startDate = searchParams.get('start_date');
      const endDate = searchParams.get('end_date');

      // Get user count
      const { count: userCount, error: userError } = await supabaseAdmin
        .from('profiles')
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
        .from('entries')
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

      // Get active users (distinct users with entries in the last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const thirtyDaysAgoStr = thirtyDaysAgo.toISOString().split('T')[0];

      // Use a raw RPC or paginate to avoid row cap issues
      // Fetch all user_ids (no limit) to get accurate distinct count
      let allUserIds: string[] = [];
      let offset = 0;
      const pageSize = 1000;
      let hasMore = true;

      while (hasMore) {
        const { data: batch, error: activeError } = await supabaseAdmin
          .from('entries')
          .select('user_id')
          .gte('date', thirtyDaysAgoStr)
          .range(offset, offset + pageSize - 1);

        if (activeError) {
          console.error('Error fetching active users:', activeError);
          return NextResponse.json(
            { error: 'Failed to fetch analytics' },
            { status: 500 }
          );
        }

        if (batch && batch.length > 0) {
          allUserIds = allUserIds.concat(batch.map((e) => e.user_id));
          offset += pageSize;
          hasMore = batch.length === pageSize;
        } else {
          hasMore = false;
        }
      }

      const activeUserCount = new Set(allUserIds).size;

      // Log admin action
      await logAdminAction(adminUserId, {
        action: 'view_analytics',
        resourceType: 'analytics',
        details: { startDate, endDate },
      }, request);

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
