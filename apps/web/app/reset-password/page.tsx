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
    // Supabase automatically picks up the token from the URL fragment
    // when the page loads. We listen for the PASSWORD_RECOVERY event.
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event) => {
        if (event === 'PASSWORD_RECOVERY') {
          setReady(true)
        }
      }
    )

    // Also check if we already have a session (page reload after token exchange)
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        setReady(true)
      } else {
        // Give Supabase a moment to process the URL fragment
        setTimeout(() => {
          supabase.auth.getSession().then(({ data: { session: s } }) => {
            if (s) {
              setReady(true)
            } else {
              setExpired(true)
            }
          })
        }, 2000)
      }
    })

    return () => subscription.unsubscribe()
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
