'use client'

import { useState } from 'react'

export default function AccountPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleManageSubscription = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const response = await fetch('/api/billing/portal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
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

  return (
    <div className="container">
      <div className="card">
        <h1 className="title">Manage Subscription</h1>
        <p className="subtitle">Enter your email to access billing settings</p>

        {error && <div className="error-box">{error}</div>}

        <form onSubmit={handleManageSubscription}>
          <div className="form-group">
            <label className="label" htmlFor="email">
              Email
            </label>
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

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Please wait...' : 'Manage Subscription'}
          </button>
        </form>

        <a href="/" className="link">
          Back to Home
        </a>
      </div>
    </div>
  )
}
