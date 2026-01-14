-- Add holiday work tracking columns to entries table
-- Run this after the base entries table is created

-- Add columns if they don't exist
DO $$ 
BEGIN
  -- Holiday work flag
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'entries' AND column_name = 'is_holiday_work') THEN
    ALTER TABLE entries ADD COLUMN is_holiday_work BOOLEAN DEFAULT false;
  END IF;
  
  -- Holiday name for reference
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'entries' AND column_name = 'holiday_name') THEN
    ALTER TABLE entries ADD COLUMN holiday_name TEXT;
  END IF;
END $$;

-- Create index for filtering holiday work entries
CREATE INDEX IF NOT EXISTS entries_is_holiday_work_idx ON entries(is_holiday_work) WHERE is_holiday_work = true;

-- Add comment for documentation
COMMENT ON COLUMN entries.is_holiday_work IS 'True if this entry is work done on a public holiday (red day)';
COMMENT ON COLUMN entries.holiday_name IS 'Name of the holiday if this is holiday work';
