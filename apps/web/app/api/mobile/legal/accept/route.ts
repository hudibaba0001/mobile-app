import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { createServiceRoleClient } from '@/lib/supabase-server'
import { fetchCurrentLegalSnapshots } from '@/lib/legal-proof'
import { PRIVACY_VERSION, TERMS_VERSION } from '@/lib/validation'

function getEnv(name: string): string {
  const value = process.env[name]
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value.trim()
}

async function getAuthenticatedUser(request: NextRequest) {
  const authHeader = request.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return null
  }

  const token = authHeader.replace('Bearer ', '')
  const supabaseAuth = createClient(
    getEnv('NEXT_PUBLIC_SUPABASE_URL'),
    getEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
  )

  const {
    data: { user },
    error,
  } = await supabaseAuth.auth.getUser(token)

  if (error || !user) {
    return null
  }

  return user
}

function getRequestIp(request: NextRequest): string {
  return (
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    request.headers.get('x-real-ip') ||
    'unknown'
  )
}

export async function POST(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser(request)
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const legalSnapshots = await fetchCurrentLegalSnapshots({
      termsFallbackVersion: TERMS_VERSION,
      privacyFallbackVersion: PRIVACY_VERSION,
    })

    const nowIso = new Date().toISOString()
    const ipAddress = getRequestIp(request)
    const userAgent = request.headers.get('user-agent') || 'unknown'

    const supabase = createServiceRoleClient()

    const { error: legalAuditError } = await supabase.from('terms_acceptance').insert({
      user_id: user.id,
      email: user.email ?? '',
      terms_version: legalSnapshots.terms.version,
      privacy_version: legalSnapshots.privacy.version,
      terms_content: legalSnapshots.terms.content,
      privacy_content: legalSnapshots.privacy.content,
      ip_address: ipAddress,
      user_agent: userAgent,
      accepted_at: nowIso,
    })

    if (legalAuditError) {
      return NextResponse.json(
        { error: `Failed to store legal proof: ${legalAuditError.message}` },
        { status: 500 },
      )
    }

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .upsert(
        {
          id: user.id,
          email: user.email ?? null,
          terms_accepted_at: nowIso,
          privacy_accepted_at: nowIso,
          terms_version: legalSnapshots.terms.version,
          privacy_version: legalSnapshots.privacy.version,
          updated_at: nowIso,
        },
        { onConflict: 'id' },
      )
      .select()
      .maybeSingle()

    if (profileError) {
      return NextResponse.json(
        { error: `Failed to update profile legal status: ${profileError.message}` },
        { status: 500 },
      )
    }

    return NextResponse.json({
      ok: true,
      termsVersion: legalSnapshots.terms.version,
      privacyVersion: legalSnapshots.privacy.version,
      profile,
    })
  } catch (error) {
    console.error('Accept legal error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal error' },
      { status: 500 },
    )
  }
}
