-- Email settings table for cloud sync
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS email_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  manager_email TEXT NOT NULL DEFAULT '',
  sender_email TEXT NOT NULL DEFAULT '',
  sender_name TEXT NOT NULL DEFAULT '',
  auto_send_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  auto_send_frequency TEXT NOT NULL DEFAULT 'weekly',
  auto_send_day INTEGER NOT NULL DEFAULT 1,
  default_report_format TEXT NOT NULL DEFAULT 'excel',
  default_report_period TEXT NOT NULL DEFAULT 'lastWeek',
  custom_subject_template TEXT NOT NULL DEFAULT '',
  custom_message_template TEXT NOT NULL DEFAULT '',
  include_charts BOOLEAN NOT NULL DEFAULT TRUE,
  include_summary BOOLEAN NOT NULL DEFAULT TRUE,
  include_detailed_entries BOOLEAN NOT NULL DEFAULT TRUE,
  last_sent_date TIMESTAMPTZ,
  smtp_server TEXT NOT NULL DEFAULT 'smtp.gmail.com',
  smtp_port INTEGER NOT NULL DEFAULT 587,
  use_ssl BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_email_settings_user_id ON email_settings(user_id);

-- Enable RLS
ALTER TABLE email_settings ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view own email settings"
  ON email_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own email settings"
  ON email_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own email settings"
  ON email_settings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own email settings"
  ON email_settings FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_email_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_email_settings_updated_at
  BEFORE UPDATE ON email_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_email_settings_updated_at();
