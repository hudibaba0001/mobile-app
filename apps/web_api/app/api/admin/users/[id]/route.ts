import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { calculateUserBalances } from '@/lib/balance-calculator';

// UUID validation regex
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  return withAdminAuth(request, async (req, adminUserId) => {
    try {
      const { id: userId } = await params;

      // Validate UUID format
      if (!UUID_REGEX.test(userId)) {
        return NextResponse.json(
          { error: 'Invalid user ID format' },
          { status: 400 }
        );
      }

      // Get user profile
      const { data: profile, error: profileError } = await supabaseAdmin
        .from('profiles')
        .select('id, email, first_name, last_name, created_at, full_time_hours, contract_percent, tracking_start_date, opening_flex_minutes')
        .eq('id', userId)
        .single();

      if (profileError || !profile) {
        return NextResponse.json(
          { error: 'User not found' },
          { status: 404 }
        );
      }

      // Calculate balances
      const now = new Date();
      const balances = await calculateUserBalances(userId, now.getFullYear(), now.getMonth() + 1);

      // Count data records
      const [entriesCount, absencesCount, adjustmentsCount, redDaysCount] = await Promise.all([
        supabaseAdmin.from('entries').select('id', { count: 'exact', head: true }).eq('user_id', userId),
        supabaseAdmin.from('absences').select('id', { count: 'exact', head: true }).eq('user_id', userId),
        supabaseAdmin.from('balance_adjustments').select('id', { count: 'exact', head: true }).eq('user_id', userId),
        supabaseAdmin.from('user_red_days').select('id', { count: 'exact', head: true }).eq('user_id', userId),
      ]);

      // Log action
      await logAdminAction(adminUserId, {
        action: 'view_user_detail',
        resourceType: 'user',
        resourceId: userId,
      }, request);

      return NextResponse.json({
        profile: {
          id: profile.id,
          email: profile.email,
          first_name: profile.first_name,
          last_name: profile.last_name,
          created_at: profile.created_at,
        },
        contract: {
          full_time_hours: profile.full_time_hours,
          contract_percent: profile.contract_percent,
          tracking_start_date: profile.tracking_start_date,
          opening_flex_minutes: profile.opening_flex_minutes,
        },
        balances,
        counts: {
          entries: entriesCount.count || 0,
          absences: absencesCount.count || 0,
          adjustments: adjustmentsCount.count || 0,
          redDays: redDaysCount.count || 0,
        },
      });
    } catch (error) {
      console.error('Unexpected error in user detail:', error);
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    }
  });
}
