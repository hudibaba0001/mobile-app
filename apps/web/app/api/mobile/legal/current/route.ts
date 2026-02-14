import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { fetchCurrentLegalSnapshots, PRIVACY_URL, TERMS_URL } from '@/lib/legal-proof'
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

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthenticatedUser(request)
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const legalSnapshots = await fetchCurrentLegalSnapshots({
      termsFallbackVersion: TERMS_VERSION,
      privacyFallbackVersion: PRIVACY_VERSION,
    })

    return NextResponse.json({
      termsVersion: legalSnapshots.terms.version,
      privacyVersion: legalSnapshots.privacy.version,
      termsModifiedAt: legalSnapshots.terms.modifiedAt,
      privacyModifiedAt: legalSnapshots.privacy.modifiedAt,
      termsUrl: TERMS_URL,
      privacyUrl: PRIVACY_URL,
    })
  } catch (error) {
    console.error('Fetch legal versions error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal error' },
      { status: 500 },
    )
  }
}
