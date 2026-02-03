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

      // Check if user exists
      const { data: profile, error: profileError } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (profileError || !profile) {
        return NextResponse.json(
          { error: 'User not found' },
          { status: 404 }
        );
      }

      // Check data size (prevent huge exports)
      const { count: entryCount, error: countError } = await supabaseAdmin
        .from('entries')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (countError) {
        console.error('Error counting entries:', countError);
        return NextResponse.json(
          { error: 'Failed to count user data' },
          { status: 500 }
        );
      }

      if (entryCount && entryCount > 10000) {
        return NextResponse.json(
          { error: 'User data too large for export. Contact support.' },
          { status: 413 }
        );
      }

      // Fetch all user data
      const [
        { data: entries },
        { data: workShifts },
        { data: travelSegments },
        { data: absences },
        { data: balanceAdjustments },
        { data: redDays },
      ] = await Promise.all([
        supabaseAdmin.from('entries').select('*').eq('user_id', userId).order('date', { ascending: false }),
        supabaseAdmin.from('work_shifts').select('*'),
        supabaseAdmin.from('travel_segments').select('*'),
        supabaseAdmin.from('absences').select('*').eq('user_id', userId).order('date', { ascending: false }),
        supabaseAdmin.from('balance_adjustments').select('*').eq('user_id', userId).order('effective_date', { ascending: false }),
        supabaseAdmin.from('user_red_days').select('*').eq('user_id', userId).order('date', { ascending: false }),
      ]);

      // Get entry IDs to filter shifts and travel segments
      const entryIds = entries?.map(e => e.id) || [];

      // Filter shifts and travel segments to only this user's entries
      const userWorkShifts = workShifts?.filter(s => entryIds.includes(s.entry_id)) || [];
      const userTravelSegments = travelSegments?.filter(t => entryIds.includes(t.entry_id)) || [];

      // Merge shifts into entries
      const entriesWithDetails = entries?.map(entry => {
        const shifts = userWorkShifts.filter(s => s.entry_id === entry.id);
        const travel = userTravelSegments.filter(t => t.entry_id === entry.id);
        return {
          ...entry,
          work_shifts: shifts,
          travel_segments: travel,
        };
      }) || [];

      // Calculate balances
      const now = new Date();
      const balances = await calculateUserBalances(userId, now.getFullYear(), now.getMonth() + 1);

      // Get date range
      const dates = entries?.map(e => e.date).filter(Boolean) || [];
      const earliest = dates.length > 0 ? dates[dates.length - 1] : null;
      const latest = dates.length > 0 ? dates[0] : null;

      // Build export object (exclude sensitive Stripe data)
      const exportData = {
        exportedAt: new Date().toISOString(),
        userId: profile.id,
        profile: {
          id: profile.id,
          email: profile.email,
          first_name: profile.first_name,
          last_name: profile.last_name,
          phone: profile.phone,
          created_at: profile.created_at,
          updated_at: profile.updated_at,
          // Exclude: stripe_customer_id, stripe_subscription_id, subscription_status
        },
        contract: {
          contract_percent: profile.contract_percent,
          full_time_hours: profile.full_time_hours,
          employer_mode: profile.employer_mode,
          tracking_start_date: profile.tracking_start_date,
          opening_flex_minutes: profile.opening_flex_minutes,
        },
        balances,
        data: {
          entries: entriesWithDetails,
          absences: absences || [],
          adjustments: balanceAdjustments || [],
          redDays: redDays || [],
        },
        metadata: {
          totalEntries: entries?.length || 0,
          totalAbsences: absences?.length || 0,
          totalAdjustments: balanceAdjustments?.length || 0,
          totalRedDays: redDays?.length || 0,
          dateRange: {
            earliest,
            latest,
          },
        },
      };

      // Calculate export size
      const exportSizeMB = (JSON.stringify(exportData).length / 1048576).toFixed(2);

      // Enhanced audit log
      await logAdminAction(adminUserId, {
        action: 'export_user_debug_bundle',
        resourceType: 'user',
        resourceId: userId,
        details: {
          entryCount: entries?.length || 0,
          exportSizeMB,
          dateRange: { earliest, latest },
        },
      }, request);

      // Sanitize filename (remove non-alphanumeric characters)
      const safeUserId = userId.replace(/[^a-zA-Z0-9-]/g, '');
      const timestamp = Date.now();
      const filename = `user-${safeUserId}-export-${timestamp}.json`;

      // Return JSON download
      return new NextResponse(JSON.stringify(exportData, null, 2), {
        headers: {
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="${filename}"`,
        },
      });
    } catch (error) {
      console.error('Unexpected error in export:', error);
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    }
  });
}
