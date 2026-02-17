'use client'

import { useState } from 'react'
import Link from 'next/link'
import { createClient, SupabaseClient } from '@supabase/supabase-js'

let _supabase: SupabaseClient | null = null
function getSupabase() {
  if (!_supabase) {
    _supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )
  }
  return _supabase
}

export default function RecoverPage() {
  const [verifying, setVerifying] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleVerify() {
    const params = new URLSearchParams(window.location.search)
    const tokenHash = params.get('token_hash')
    const type = params.get('type')

    if (!tokenHash || type !== 'recovery') {
      setError('Invalid or missing recovery link parameters.')
      return
    }

    setVerifying(true)
    setError(null)

    try {
      const supabase = getSupabase()
      const { error: otpError } = await supabase.auth.verifyOtp({
        token_hash: tokenHash,
        type: 'recovery',
      })

      if (otpError) {
        setError(
          'This link has expired or has already been used. Please request a new password reset from the app.'
        )
        return
      }

      // OTP verified — session is established. Redirect to reset-password page.
      window.location.href = '/reset-password'
    } catch {
      setError('Something went wrong. Please try again.')
    } finally {
      setVerifying(false)
    }
  }

  return (
    <div className="container" style={{ paddingTop: '80px' }}>
      <div className="card" style={{ textAlign: 'center' }}>
        <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>&#128274;</div>
        <h1 className="title">Password Reset</h1>
        <p className="subtitle">
          Click the button below to verify your identity and set a new password.
        </p>

        {error && <div className="error-box">{error}</div>}

        <button
          className="button"
          onClick={handleVerify}
          disabled={verifying}
          style={{ marginBottom: '1rem' }}
        >
          {verifying ? 'Verifying...' : 'Reset My Password'}
        </button>

        <Link href="/" className="link">
          Back to Home
        </Link>
      </div>
    </div>
  )
}
