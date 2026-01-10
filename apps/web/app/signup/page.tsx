'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function SignupPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    termsAccepted: false,
    privacyAccepted: false,
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const response = await fetch('/api/signup/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Something went wrong')
      }

      // Redirect to Stripe Checkout
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
        <h1 className="title">Create Account</h1>
        <p className="subtitle">Start your 7-day free trial</p>

        {error && <div className="error-box">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="label" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              className="input"
              value={formData.email}
              onChange={(e) =>
                setFormData({ ...formData, email: e.target.value })
              }
              required
              placeholder="you@example.com"
            />
          </div>

          <div className="form-group">
            <label className="label" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              type="password"
              className="input"
              value={formData.password}
              onChange={(e) =>
                setFormData({ ...formData, password: e.target.value })
              }
              required
              minLength={8}
              placeholder="Minimum 8 characters"
            />
          </div>

          <div className="price-badge">
            <strong>59 kr/mån</strong> inkl. moms — 7 dagar gratis
          </div>

          <div className="checkbox-group">
            <input
              type="checkbox"
              id="terms"
              className="checkbox"
              checked={formData.termsAccepted}
              onChange={(e) =>
                setFormData({ ...formData, termsAccepted: e.target.checked })
              }
              required
            />
            <label className="checkbox-label" htmlFor="terms">
              I agree to the{' '}
              <a href="/terms" target="_blank" rel="noopener noreferrer">
                Terms of Service
              </a>
            </label>
          </div>

          <div className="checkbox-group">
            <input
              type="checkbox"
              id="privacy"
              className="checkbox"
              checked={formData.privacyAccepted}
              onChange={(e) =>
                setFormData({ ...formData, privacyAccepted: e.target.checked })
              }
              required
            />
            <label className="checkbox-label" htmlFor="privacy">
              I agree to the{' '}
              <a href="/privacy" target="_blank" rel="noopener noreferrer">
                Privacy Policy
              </a>
            </label>
          </div>

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Please wait...' : 'Continue to payment'}
          </button>
        </form>

        <a href="/" className="link">
          Already have an account? Open the app
        </a>
      </div>
    </div>
  )
}
