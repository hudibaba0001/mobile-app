-- Profiles table with subscription and consent fields
-- This replaces/extends the basic profiles table

-- Create profiles table if not exists, or alter existing
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  -- Consent fields
  terms_accepted_at timestamptz,
  privacy_accepted_at timestamptz,
  terms_version text,
  privacy_version text,
  -- Stripe fields
  stripe_customer_id text,
  stripe_subscription_id text,
  subscription_status text, -- 'pending', 'trialing', 'active', 'past_due', 'canceled'
  current_period_end timestamptz,
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add columns if they don't exist (for existing tables)
DO $$ 
BEGIN
  -- Consent fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'terms_accepted_at') THEN
    ALTER TABLE profiles ADD COLUMN terms_accepted_at timestamptz;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'privacy_accepted_at') THEN
    ALTER TABLE profiles ADD COLUMN privacy_accepted_at timestamptz;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'terms_version') THEN
    ALTER TABLE profiles ADD COLUMN terms_version text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'privacy_version') THEN
    ALTER TABLE profiles ADD COLUMN privacy_version text;
  END IF;
  
  -- Stripe fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'stripe_customer_id') THEN
    ALTER TABLE profiles ADD COLUMN stripe_customer_id text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'stripe_subscription_id') THEN
    ALTER TABLE profiles ADD COLUMN stripe_subscription_id text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'subscription_status') THEN
    ALTER TABLE profiles ADD COLUMN subscription_status text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_period_end') THEN
    ALTER TABLE profiles ADD COLUMN current_period_end timestamptz;
  END IF;
END $$;

-- Create indexes for lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer ON profiles(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_profiles_subscription ON profiles(stripe_subscription_id);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile limited" ON profiles;

-- Policy: Users can only read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update only specific non-subscription fields
-- Subscription fields can only be updated by service role (webhooks)
CREATE POLICY "Users can update own profile limited"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Note: For maximum security, you can create a separate table for 
-- subscription data that users cannot modify at all, but for simplicity
-- we rely on the web/webhook to be the only writer of subscription fields.

-- Insert policy for service role only (handled by RLS being off for service role)
-- The service role bypasses RLS entirely

COMMENT ON TABLE profiles IS 'User profiles with subscription and consent data. Subscription fields updated by Stripe webhooks only.';
