-- Profiles table with subscription and consent fields
-- This replaces/extends the basic profiles table

-- Create profiles table if not exists, or alter existing
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  first_name text,
  last_name text,
  phone text,
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
  -- Contract / settings fields
  contract_percent integer,
  full_time_hours integer,
  tracking_start_date date,
  opening_flex_minutes integer,
  employer_mode text,
  -- Admin & feature flags
  is_admin boolean DEFAULT false,
  is_dark_mode boolean,
  travel_logging_enabled boolean,
  time_balance_enabled boolean,
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add columns if they don't exist (for existing tables)
DO $$ 
BEGIN
  -- User info fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'first_name') THEN
    ALTER TABLE profiles ADD COLUMN first_name text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_name') THEN
    ALTER TABLE profiles ADD COLUMN last_name text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'phone') THEN
    ALTER TABLE profiles ADD COLUMN phone text;
  END IF;

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

  -- Contract / settings fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'contract_percent') THEN
    ALTER TABLE profiles ADD COLUMN contract_percent integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'full_time_hours') THEN
    ALTER TABLE profiles ADD COLUMN full_time_hours integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'tracking_start_date') THEN
    ALTER TABLE profiles ADD COLUMN tracking_start_date date;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'opening_flex_minutes') THEN
    ALTER TABLE profiles ADD COLUMN opening_flex_minutes integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'employer_mode') THEN
    ALTER TABLE profiles ADD COLUMN employer_mode text;
  END IF;

  -- Admin & feature flags
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_admin') THEN
    ALTER TABLE profiles ADD COLUMN is_admin boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_dark_mode') THEN
    ALTER TABLE profiles ADD COLUMN is_dark_mode boolean;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'travel_logging_enabled') THEN
    ALTER TABLE profiles ADD COLUMN travel_logging_enabled boolean;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'time_balance_enabled') THEN
    ALTER TABLE profiles ADD COLUMN time_balance_enabled boolean;
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

-- Policy: Users can update their own profile row
-- A BEFORE UPDATE trigger (prevent_profile_escalation) blocks changes to
-- protected columns: is_admin, subscription_status, stripe_customer_id,
-- stripe_subscription_id, current_period_end, email.
-- Service role bypasses the trigger for webhook/admin operations.
CREATE POLICY "Users can update own profile limited"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Trigger function: blocks non-service-role users from updating sensitive columns
CREATE OR REPLACE FUNCTION prevent_profile_escalation()
RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('role', true) = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
    RAISE EXCEPTION 'Cannot modify admin status';
  END IF;
  IF NEW.subscription_status IS DISTINCT FROM OLD.subscription_status THEN
    RAISE EXCEPTION 'Cannot modify subscription status';
  END IF;
  IF NEW.stripe_customer_id IS DISTINCT FROM OLD.stripe_customer_id THEN
    RAISE EXCEPTION 'Cannot modify Stripe customer ID';
  END IF;
  IF NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id THEN
    RAISE EXCEPTION 'Cannot modify Stripe subscription ID';
  END IF;
  IF NEW.current_period_end IS DISTINCT FROM OLD.current_period_end THEN
    RAISE EXCEPTION 'Cannot modify subscription period';
  END IF;
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'Cannot modify email directly';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

DROP TRIGGER IF EXISTS profile_escalation_guard ON profiles;
CREATE TRIGGER profile_escalation_guard
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION prevent_profile_escalation();

COMMENT ON TABLE profiles IS 'User profiles with subscription and consent data. Subscription fields updated by Stripe webhooks only.';
