-- Supabase Table Schema for Terms & Conditions Acceptance Proof
-- Run this SQL in your Supabase SQL Editor

-- Create terms_acceptance table (audit log - never delete rows)
CREATE TABLE IF NOT EXISTS terms_acceptance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  terms_version TEXT NOT NULL DEFAULT '1.0',
  privacy_version TEXT NOT NULL DEFAULT '1.0',
  terms_accepted BOOLEAN NOT NULL DEFAULT TRUE,
  privacy_accepted BOOLEAN NOT NULL DEFAULT TRUE,
  terms_content TEXT,        -- Full T&C text at time of acceptance
  privacy_content TEXT,      -- Full Privacy Policy text at time of acceptance
  ip_address TEXT,
  user_agent TEXT,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user lookup
CREATE INDEX IF NOT EXISTS terms_acceptance_user_id_idx ON terms_acceptance(user_id);
CREATE INDEX IF NOT EXISTS terms_acceptance_email_idx ON terms_acceptance(email);

-- Enable Row Level Security (RLS)
ALTER TABLE terms_acceptance ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own acceptance" ON terms_acceptance;
DROP POLICY IF EXISTS "Users can insert their own acceptance" ON terms_acceptance;

-- Users can only see their own records
CREATE POLICY "Users can view their own acceptance"
  ON terms_acceptance FOR SELECT
  USING (auth.uid() = user_id);

-- Service role inserts on behalf of users during signup
-- No user-level INSERT policy needed since we use service role client

-- No UPDATE or DELETE policies - acceptance records are immutable for legal proof
