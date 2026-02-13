-- Google Play entitlement source of truth for mobile billing
-- Keeps billing state isolated from profiles table.

CREATE TABLE IF NOT EXISTS user_entitlements (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'google_play',
  product_id text,
  purchase_token text UNIQUE,
  status text NOT NULL DEFAULT 'pending_subscription',
  current_period_end timestamptz,
  raw_subscription_state text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_entitlements_provider_check
    CHECK (provider IN ('google_play')),
  CONSTRAINT user_entitlements_status_check
    CHECK (
      status IN (
        'pending_subscription',
        'active',
        'grace',
        'on_hold',
        'canceled',
        'expired'
      )
    )
);

CREATE INDEX IF NOT EXISTS idx_user_entitlements_status
  ON user_entitlements(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_entitlements_purchase_token
  ON user_entitlements(purchase_token);

ALTER TABLE user_entitlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own entitlement" ON user_entitlements;
CREATE POLICY "Users can view own entitlement"
  ON user_entitlements
  FOR SELECT
  USING (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE policies on purpose:
-- authenticated users cannot mutate entitlements from client SDK.

CREATE OR REPLACE FUNCTION set_user_entitlements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_user_entitlements_updated_at_trigger ON user_entitlements;
CREATE TRIGGER set_user_entitlements_updated_at_trigger
  BEFORE UPDATE ON user_entitlements
  FOR EACH ROW
  EXECUTE FUNCTION set_user_entitlements_updated_at();

-- Keep a lightweight, non-authoritative profile status for UX.
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS entitlement_status text;

ALTER TABLE profiles
  ALTER COLUMN entitlement_status SET DEFAULT 'pending_subscription';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_entitlement_status_check'
  ) THEN
    ALTER TABLE profiles
      ADD CONSTRAINT profiles_entitlement_status_check
      CHECK (
        entitlement_status IS NULL OR
        entitlement_status IN (
          'pending_subscription',
          'active',
          'grace',
          'on_hold',
          'canceled',
          'expired'
        )
      );
  END IF;
END $$;

UPDATE profiles
SET entitlement_status = CASE
  WHEN subscription_status IN ('active', 'trialing') THEN 'active'
  WHEN subscription_status = 'past_due' THEN 'grace'
  WHEN subscription_status = 'canceled' THEN 'canceled'
  ELSE COALESCE(entitlement_status, 'pending_subscription')
END
WHERE entitlement_status IS NULL;

-- Extend existing profile escalation guard to include entitlement_status.
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
  IF NEW.entitlement_status IS DISTINCT FROM OLD.entitlement_status THEN
    RAISE EXCEPTION 'Cannot modify entitlement status';
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

COMMENT ON TABLE user_entitlements IS
'Authoritative subscription entitlement state for mobile billing providers.';
