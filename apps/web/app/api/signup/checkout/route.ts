import { NextRequest, NextResponse } from 'next/server'
import { createServiceRoleClient } from '@/lib/supabase-server'
import { stripe } from '@/lib/stripe'
import { signupSchema, TERMS_VERSION, PRIVACY_VERSION } from '@/lib/validation'
import { fetchCurrentLegalSnapshots } from '@/lib/legal-proof'

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

    const legalSnapshots = await fetchCurrentLegalSnapshots({
      termsFallbackVersion: TERMS_VERSION,
      privacyFallbackVersion: PRIVACY_VERSION,
    })

    // Create profile with consent timestamps
    const { error: profileError } = await supabase.from('profiles').upsert({
      id: userId,
      email,
      first_name: firstName,
      last_name: lastName,
      phone: phone || null,
      terms_accepted_at: now,
      privacy_accepted_at: now,
      terms_version: legalSnapshots.terms.version,
      privacy_version: legalSnapshots.privacy.version,
      subscription_status: 'pending',
      created_at: now,
      updated_at: now,
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

    // Log terms acceptance as immutable audit record with full content snapshot
    const { error: legalAuditError } = await supabase.from('terms_acceptance').insert({
      user_id: userId,
      email,
      terms_version: legalSnapshots.terms.version,
      privacy_version: legalSnapshots.privacy.version,
      terms_content: legalSnapshots.terms.content,
      privacy_content: legalSnapshots.privacy.content,
      ip_address: ipAddress,
      user_agent: userAgent,
    })

    if (legalAuditError) {
      console.error('Legal audit error:', legalAuditError)
      // Clean up: delete auth user if legal proof cannot be persisted
      await supabase.auth.admin.deleteUser(userId)
      return NextResponse.json(
        { error: 'Failed to store legal acceptance proof' },
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
        terms_version: legalSnapshots.terms.version,
        privacy_version: legalSnapshots.privacy.version,
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
