-- Add setup completion timestamp to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS setup_completed_at timestamptz;
