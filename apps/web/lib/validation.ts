import { z } from 'zod'

export const signupSchema = z.object({
  firstName: z.string().min(1, 'First name is required').max(50, 'First name is too long'),
  lastName: z.string().min(1, 'Last name is required').max(50, 'Last name is too long'),
  email: z.string().email('Invalid email address'),
  phone: z.string().max(20, 'Phone number is too long').optional().or(z.literal('')),
  password: z.string().min(8, 'Password must be at least 8 characters'),
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
