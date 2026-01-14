-- User Red Days table for B2C personal red day marking
-- Users can mark their own full/half red days (personal days off, etc.)

-- Create enum-like check constraints
CREATE TABLE IF NOT EXISTS user_red_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('FULL', 'HALF')),
  half TEXT CHECK (
    (kind = 'FULL' AND half IS NULL) OR 
    (kind = 'HALF' AND half IN ('AM', 'PM'))
  ),
  reason TEXT,
  source TEXT NOT NULL DEFAULT 'MANUAL' CHECK (source IN ('MANUAL', 'COMPANY', 'IMPORTED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  
  -- One entry per user per date (can update kind/half)
  CONSTRAINT user_red_days_unique UNIQUE (user_id, date)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS user_red_days_user_id_idx ON user_red_days(user_id);
CREATE INDEX IF NOT EXISTS user_red_days_date_idx ON user_red_days(date);
CREATE INDEX IF NOT EXISTS user_red_days_user_date_range_idx ON user_red_days(user_id, date);

-- Enable Row Level Security
ALTER TABLE user_red_days ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (allows re-running)
DROP POLICY IF EXISTS "Users can view their own red days" ON user_red_days;
DROP POLICY IF EXISTS "Users can insert their own red days" ON user_red_days;
DROP POLICY IF EXISTS "Users can update their own red days" ON user_red_days;
DROP POLICY IF EXISTS "Users can delete their own red days" ON user_red_days;

-- RLS Policies: Users can only manage their own red days
CREATE POLICY "Users can view their own red days"
  ON user_red_days FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own red days"
  ON user_red_days FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own red days"
  ON user_red_days FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own red days"
  ON user_red_days FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-update updated_at trigger
DROP TRIGGER IF EXISTS update_user_red_days_updated_at ON user_red_days;
CREATE TRIGGER update_user_red_days_updated_at
  BEFORE UPDATE ON user_red_days
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE user_red_days IS 'User-defined personal red days (days off). B2C-first, B2B-ready with source column.';
COMMENT ON COLUMN user_red_days.kind IS 'FULL = entire day, HALF = morning or afternoon only';
COMMENT ON COLUMN user_red_days.half IS 'AM or PM when kind=HALF, NULL when kind=FULL';
COMMENT ON COLUMN user_red_days.source IS 'MANUAL = user-added, COMPANY = from employer (future), IMPORTED = bulk import';
