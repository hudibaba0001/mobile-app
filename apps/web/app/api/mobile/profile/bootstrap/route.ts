import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { createServiceRoleClient } from '@/lib/supabase-server'

interface BootstrapBody {
  firstName?: string
  lastName?: string
}

function getEnv(name: string): string {
  const value = process.env[name]
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value.trim()
}

export async function POST(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const accessToken = authHeader.replace('Bearer ', '')
    const supabaseAuth = createClient(
      getEnv('NEXT_PUBLIC_SUPABASE_URL'),
      getEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
    )

    const {
      data: { user },
      error: authError,
    } = await supabaseAuth.auth.getUser(accessToken)

    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = (await request.json().catch(() => ({}))) as BootstrapBody
    const firstName = body.firstName?.trim()
    const lastName = body.lastName?.trim()
    const nowIso = new Date().toISOString()

    const supabase = createServiceRoleClient()

    const profilePayload: Record<string, unknown> = {
      id: user.id,
      email: user.email ?? null,
      entitlement_status: 'pending_subscription',
      updated_at: nowIso,
      created_at: nowIso,
    }

    if (firstName) profilePayload.first_name = firstName
    if (lastName) profilePayload.last_name = lastName

    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(profilePayload, { onConflict: 'id' })

    if (profileError) {
      return NextResponse.json(
        { error: `Failed to create profile: ${profileError.message}` },
        { status: 500 },
      )
    }

    const { error: entitlementError } = await supabase
      .from('user_entitlements')
      .upsert(
        {
          user_id: user.id,
          provider: 'google_play',
          status: 'pending_subscription',
          updated_at: nowIso,
          created_at: nowIso,
        },
        {
          onConflict: 'user_id',
          ignoreDuplicates: true,
        },
      )

    if (entitlementError) {
      return NextResponse.json(
        {
          error: `Failed to bootstrap entitlement row: ${entitlementError.message}`,
        },
        { status: 500 },
      )
    }

    const { data: entitlement } = await supabase
      .from('user_entitlements')
      .select('status, current_period_end, product_id')
      .eq('user_id', user.id)
      .maybeSingle()

    return NextResponse.json({
      ok: true,
      userId: user.id,
      entitlement: entitlement ?? null,
    })
  } catch (error) {
    console.error('Profile bootstrap error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal error' },
      { status: 500 },
    )
  }
}
