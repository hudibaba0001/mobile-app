'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export default function AccountPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [checkingSession, setCheckingSession] = useState(true)

  useEffect(() => {
    // Check if user already has a session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        setIsLoggedIn(true)
        setEmail(session.user.email || '')
      }
      setCheckingSession(false)
    })
  }, [])

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (signInError) {
        throw new Error(signInError.message)
      }

      setIsLoggedIn(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed')
    } finally {
      setLoading(false)
    }
  }

  const handleManageSubscription = async () => {
    setError(null)
    setLoading(true)

    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        setIsLoggedIn(false)
        throw new Error('Session expired. Please sign in again.')
      }

      const response = await fetch('/api/billing/portal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session.access_token}`,
        },
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Something went wrong')
      }

      if (data.url) {
        window.location.href = data.url
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  if (checkingSession) {
    return (
      <div className="container">
        <div className="card">
          <p>Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="container">
      <div className="card">
        <h1 className="title">Manage Subscription</h1>

        {error && <div className="error-box">{error}</div>}

        {!isLoggedIn ? (
          <>
            <p className="subtitle">Sign in to access billing settings</p>
            <form onSubmit={handleSignIn}>
              <div className="form-group">
                <label className="label" htmlFor="email">Email</label>
                <input
                  id="email"
                  type="email"
                  className="input"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  placeholder="you@example.com"
                />
              </div>

              <div className="form-group">
                <label className="label" htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  className="input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  placeholder="Your password"
                />
              </div>

              <button type="submit" className="button" disabled={loading}>
                {loading ? 'Please wait...' : 'Sign In'}
              </button>
            </form>
          </>
        ) : (
          <>
            <p className="subtitle">Signed in as {email}</p>
            <button
              className="button"
              onClick={handleManageSubscription}
              disabled={loading}
            >
              {loading ? 'Please wait...' : 'Manage Subscription'}
            </button>
            <button
              className="link"
              onClick={async () => {
                await supabase.auth.signOut()
                setIsLoggedIn(false)
                setPassword('')
              }}
              style={{ marginTop: '1rem', background: 'none', border: 'none', cursor: 'pointer' }}
            >
              Sign Out
            </button>
          </>
        )}

        <Link href="/" className="link">
          Back to Home
        </Link>
      </div>
    </div>
  )
}
