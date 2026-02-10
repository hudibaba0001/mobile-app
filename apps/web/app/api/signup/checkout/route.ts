import { NextRequest, NextResponse } from 'next/server'
import { createServiceRoleClient } from '@/lib/supabase-server'
import { stripe } from '@/lib/stripe'
import { signupSchema, TERMS_VERSION, PRIVACY_VERSION } from '@/lib/validation'

const TERMS_URL = 'https://www.kviktime.se/terms-and-conditions/'
const PRIVACY_URL = 'https://www.kviktime.se/privacy-policy/'

/** Fetch page text content from a WordPress URL */
async function fetchPageContent(url: string): Promise<string> {
  try {
    const res = await fetch(url, { next: { revalidate: 0 } })
    if (!res.ok) return `[Failed to fetch: ${res.status}]`
    const html = await res.text()
    // Strip HTML tags to store plain text
    return html
      .replace(/<script[\s\S]*?<\/script>/gi, '')
      .replace(/<style[\s\S]*?<\/style>/gi, '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
  } catch (e) {
    return `[Fetch error: ${e}]`
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // Validate input
    const validationResult = signupSchema.safeParse(body)
    if (!validationResult.success) {
      const errors = validationResult.error.flatten().fieldErrors
      const firstError = Object.values(errors)[0]?.[0] || 'Validation failed'
      return NextResponse.json({ error: firstError }, { status: 400 })
    }

    const { firstName, lastName, email, phone, password } = validationResult.data
    const supabase = createServiceRoleClient()

    // Capture IP and user agent for terms acceptance proof
    const ipAddress = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
      || request.headers.get('x-real-ip')
      || 'unknown'
    const userAgent = request.headers.get('user-agent') || 'unknown'

    // Check if user already exists
    const { data: existingUsers } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', email)
      .limit(1)

    if (existingUsers && existingUsers.length > 0) {
      return NextResponse.json(
        { error: 'An account with this email already exists' },
        { status: 400 }
      )
    }

    // Create Supabase auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Skip email confirmation
    })

    if (authError || !authData.user) {
      console.error('Auth error:', authError)
      return NextResponse.json(
        { error: authError?.message || 'Failed to create account' },
        { status: 400 }
      )
    }

    const userId = authData.user.id
    const now = new Date().toISOString()

    // Create profile with consent timestamps
    const { error: profileError } = await supabase.from('profiles').upsert({
      id: userId,
      email,
      first_name: firstName,
      last_name: lastName,
      phone: phone || null,
      terms_accepted_at: now,
      privacy_accepted_at: now,
      terms_version: TERMS_VERSION,
      privacy_version: PRIVACY_VERSION,
      subscription_status: 'pending',
      created_at: now,
      updated_at: now,
    })

    // Fetch T&C and Privacy Policy content from WordPress for legal proof
    const [termsContent, privacyContent] = await Promise.all([
      fetchPageContent(TERMS_URL),
      fetchPageContent(PRIVACY_URL),
    ])

    // Log terms acceptance as immutable audit record with full content snapshot
    await supabase.from('terms_acceptance').insert({
      user_id: userId,
      email,
      terms_version: TERMS_VERSION,
      privacy_version: PRIVACY_VERSION,
      terms_content: termsContent,
      privacy_content: privacyContent,
      ip_address: ipAddress,
      user_agent: userAgent,
    })

    if (profileError) {
      console.error('Profile error:', profileError)
      // Clean up: delete the auth user if profile creation fails
      await supabase.auth.admin.deleteUser(userId)
      return NextResponse.json(
        { error: 'Failed to create profile' },
        { status: 500 }
      )
    }

    // Create Stripe customer
    const customer = await stripe.customers.create({
      email,
      name: `${firstName} ${lastName}`,
      phone: phone || undefined,
      metadata: {
        supabase_user_id: userId,
      },
    })

    // Update profile with Stripe customer ID
    await supabase.from('profiles').update({
      stripe_customer_id: customer.id,
      updated_at: new Date().toISOString(),
    }).eq('id', userId)

    // Create Stripe Checkout session
    const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'
    const priceId = process.env.STRIPE_PRICE_ID_MONTHLY

    // 89 SEK/month (8900 öre) - includes 25% VAT
    const lineItems = priceId
      ? [{ price: priceId, quantity: 1 }]
      : [
          {
            price_data: {
              currency: 'sek',
              product_data: {
                name: 'Travel Time App - Monthly',
                description: 'Full access to the Travel Time App',
              },
              unit_amount: 8900, // 89 SEK in öre
              recurring: { interval: 'month' as const },
            },
            quantity: 1,
          },
        ]

    const checkoutSession = await stripe.checkout.sessions.create({
      customer: customer.id,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: lineItems,
      subscription_data: {
        trial_period_days: 7,
        metadata: {
          supabase_user_id: userId,
        },
      },
      success_url: `${siteUrl}/signup/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${siteUrl}/signup/cancel`,
      client_reference_id: userId,
      metadata: {
        supabase_user_id: userId,
        terms_version: TERMS_VERSION,
        privacy_version: PRIVACY_VERSION,
      },
    })

    return NextResponse.json({ url: checkoutSession.url })
  } catch (error) {
    console.error('Checkout error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
