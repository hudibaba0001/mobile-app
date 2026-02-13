import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { JWT } from 'google-auth-library'
import { createServiceRoleClient } from '@/lib/supabase-server'

export const runtime = 'nodejs'

type EntitlementStatus =
  | 'pending_subscription'
  | 'active'
  | 'grace'
  | 'on_hold'
  | 'canceled'
  | 'expired'

interface GoogleSubscriptionV2LineItem {
  productId?: string
  expiryTime?: string
}

interface GoogleSubscriptionV2Response {
  subscriptionState?: string
  lineItems?: GoogleSubscriptionV2LineItem[]
}

interface VerifyRequestBody {
  purchaseToken?: string
  productId?: string
}

const ANDROID_PUBLISHER_SCOPE =
  'https://www.googleapis.com/auth/androidpublisher'

function getEnv(name: string): string {
  const value = process.env[name]
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`)
  }
  return value.trim()
}

function parseAllowedProducts(): Set<string> {
  const raw = getEnv('GOOGLE_PLAY_ALLOWED_PRODUCT_IDS')
  return new Set(raw.split(',').map((item) => item.trim()).filter(Boolean))
}

function mapGoogleStateToEntitlementStatus(
  subscriptionState: string | undefined,
): EntitlementStatus {
  switch (subscriptionState) {
    case 'SUBSCRIPTION_STATE_ACTIVE':
      return 'active'
    case 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD':
      return 'grace'
    case 'SUBSCRIPTION_STATE_ON_HOLD':
      return 'on_hold'
    case 'SUBSCRIPTION_STATE_CANCELED':
      return 'canceled'
    case 'SUBSCRIPTION_STATE_EXPIRED':
      return 'expired'
    default:
      return 'pending_subscription'
  }
}

function getLatestPeriodEnd(
  lineItems: GoogleSubscriptionV2LineItem[] | undefined,
): string | null {
  if (!lineItems || lineItems.length === 0) return null
  const validExpiryTimes = lineItems
    .map((item) => item.expiryTime)
    .filter((value): value is string => Boolean(value))
    .map((value) => new Date(value))
    .filter((date) => !Number.isNaN(date.getTime()))

  if (validExpiryTimes.length === 0) return null

  validExpiryTimes.sort((a, b) => b.getTime() - a.getTime())
  return validExpiryTimes[0].toISOString()
}

function getVerifiedProductId(
  response: GoogleSubscriptionV2Response,
): string | null {
  const lineItems = response.lineItems ?? []
  for (const lineItem of lineItems) {
    if (lineItem.productId && lineItem.productId.trim()) {
      return lineItem.productId.trim()
    }
  }
  return null
}

async function getAuthenticatedUser(request: NextRequest) {
  const authHeader = request.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return null
  }

  const token = authHeader.replace('Bearer ', '')
  const supabaseAuth = createClient(
    getEnv('NEXT_PUBLIC_SUPABASE_URL'),
    getEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
  )

  const {
    data: { user },
    error,
  } = await supabaseAuth.auth.getUser(token)

  if (error || !user) {
    return null
  }

  return { user, accessToken: token }
}

async function fetchGoogleSubscription(
  purchaseToken: string,
): Promise<GoogleSubscriptionV2Response> {
  const packageName = getEnv('GOOGLE_PLAY_PACKAGE_NAME')
  const serviceAccountRaw = getEnv('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON')
  const serviceAccount = JSON.parse(serviceAccountRaw) as {
    client_email?: string
    private_key?: string
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error('Invalid GOOGLE_PLAY_SERVICE_ACCOUNT_JSON')
  }

  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key.replace(/\\n/g, '\n'),
    scopes: [ANDROID_PUBLISHER_SCOPE],
  })

  const accessTokenResponse = await jwtClient.getAccessToken()
  const accessToken =
    typeof accessTokenResponse === 'string'
      ? accessTokenResponse
      : accessTokenResponse?.token

  if (!accessToken) {
    throw new Error('Unable to acquire Google API access token')
  }

  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    cache: 'no-store',
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(
      `Google verification failed (${response.status}): ${errorText}`,
    )
  }

  return (await response.json()) as GoogleSubscriptionV2Response
}

export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthenticatedUser(request)
    if (!auth) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = (await request.json()) as VerifyRequestBody
    const purchaseToken = body.purchaseToken?.trim() ?? ''
    const clientProductId = body.productId?.trim() ?? ''

    if (!purchaseToken || !clientProductId) {
      return NextResponse.json(
        { error: 'purchaseToken and productId are required' },
        { status: 400 },
      )
    }

    const googleResponse = await fetchGoogleSubscription(purchaseToken)
    const verifiedProductId = getVerifiedProductId(googleResponse)

    if (!verifiedProductId) {
      return NextResponse.json(
        { error: 'Google response did not include productId' },
        { status: 400 },
      )
    }

    if (clientProductId != verifiedProductId) {
      return NextResponse.json(
        { error: 'Product mismatch' },
        { status: 400 },
      )
    }

    const allowedProducts = parseAllowedProducts()
    if (!allowedProducts.has(verifiedProductId)) {
      return NextResponse.json(
        { error: 'Product is not allowed for this app' },
        { status: 403 },
      )
    }

    const status = mapGoogleStateToEntitlementStatus(
      googleResponse.subscriptionState,
    )
    const currentPeriodEnd = getLatestPeriodEnd(googleResponse.lineItems)
    const nowIso = new Date().toISOString()

    const supabase = createServiceRoleClient()

    const entitlementPayload = {
      user_id: auth.user.id,
      provider: 'google_play',
      product_id: verifiedProductId,
      purchase_token: purchaseToken,
      status,
      current_period_end: currentPeriodEnd,
      raw_subscription_state: googleResponse.subscriptionState ?? null,
      updated_at: nowIso,
    }

    const { error: entitlementError } = await supabase
      .from('user_entitlements')
      .upsert(entitlementPayload, { onConflict: 'user_id' })

    if (entitlementError) {
      return NextResponse.json(
        { error: `Failed to persist entitlement: ${entitlementError.message}` },
        { status: 500 },
      )
    }

    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(
        {
          id: auth.user.id,
          email: auth.user.email ?? null,
          entitlement_status: status,
          updated_at: nowIso,
        },
        { onConflict: 'id' },
      )

    if (profileError) {
      return NextResponse.json(
        { error: `Failed to persist profile status: ${profileError.message}` },
        { status: 500 },
      )
    }

    return NextResponse.json({
      ok: true,
      status,
      productId: verifiedProductId,
      currentPeriodEnd,
    })
  } catch (error) {
    console.error('Google billing verify error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal error' },
      { status: 500 },
    )
  }
}
