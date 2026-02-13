'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export default function ResetPasswordPage() {
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  const [ready, setReady] = useState(false)
  const [expired, setExpired] = useState(false)

  useEffect(() => {
    let cancelled = false

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event) => {
        if (event === 'PASSWORD_RECOVERY' && !cancelled) {
          setReady(true)
        }
      }
    )

    async function handleToken() {
      const params = new URLSearchParams(window.location.search)
      const errorParam = params.get('error')
      const tokenHash = params.get('token_hash')
      const type = params.get('type')

      if (errorParam && !cancelled) {
        setExpired(true)
        return
      }

      // Fallback for links that land directly on this page with token_hash.
      if (tokenHash && type === 'recovery') {
        const { error } = await supabase.auth.verifyOtp({
          token_hash: tokenHash,
          type: 'recovery',
        })

        if (!error && !cancelled) {
          setReady(true)
          return
        }
      }

      // Check for implicit hash fragment flow: #access_token=...&type=recovery
      const hash = window.location.hash
      if (hash && hash.includes('access_token')) {
        // Supabase client auto-detects hash tokens, give it time to process
        for (let i = 0; i < 10; i++) {
          await new Promise(r => setTimeout(r, 500))
          const { data: { session } } = await supabase.auth.getSession()
          if (session && !cancelled) {
            setReady(true)
            return
          }
        }
      }

      // Final check: session may already exist
      const { data: { session } } = await supabase.auth.getSession()
      if (session && !cancelled) {
        setReady(true)
        return
      }

      // No token found or exchange failed
      if (!cancelled) {
        setExpired(true)
      }
    }

    handleToken()

    return () => {
      cancelled = true
      subscription.unsubscribe()
    }
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (password.length < 8) {
      setError('Password must be at least 8 characters.')
      return
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.')
      return
    }

    setLoading(true)

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password,
      })

      if (updateError) {
        throw new Error(updateError.message)
      }

      setSuccess(true)
      await supabase.auth.signOut()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update password.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="container">
        <div className="card">
          <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
            <div style={{ fontSize: '3rem' }}>&#10003;</div>
          </div>
          <h1 className="title">Password Updated</h1>
          <p className="subtitle">
            Your password has been changed successfully. You can now sign in with your new password in the KvikTime app.
          </p>
        </div>
      </div>
    )
  }

  if (expired) {
    return (
      <div className="container">
        <div className="card">
          <h1 className="title">Link Expired</h1>
          <p className="subtitle">
            This password reset link has expired or is invalid. Please request a new one from the KvikTime app.
          </p>
          <Link href="/" className="link">
            Back to Home
          </Link>
        </div>
      </div>
    )
  }

  if (!ready) {
    return (
      <div className="container">
        <div className="card">
          <p style={{ textAlign: 'center' }}>Verifying reset link...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="container">
      <div className="card">
        <h1 className="title">Reset Password</h1>
        <p className="subtitle">Enter your new password below.</p>

        {error && <div className="error-box">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="label" htmlFor="password">New Password</label>
            <input
              id="password"
              type="password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              placeholder="At least 8 characters"
              autoFocus
            />
          </div>

          <div className="form-group">
            <label className="label" htmlFor="confirm-password">Confirm Password</label>
            <input
              id="confirm-password"
              type="password"
              className="input"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              minLength={8}
              placeholder="Enter password again"
            />
          </div>

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Updating...' : 'Update Password'}
          </button>
        </form>

        <Link href="/" className="link">
          Back to Home
        </Link>
      </div>
    </div>
  )
}
