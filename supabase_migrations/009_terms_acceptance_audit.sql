-- Immutable legal acceptance audit trail.
-- Stores version + content snapshot for Terms and Privacy at acceptance time.

CREATE TABLE IF NOT EXISTS terms_acceptance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  terms_version text NOT NULL DEFAULT '1.0',
  privacy_version text NOT NULL DEFAULT '1.0',
  terms_accepted boolean NOT NULL DEFAULT true,
  privacy_accepted boolean NOT NULL DEFAULT true,
  terms_content text,
  privacy_content text,
  ip_address text,
  user_agent text,
  accepted_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_terms_acceptance_user_id
  ON terms_acceptance(user_id);

CREATE INDEX IF NOT EXISTS idx_terms_acceptance_email
  ON terms_acceptance(email);

CREATE INDEX IF NOT EXISTS idx_terms_acceptance_accepted_at
  ON terms_acceptance(accepted_at DESC);

ALTER TABLE terms_acceptance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own terms acceptance" ON terms_acceptance;
CREATE POLICY "Users can view own terms acceptance"
  ON terms_acceptance
  FOR SELECT
  USING (auth.uid() = user_id);

-- No UPDATE / DELETE / INSERT client policies:
-- only server-side service role should write audit rows.

COMMENT ON TABLE terms_acceptance IS
'Immutable legal acceptance audit records with version and content snapshot.';
