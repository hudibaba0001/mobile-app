import { NextRequest, NextResponse } from 'next/server'
import { createClient, type EmailOtpType } from '@supabase/supabase-js'

const DEFAULT_RESET_PATH = '/reset-password'
const RECOVERY_TYPE: EmailOtpType = 'recovery'

function resolveSafeRedirectPath(rawNext: string | null, origin: string): string {
  if (!rawNext) return DEFAULT_RESET_PATH

  try {
    const parsed = new URL(rawNext, origin)

    if (parsed.origin !== origin) {
      return DEFAULT_RESET_PATH
    }

    return `${parsed.pathname}${parsed.search}`
  } catch {
    return DEFAULT_RESET_PATH
  }
}

function buildFailureUrl(origin: string, redirectPath: string): URL {
  const failureUrl = new URL(redirectPath, origin)
  failureUrl.searchParams.set('error', 'invalid_or_expired_link')
  return failureUrl
}

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url)
  const tokenHash = requestUrl.searchParams.get('token_hash')
  const type = requestUrl.searchParams.get('type')
  const redirectPath = resolveSafeRedirectPath(
    requestUrl.searchParams.get('next'),
    requestUrl.origin,
  )
  const failureUrl = buildFailureUrl(requestUrl.origin, redirectPath)

  if (!tokenHash || type !== RECOVERY_TYPE) {
    return NextResponse.redirect(failureUrl)
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  )

  const { data, error } = await supabase.auth.verifyOtp({
    token_hash: tokenHash,
    type: RECOVERY_TYPE,
  })

  if (error || !data.session?.access_token || !data.session.refresh_token) {
    if (error) {
      console.error('Password recovery verifyOtp failed:', error.message)
    }
    return NextResponse.redirect(failureUrl)
  }

  const successUrl = new URL(redirectPath, requestUrl.origin)
  const hashParams = new URLSearchParams({
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: String(data.session.expires_in),
    token_type: data.session.token_type,
    type: RECOVERY_TYPE,
  })

  if (data.session.expires_at) {
    hashParams.set('expires_at', String(data.session.expires_at))
  }

  successUrl.hash = hashParams.toString()

  return NextResponse.redirect(successUrl)
}
