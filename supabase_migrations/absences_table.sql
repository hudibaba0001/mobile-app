-- Create absences table for tracking paid/unpaid absences
CREATE TABLE IF NOT EXISTS absences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  minutes INTEGER NOT NULL DEFAULT 0,
  type TEXT NOT NULL CHECK (type IN ('vacationPaid', 'sickPaid', 'vabPaid', 'unpaid')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_absences_user_date ON absences(user_id, date);

-- Enable Row Level Security
ALTER TABLE absences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own absences
CREATE POLICY "Users can select own absences"
  ON absences
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own absences"
  ON absences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own absences"
  ON absences
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own absences"
  ON absences
  FOR DELETE
  USING (auth.uid() = user_id);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_absences_updated_at
  BEFORE UPDATE ON absences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

