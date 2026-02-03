import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';

// UUID validation regex
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (req, adminUserId) => {
    try {
      // Parse query parameter
      const { searchParams } = new URL(request.url);
      const query = searchParams.get('q');

      // Validate query
      if (!query || query.trim().length === 0) {
        return NextResponse.json(
          { error: 'Query required' },
          { status: 400 }
        );
      }

      const trimmedQuery = query.trim();

      if (trimmedQuery.length < 2) {
        return NextResponse.json(
          { error: 'Query too short (min 2 characters)' },
          { status: 400 }
        );
      }

      if (trimmedQuery.length > 100) {
        return NextResponse.json(
          { error: 'Query too long (max 100 characters)' },
          { status: 400 }
        );
      }

      // Build search query
      let searchQuery = supabaseAdmin
        .from('profiles')
        .select('id, email, first_name, last_name, created_at')
        .limit(100); // Limit results to prevent large responses

      // Check if query is a valid UUID (exact user ID search)
      if (UUID_REGEX.test(trimmedQuery)) {
        searchQuery = searchQuery.eq('id', trimmedQuery);
      } else {
        // Search by email (case-insensitive)
        searchQuery = searchQuery.ilike('email', `%${trimmedQuery}%`);
      }

      const { data: users, error } = await searchQuery.order('created_at', { ascending: false });

      if (error) {
        console.error('Error searching users:', error);
        return NextResponse.json(
          { error: 'Failed to search users' },
          { status: 500 }
        );
      }

      // Log search action
      await logAdminAction(adminUserId, {
        action: 'search_users',
        resourceType: 'user',
        details: { query: trimmedQuery, resultCount: users?.length || 0 },
      }, request);

      return NextResponse.json({ users: users || [] });
    } catch (error) {
      console.error('Unexpected error in user search:', error);
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    }
  });
}
