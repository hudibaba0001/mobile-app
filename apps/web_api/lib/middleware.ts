import { NextRequest, NextResponse } from 'next/server';
import { verifyToken, supabaseAdmin } from './supabase';
import { adminRateLimit } from './rate-limit';

export async function withAuth(
  request: NextRequest,
  handler: (request: NextRequest, userId: string) => Promise<NextResponse>
) {
  const authHeader = request.headers.get('authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return NextResponse.json(
      { error: 'Missing or invalid authorization header' },
      { status: 401 }
    );
  }

  const token = authHeader.substring(7);
  const user = await verifyToken(token);

  if (!user) {
    return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
  }

  return handler(request, user.id);
}

export async function withAdminAuth(
  request: NextRequest,
  handler: (request: NextRequest, userId: string) => Promise<NextResponse>
) {
  // Apply rate limiting first
  const rateLimitResponse = await adminRateLimit(request);
  if (rateLimitResponse) {
    return rateLimitResponse;
  }

  // Check Authorization header first, then fall back to httpOnly cookie
  const authHeader = request.headers.get('authorization');
  const cookieToken = request.cookies.get('admin_access_token')?.value;
  let token: string | undefined;

  if (authHeader?.startsWith('Bearer ')) {
    token = authHeader.substring(7);
  } else if (cookieToken) {
    token = cookieToken;
  }

  if (!token) {
    return NextResponse.json(
      { error: 'Missing or invalid authorization' },
      { status: 401 }
    );
  }
  const user = await verifyToken(token);

  if (!user) {
    return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
  }

  // Check if user is admin by querying the profiles table
  const { data: profile, error } = await supabaseAdmin
    .from('profiles')
    .select('is_admin')
    .eq('id', user.id)
    .single();

  if (error || !profile) {
    console.error('Error fetching user profile:', error);
    return NextResponse.json(
      { error: 'Failed to verify admin status' },
      { status: 500 }
    );
  }

  if (!profile.is_admin) {
    return NextResponse.json(
      { error: 'Forbidden: Admin access required' },
      { status: 403 }
    );
  }

  return handler(request, user.id);
}
