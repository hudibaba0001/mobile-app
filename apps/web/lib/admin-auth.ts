import { createClient } from '@supabase/supabase-js'
import { createServiceRoleClient } from './supabase-server'

/**
 * Verify the Authorization header and check if the user is an admin.
 * Returns the user ID on success, or a Response object on failure.
 */
export async function verifyAdmin(
  request: Request
): Promise<{ userId: string } | Response> {
  const authHeader = request.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const token = authHeader.slice(7)

  const supabaseAuth = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  const {
    data: { user },
    error,
  } = await supabaseAuth.auth.getUser(token)

  if (error || !user) {
    return Response.json({ error: 'Invalid token' }, { status: 401 })
  }

  const supabase = createServiceRoleClient()
  const { data: profile } = await supabase
    .from('profiles')
    .select('is_admin')
    .eq('id', user.id)
    .single()

  if (!profile?.is_admin) {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  return { userId: user.id }
}
