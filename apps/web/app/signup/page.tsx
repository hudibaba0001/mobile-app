'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

interface PasswordStrength {
  score: number
  feedback: string
  color: string
  isValid: boolean
}

export default function SignupPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    password: '',
    termsAccepted: false,
    privacyAccepted: false,
  })
  const [passwordStrength, setPasswordStrength] = useState<PasswordStrength>({
    score: 0,
    feedback: '',
    color: 'bg-gray-300',
    isValid: false,
  })

  // Password strength validation
  const validatePasswordStrength = (password: string): PasswordStrength => {
    if (!password) {
      return { score: 0, feedback: '', color: 'bg-gray-300', isValid: false }
    }

    let score = 0
    const checks = {
      length: password.length >= 12,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /[0-9]/.test(password),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password),
    }

    // Score calculation
    if (checks.length) score += 2
    if (checks.uppercase) score += 1
    if (checks.lowercase) score += 1
    if (checks.number) score += 1
    if (checks.special) score += 1

    // Determine strength
    let feedback = ''
    let color = 'bg-gray-300'
    let isValid = false

    if (score === 0) {
      feedback = ''
    } else if (score <= 2) {
      feedback = 'Weak password'
      color = 'bg-red-500'
    } else if (score <= 4) {
      feedback = 'Moderate password'
      color = 'bg-orange-500'
    } else if (score <= 5) {
      feedback = 'Good password'
      color = 'bg-yellow-500'
    } else {
      feedback = 'Strong password'
      color = 'bg-green-500'
      isValid = true
    }

    // Password must meet all requirements to be valid
    isValid = Object.values(checks).every((check) => check === true)

    return { score, feedback, color, isValid }
  }

  const handlePasswordChange = (password: string) => {
    setFormData({ ...formData, password })
    setPasswordStrength(validatePasswordStrength(password))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    // Validate password strength
    if (!passwordStrength.isValid) {
      setError('Please create a stronger password that meets all requirements')
      return
    }

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
          <div className="name-row">
            <div className="form-group">
              <label className="label" htmlFor="firstName">
                First Name *
              </label>
              <input
                id="firstName"
                type="text"
                className="input"
                value={formData.firstName}
                onChange={(e) =>
                  setFormData({ ...formData, firstName: e.target.value })
                }
                required
                placeholder="John"
              />
            </div>

            <div className="form-group">
              <label className="label" htmlFor="lastName">
                Last Name *
              </label>
              <input
                id="lastName"
                type="text"
                className="input"
                value={formData.lastName}
                onChange={(e) =>
                  setFormData({ ...formData, lastName: e.target.value })
                }
                required
                placeholder="Doe"
              />
            </div>
          </div>

          <div className="form-group">
            <label className="label" htmlFor="email">
              Email *
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
            <label className="label" htmlFor="phone">
              Phone Number <span className="optional">(optional)</span>
            </label>
            <input
              id="phone"
              type="tel"
              className="input"
              value={formData.phone}
              onChange={(e) =>
                setFormData({ ...formData, phone: e.target.value })
              }
              placeholder="+46 70 123 4567"
            />
          </div>

          <div className="form-group">
            <label className="label" htmlFor="password">
              Password *
            </label>
            <input
              id="password"
              type="password"
              className="input"
              value={formData.password}
              onChange={(e) => handlePasswordChange(e.target.value)}
              required
              placeholder="Create a strong password"
            />

            {/* Password strength indicator */}
            {formData.password && (
              <div className="mt-2">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm text-gray-600">
                    Password strength:
                  </span>
                  <span className="text-sm font-semibold" style={{ color: passwordStrength.color.replace('bg-', '') }}>
                    {passwordStrength.feedback}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all duration-300 ${passwordStrength.color}`}
                    style={{ width: `${(passwordStrength.score / 6) * 100}%` }}
                  />
                </div>
              </div>
            )}

            {/* Password requirements checklist */}
            <div className="mt-3 space-y-1">
              <p className="text-sm font-medium text-gray-700 mb-2">
                Password must contain:
              </p>
              <PasswordRequirement
                met={formData.password.length >= 12}
                text="At least 12 characters"
              />
              <PasswordRequirement
                met={/[A-Z]/.test(formData.password)}
                text="At least one uppercase letter (A-Z)"
              />
              <PasswordRequirement
                met={/[a-z]/.test(formData.password)}
                text="At least one lowercase letter (a-z)"
              />
              <PasswordRequirement
                met={/[0-9]/.test(formData.password)}
                text="At least one number (0-9)"
              />
              <PasswordRequirement
                met={/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(formData.password)}
                text="At least one special character (!@#$%^&*)"
              />
            </div>
          </div>

          <div className="price-badge">
            <strong>89 kr/mån</strong> inkl. moms — 7 dagar gratis
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

// Password requirement item component
function PasswordRequirement({ met, text }: { met: boolean; text: string }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      {met ? (
        <svg
          className="w-4 h-4 text-green-500"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M5 13l4 4L19 7"
          />
        </svg>
      ) : (
        <svg
          className="w-4 h-4 text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <circle cx="12" cy="12" r="10" strokeWidth={2} />
        </svg>
      )}
      <span className={met ? 'text-green-700' : 'text-gray-600'}>{text}</span>
    </div>
  )
}
