import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';

// GET /api/admin/messages - List all app messages
export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (_req) => {
    const { data, error } = await supabaseAdmin
      .from('app_messages')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching app messages:', error);
      return NextResponse.json(
        { error: 'Failed to fetch app messages' },
        { status: 500 }
      );
    }

    return NextResponse.json({ messages: data || [] });
  });
}

// POST /api/admin/messages - Create a new app message
export async function POST(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const body = await _req.json();
    const {
      title,
      body: messageBody,
      type,
      is_active,
      starts_at,
      expires_at,
      min_app_version,
      max_app_version,
      action_url,
      action_label,
      is_dismissible,
    } = body;

    if (!title || !messageBody) {
      return NextResponse.json(
        { error: 'title and body are required' },
        { status: 400 }
      );
    }

    const { data, error } = await supabaseAdmin
      .from('app_messages')
      .insert({
        title,
        body: messageBody,
        type: type || 'info',
        is_active: is_active ?? true,
        starts_at: starts_at || new Date().toISOString(),
        expires_at: expires_at || null,
        min_app_version: min_app_version || null,
        max_app_version: max_app_version || null,
        action_url: action_url || null,
        action_label: action_label || null,
        is_dismissible: is_dismissible ?? true,
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating app message:', error);
      return NextResponse.json(
        { error: 'Failed to create app message' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'create_app_message',
      resourceType: 'app_message',
      resourceId: data.id,
      details: { title, type },
    }, _req);

    return NextResponse.json({ message: data }, { status: 201 });
  });
}

// PUT /api/admin/messages - Update an app message
export async function PUT(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const body = await _req.json();
    const { id, ...updates } = body;

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    // Rename 'body' field if present to avoid conflict with request body
    const updateData: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(updates)) {
      if (key === 'messageBody') {
        updateData.body = value;
      } else {
        updateData[key] = value;
      }
    }

    const { data, error } = await supabaseAdmin
      .from('app_messages')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error updating app message:', error);
      return NextResponse.json(
        { error: 'Failed to update app message' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'update_app_message',
      resourceType: 'app_message',
      resourceId: id,
      details: { fields: Object.keys(updates) },
    }, _req);

    return NextResponse.json({ message: data });
  });
}

// DELETE /api/admin/messages - Delete an app message
export async function DELETE(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const id = _req.nextUrl.searchParams.get('id');

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    const { error } = await supabaseAdmin
      .from('app_messages')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting app message:', error);
      return NextResponse.json(
        { error: 'Failed to delete app message' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'delete_app_message',
      resourceType: 'app_message',
      resourceId: id,
    }, _req);

    return NextResponse.json({ success: true });
  });
}
