# Web Signup & Billing App

Next.js web application for user signup and Stripe billing management.

## Features

- User signup with Terms & Privacy acceptance
- Stripe Checkout integration with 7-day free trial
- Stripe webhook handling for subscription status
- Customer billing portal access

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

## Pages

- `/` - Home/landing page
- `/signup` - User signup form
- `/signup/success` - Payment success confirmation
- `/signup/cancel` - Payment canceled
- `/account` - Manage subscription (access billing portal)
- `/terms` - Terms of Service (placeholder)
- `/privacy` - Privacy Policy (placeholder)

## API Routes

- `POST /api/signup/checkout` - Create user and Stripe Checkout session
- `POST /api/stripe/webhook` - Handle Stripe webhook events
- `POST /api/billing/portal` - Create Stripe Customer Portal session

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
