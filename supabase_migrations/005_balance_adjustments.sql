-- Balance Adjustments table for manual balance corrections
-- Adjustments shift the running balance by +/- minutes without changing worked/scheduled hours

CREATE TABLE IF NOT EXISTS balance_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  effective_date DATE NOT NULL,
  delta_minutes INT NOT NULL,  -- Signed: positive = credit, negative = deficit
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient querying by user and date range
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_user_date 
  ON balance_adjustments(user_id, effective_date);

-- Enable Row Level Security
ALTER TABLE balance_adjustments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotent migrations)
DROP POLICY IF EXISTS "Users can view their own adjustments" ON balance_adjustments;
DROP POLICY IF EXISTS "Users can insert their own adjustments" ON balance_adjustments;
DROP POLICY IF EXISTS "Users can update their own adjustments" ON balance_adjustments;
DROP POLICY IF EXISTS "Users can delete their own adjustments" ON balance_adjustments;

-- RLS Policies: users can only CRUD their own adjustments
CREATE POLICY "Users can view their own adjustments"
  ON balance_adjustments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own adjustments"
  ON balance_adjustments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own adjustments"
  ON balance_adjustments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own adjustments"
  ON balance_adjustments FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_balance_adjustments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_balance_adjustments_updated_at ON balance_adjustments;
CREATE TRIGGER trigger_balance_adjustments_updated_at
  BEFORE UPDATE ON balance_adjustments
  FOR EACH ROW
  EXECUTE FUNCTION update_balance_adjustments_updated_at();
