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
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-indigo-600 to-purple-600 mb-4">
            <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            Welcome to KvikTime
          </h1>
          <p className="text-lg text-gray-600">
            Create your account and start your 7-day free trial
          </p>
        </div>

        {/* Main Card */}
        <div className="bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden">
          {/* Price Badge */}
          <div className="bg-gradient-to-r from-indigo-600 to-purple-600 text-white px-6 py-4 text-center">
            <p className="text-sm font-medium opacity-90">7 days free, then</p>
            <p className="text-2xl font-bold">89 kr/month</p>
            <p className="text-sm opacity-90">including VAT • Cancel anytime</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-8 space-y-6">
            {error && (
              <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <div className="ml-3">
                    <p className="text-sm text-red-700 font-medium">{error}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Name Fields */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div>
                <label htmlFor="firstName" className="block text-sm font-semibold text-gray-700 mb-2">
                  First Name <span className="text-red-500">*</span>
                </label>
                <input
                  id="firstName"
                  type="text"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition duration-200 text-gray-900 placeholder-gray-400"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  required
                  placeholder="John"
                />
              </div>

              <div>
                <label htmlFor="lastName" className="block text-sm font-semibold text-gray-700 mb-2">
                  Last Name <span className="text-red-500">*</span>
                </label>
                <input
                  id="lastName"
                  type="text"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition duration-200 text-gray-900 placeholder-gray-400"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  required
                  placeholder="Doe"
                />
              </div>
            </div>

            {/* Email */}
            <div>
              <label htmlFor="email" className="block text-sm font-semibold text-gray-700 mb-2">
                Email Address <span className="text-red-500">*</span>
              </label>
              <input
                id="email"
                type="email"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition duration-200 text-gray-900 placeholder-gray-400"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
                placeholder="you@example.com"
              />
            </div>

            {/* Phone */}
            <div>
              <label htmlFor="phone" className="block text-sm font-semibold text-gray-700 mb-2">
                Phone Number <span className="text-gray-400 text-xs font-normal">(optional)</span>
              </label>
              <input
                id="phone"
                type="tel"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition duration-200 text-gray-900 placeholder-gray-400"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                placeholder="+46 70 123 4567"
              />
            </div>

            {/* Password */}
            <div>
              <label htmlFor="password" className="block text-sm font-semibold text-gray-700 mb-2">
                Password <span className="text-red-500">*</span>
              </label>
              <input
                id="password"
                type="password"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition duration-200 text-gray-900 placeholder-gray-400"
                value={formData.password}
                onChange={(e) => handlePasswordChange(e.target.value)}
                required
                placeholder="Create a strong password"
              />

              {/* Password strength indicator */}
              {formData.password && (
                <div className="mt-3 bg-gray-50 rounded-lg p-4 border border-gray-200">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium text-gray-700">
                      Password strength:
                    </span>
                    <span className={`text-sm font-semibold ${
                      passwordStrength.color === 'bg-green-500' ? 'text-green-600' :
                      passwordStrength.color === 'bg-yellow-500' ? 'text-yellow-600' :
                      passwordStrength.color === 'bg-orange-500' ? 'text-orange-600' :
                      passwordStrength.color === 'bg-red-500' ? 'text-red-600' :
                      'text-gray-600'
                    }`}>
                      {passwordStrength.feedback}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-300 ${passwordStrength.color}`}
                      style={{ width: `${(passwordStrength.score / 6) * 100}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Password requirements checklist */}
              <div className="mt-4 bg-gray-50 rounded-lg p-4 border border-gray-200">
                <p className="text-sm font-semibold text-gray-700 mb-3">
                  Password requirements:
                </p>
                <div className="space-y-2">
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
            </div>

            {/* Terms and Privacy */}
            <div className="space-y-3 pt-2">
              <label className="flex items-start">
                <input
                  type="checkbox"
                  id="terms"
                  className="mt-1 h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded cursor-pointer"
                  checked={formData.termsAccepted}
                  onChange={(e) => setFormData({ ...formData, termsAccepted: e.target.checked })}
                  required
                />
                <span className="ml-3 text-sm text-gray-600">
                  I agree to the{' '}
                  <a href="/terms" target="_blank" rel="noopener noreferrer" className="text-indigo-600 hover:text-indigo-500 font-medium underline">
                    Terms of Service
                  </a>
                </span>
              </label>

              <label className="flex items-start">
                <input
                  type="checkbox"
                  id="privacy"
                  className="mt-1 h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded cursor-pointer"
                  checked={formData.privacyAccepted}
                  onChange={(e) => setFormData({ ...formData, privacyAccepted: e.target.checked })}
                  required
                />
                <span className="ml-3 text-sm text-gray-600">
                  I agree to the{' '}
                  <a href="/privacy" target="_blank" rel="noopener noreferrer" className="text-indigo-600 hover:text-indigo-500 font-medium underline">
                    Privacy Policy
                  </a>
                </span>
              </label>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white font-semibold py-4 px-6 rounded-lg hover:from-indigo-700 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing...
                </span>
              ) : (
                'Start Free Trial →'
              )}
            </button>

            {/* Security Badge */}
            <div className="flex items-center justify-center text-xs text-gray-500 pt-2">
              <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              Secure SSL encrypted payment
            </div>
          </form>
        </div>

        {/* Footer */}
        <div className="text-center mt-6">
          <p className="text-sm text-gray-600">
            Already have an account?{' '}
            <a href="/" className="text-indigo-600 hover:text-indigo-500 font-semibold">
              Sign in
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}

// Password requirement item component
function PasswordRequirement({ met, text }: { met: boolean; text: string }) {
  return (
    <div className="flex items-center gap-2.5">
      {met ? (
        <div className="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 flex items-center justify-center">
          <svg className="w-3 h-3 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
          </svg>
        </div>
      ) : (
        <div className="flex-shrink-0 w-5 h-5 rounded-full border-2 border-gray-300" />
      )}
      <span className={`text-sm ${met ? 'text-green-700 font-medium' : 'text-gray-600'}`}>
        {text}
      </span>
    </div>
  )
}
