import { NextRequest, NextResponse } from 'next/server';
import { withAdminAuth } from '@/lib/middleware';
import { supabaseAdmin } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';

// GET /api/admin/legal - List all legal documents
export async function GET(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const type = _req.nextUrl.searchParams.get('type'); // 'terms' or 'privacy'

    let query = supabaseAdmin
      .from('legal_documents')
      .select('*')
      .order('created_at', { ascending: false });

    if (type) {
      query = query.eq('type', type);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error fetching legal documents:', error);
      return NextResponse.json(
        { error: 'Failed to fetch legal documents' },
        { status: 500 }
      );
    }

    return NextResponse.json({ documents: data || [] });
  });
}

// POST /api/admin/legal - Create a new legal document
export async function POST(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const body = await _req.json();
    const { type, title, content, version, is_current } = body;

    if (!type || !title || !content) {
      return NextResponse.json(
        { error: 'type, title, and content are required' },
        { status: 400 }
      );
    }

    if (!['terms', 'privacy'].includes(type)) {
      return NextResponse.json(
        { error: 'type must be "terms" or "privacy"' },
        { status: 400 }
      );
    }

    // If setting as current, unset all others of same type first
    if (is_current) {
      await supabaseAdmin
        .from('legal_documents')
        .update({ is_current: false })
        .eq('type', type)
        .eq('is_current', true);
    }

    const { data, error } = await supabaseAdmin
      .from('legal_documents')
      .insert({
        type,
        title,
        content,
        version: version || '1.0',
        is_current: is_current || false,
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating legal document:', error);
      return NextResponse.json(
        { error: 'Failed to create legal document' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'create_legal_document',
      resourceType: 'legal_document',
      resourceId: data.id,
      details: { type, title, is_current },
    }, _req);

    return NextResponse.json({ document: data }, { status: 201 });
  });
}

// PUT /api/admin/legal - Update a legal document
export async function PUT(request: NextRequest) {
  return withAdminAuth(request, async (_req, userId) => {
    const body = await _req.json();
    const { id, title, content, version, is_current } = body;

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    // Get the document to know its type
    const { data: existing } = await supabaseAdmin
      .from('legal_documents')
      .select('type')
      .eq('id', id)
      .single();

    if (!existing) {
      return NextResponse.json(
        { error: 'Document not found' },
        { status: 404 }
      );
    }

    // If setting as current, unset all others of same type first
    if (is_current) {
      await supabaseAdmin
        .from('legal_documents')
        .update({ is_current: false })
        .eq('type', existing.type)
        .eq('is_current', true);
    }

    const updateData: Record<string, unknown> = {};
    if (title !== undefined) updateData.title = title;
    if (content !== undefined) updateData.content = content;
    if (version !== undefined) updateData.version = version;
    if (is_current !== undefined) updateData.is_current = is_current;

    const { data, error } = await supabaseAdmin
      .from('legal_documents')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error updating legal document:', error);
      return NextResponse.json(
        { error: 'Failed to update legal document' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'update_legal_document',
      resourceType: 'legal_document',
      resourceId: id,
      details: { is_current },
    }, _req);

    return NextResponse.json({ document: data });
  });
}

// DELETE /api/admin/legal - Delete a legal document
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
      .from('legal_documents')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting legal document:', error);
      return NextResponse.json(
        { error: 'Failed to delete legal document' },
        { status: 500 }
      );
    }

    await logAdminAction(userId, {
      action: 'delete_legal_document',
      resourceType: 'legal_document',
      resourceId: id,
    }, _req);

    return NextResponse.json({ success: true });
  });
}
