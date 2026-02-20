-- Migration: persist onboarding completion on profile
-- Adds setup completion timestamp and ensures users can update their own row.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS setup_completed_at timestamptz;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'profiles_update_own_setup_completion'
  ) THEN
    CREATE POLICY profiles_update_own_setup_completion
      ON profiles
      FOR UPDATE
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END
$$;

COMMENT ON COLUMN profiles.setup_completed_at IS
  'Timestamp set when onboarding setup is completed.';
