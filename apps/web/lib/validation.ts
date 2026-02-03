import { z } from 'zod'

// Strong password validation regex patterns
const PASSWORD_MIN_LENGTH = 12
const PASSWORD_PATTERNS = {
  uppercase: /[A-Z]/,
  lowercase: /[a-z]/,
  number: /[0-9]/,
  special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/,
}

export const signupSchema = z.object({
  firstName: z.string().min(1, 'First name is required').max(50, 'First name is too long'),
  lastName: z.string().min(1, 'Last name is required').max(50, 'Last name is too long'),
  email: z.string().email('Invalid email address'),
  phone: z.string().max(20, 'Phone number is too long').optional().or(z.literal('')),
  password: z
    .string()
    .min(PASSWORD_MIN_LENGTH, `Password must be at least ${PASSWORD_MIN_LENGTH} characters`)
    .regex(PASSWORD_PATTERNS.uppercase, 'Password must contain at least one uppercase letter')
    .regex(PASSWORD_PATTERNS.lowercase, 'Password must contain at least one lowercase letter')
    .regex(PASSWORD_PATTERNS.number, 'Password must contain at least one number')
    .regex(PASSWORD_PATTERNS.special, 'Password must contain at least one special character'),
  termsAccepted: z.literal(true, {
    errorMap: () => ({ message: 'You must accept the Terms of Service' }),
  }),
  privacyAccepted: z.literal(true, {
    errorMap: () => ({ message: 'You must accept the Privacy Policy' }),
  }),
})

export type SignupFormData = z.infer<typeof signupSchema>

// Current versions - update these when terms/privacy change
export const TERMS_VERSION = 'v1'
export const PRIVACY_VERSION = 'v1'
