'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import './signup.css'

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
    color: '#ddd',
    isValid: false,
  })

  // Password strength validation
  const validatePasswordStrength = (password: string): PasswordStrength => {
    if (!password) {
      return { score: 0, feedback: '', color: '#ddd', isValid: false }
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
    let color = '#ddd'
    let isValid = false

    if (score === 0) {
      feedback = ''
    } else if (score <= 2) {
      feedback = 'Weak password'
      color = '#dc2626'
    } else if (score <= 4) {
      feedback = 'Moderate password'
      color = '#f59e0b'
    } else if (score <= 5) {
      feedback = 'Good password'
      color = '#eab308'
    } else {
      feedback = 'Strong password'
      color = '#10b981'
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
    <div className="signup-page">
      <div className="signup-container">
        {/* Header */}
        <div className="signup-header">
          <div className="brand-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <circle cx="12" cy="12" r="10" strokeWidth="2"/>
              <path d="M12 6v6l4 2" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </div>
          <h1 className="signup-title">Welcome to KvikTime</h1>
          <p className="signup-subtitle">Create your account and start your 7-day free trial</p>
        </div>

        {/* Card */}
        <div className="signup-card">
          {/* Price Badge */}
          <div className="price-badge-top">
            <div className="price-badge-label">7 days free, then</div>
            <div className="price-badge-amount">89 kr/month</div>
            <div className="price-badge-info">including VAT • Cancel anytime</div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="signup-form">
            {error && (
              <div className="error-box">
                <svg className="error-icon" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <span>{error}</span>
              </div>
            )}

            <div className="name-row">
              <div className="form-group">
                <label className="label" htmlFor="firstName">
                  First Name <span className="required">*</span>
                </label>
                <input
                  id="firstName"
                  type="text"
                  className="input"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  required
                  placeholder="John"
                />
              </div>

              <div className="form-group">
                <label className="label" htmlFor="lastName">
                  Last Name <span className="required">*</span>
                </label>
                <input
                  id="lastName"
                  type="text"
                  className="input"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  required
                  placeholder="Doe"
                />
              </div>
            </div>

            <div className="form-group">
              <label className="label" htmlFor="email">
                Email Address <span className="required">*</span>
              </label>
              <input
                id="email"
                type="email"
                className="input"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
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
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                placeholder="+46 70 123 4567"
              />
            </div>

            <div className="form-group">
              <label className="label" htmlFor="password">
                Password <span className="required">*</span>
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
                <div className="password-strength">
                  <div className="strength-header">
                    <span className="strength-label">Password strength:</span>
                    <span className="strength-feedback" style={{ color: passwordStrength.color }}>
                      {passwordStrength.feedback}
                    </span>
                  </div>
                  <div className="strength-bar">
                    <div
                      className="strength-bar-fill"
                      style={{
                        width: `${(passwordStrength.score / 6) * 100}%`,
                        backgroundColor: passwordStrength.color
                      }}
                    />
                  </div>
                </div>
              )}

              {/* Password requirements */}
              <div className="password-requirements">
                <div className="requirements-title">Password requirements:</div>
                <PasswordRequirement
                  met={formData.password.length >= 12}
                  text="At least 12 characters"
                />
                <PasswordRequirement
                  met={/[A-Z]/.test(formData.password)}
                  text="One uppercase letter (A-Z)"
                />
                <PasswordRequirement
                  met={/[a-z]/.test(formData.password)}
                  text="One lowercase letter (a-z)"
                />
                <PasswordRequirement
                  met={/[0-9]/.test(formData.password)}
                  text="One number (0-9)"
                />
                <PasswordRequirement
                  met={/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(formData.password)}
                  text="One special character (!@#$%^&*)"
                />
              </div>
            </div>

            <div className="checkbox-group">
              <input
                type="checkbox"
                id="terms"
                className="checkbox"
                checked={formData.termsAccepted}
                onChange={(e) => setFormData({ ...formData, termsAccepted: e.target.checked })}
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
                onChange={(e) => setFormData({ ...formData, privacyAccepted: e.target.checked })}
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
              {loading ? (
                <span className="button-loading">
                  <span className="spinner"></span>
                  Processing...
                </span>
              ) : (
                'Start Free Trial →'
              )}
            </button>

            <div className="security-badge">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" strokeWidth="2"/>
                <path d="M7 11V7a5 5 0 0110 0v4" strokeWidth="2"/>
              </svg>
              Secure SSL encrypted payment
            </div>
          </form>
        </div>

        {/* Footer */}
        <div className="signup-footer">
          Already have an account?{' '}
          <Link href="/" className="signin-link">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  )
}

// Password requirement component
function PasswordRequirement({ met, text }: { met: boolean; text: string }) {
  return (
    <div className={`requirement-item ${met ? 'met' : ''}`}>
      <div className="requirement-icon">
        {met ? (
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M5 13l4 4L19 7" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        ) : (
          <div className="requirement-circle" />
        )}
      </div>
      <span className="requirement-text">{text}</span>
    </div>
  )
}
