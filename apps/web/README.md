# Web Signup & Billing App

Next.js web application for user signup and Stripe billing management.

## Features

- User signup with Terms & Privacy acceptance
- Stripe Checkout integration with 7-day free trial
- Stripe webhook handling for subscription status
- Customer billing portal access
- Cross-client password reset flow for mobile users

## Setup

### 1. Install dependencies

```bash
cd apps/web
npm install
```

### 2. Configure environment

Copy `env.example` to `.env.local` and fill in your values:

```bash
cp env.example .env.local
```

Required environment variables:
- `NEXT_PUBLIC_SITE_URL` - Your production URL
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (server-only)
- `GOOGLE_PLAY_PACKAGE_NAME` - Android package name (for Play verify)
- `GOOGLE_PLAY_ALLOWED_PRODUCT_IDS` - Comma separated subscription product IDs
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` - Google service account JSON (escaped in env)
- `STRIPE_SECRET_KEY` - Stripe secret key
- `STRIPE_WEBHOOK_SECRET` - Stripe webhook signing secret
- `STRIPE_PRICE_ID_MONTHLY` - Stripe price ID for 59 SEK/month subscription

### 3. Run Supabase migration

Apply the profiles table migration:

```bash
# From project root
psql -h your-supabase-host -U postgres -d postgres -f supabase_migrations/002_profiles_subscription.sql
```

Or apply via Supabase dashboard SQL editor.

### 4. Configure Stripe

1. Create a product and price in Stripe Dashboard (59 SEK/month)
2. Set up webhook endpoint pointing to `/api/stripe/webhook`
3. Subscribe to events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`

### 5. Run development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

### 6. Configure password reset template (Supabase)

For mobile-initiated reset links, configure the Supabase **Reset Password** email template to use `token_hash` and this route:

```html
<a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=recovery&next={{ .RedirectTo }}">Reset Password</a>
```

Keep your Flutter `resetPasswordForEmail(..., redirectTo: 'https://app.kviktime.se/reset-password')` value in Supabase Redirect URLs.

## Pages

- `/` - Home/landing page
- `/signup` - User signup form
- `/signup/success` - Payment success confirmation
- `/signup/cancel` - Payment canceled
- `/account` - Manage subscription (access billing portal)
- `/auth/confirm` - Verifies reset `token_hash` and redirects with recovery session
- `/terms` - Terms of Service (placeholder)
- `/privacy` - Privacy Policy (placeholder)

## API Routes

- `POST /api/signup/checkout` - Create user and Stripe Checkout session
- `POST /api/stripe/webhook` - Handle Stripe webhook events
- `POST /api/billing/portal` - Create Stripe Customer Portal session
- `POST /api/mobile/profile/bootstrap` - Ensure profile + pending entitlement row
- `POST /api/billing/google/verify` - Verify Google Play purchase token and persist entitlement

## Deployment

Deploy to Vercel, Netlify, or any platform that supports Next.js:

```bash
npm run build
npm start
```

Remember to:
1. Set environment variables in production
2. Configure Stripe webhook endpoint for production URL
3. Update `NEXT_PUBLIC_SITE_URL` to production domain
