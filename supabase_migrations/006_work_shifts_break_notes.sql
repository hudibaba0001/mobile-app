-- Migration: Add unpaid_break_minutes and notes columns to work_shifts table
-- This migration adds support for unpaid break minutes and per-shift notes

-- Check if work_shifts table exists, if not create it
CREATE TABLE IF NOT EXISTS work_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id UUID NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Add unpaid_break_minutes column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'work_shifts' AND column_name = 'unpaid_break_minutes'
  ) THEN
    ALTER TABLE work_shifts ADD COLUMN unpaid_break_minutes INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add notes column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'work_shifts' AND column_name = 'notes'
  ) THEN
    ALTER TABLE work_shifts ADD COLUMN notes TEXT;
  END IF;
END $$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS work_shifts_entry_id_idx ON work_shifts(entry_id);
CREATE INDEX IF NOT EXISTS work_shifts_start_time_idx ON work_shifts(start_time);

-- Enable Row Level Security (RLS)
ALTER TABLE work_shifts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own work shifts" ON work_shifts;
DROP POLICY IF EXISTS "Users can insert their own work shifts" ON work_shifts;
DROP POLICY IF EXISTS "Users can update their own work shifts" ON work_shifts;
DROP POLICY IF EXISTS "Users can delete their own work shifts" ON work_shifts;

-- Create RLS policies
-- Users can only see work shifts for their own entries
CREATE POLICY "Users can view their own work shifts"
  ON work_shifts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM entries 
      WHERE entries.id = work_shifts.entry_id 
      AND entries.user_id = auth.uid()
    )
  );

-- Users can insert work shifts for their own entries
CREATE POLICY "Users can insert their own work shifts"
  ON work_shifts FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM entries 
      WHERE entries.id = work_shifts.entry_id 
      AND entries.user_id = auth.uid()
    )
  );

-- Users can update work shifts for their own entries
CREATE POLICY "Users can update their own work shifts"
  ON work_shifts FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM entries 
      WHERE entries.id = work_shifts.entry_id 
      AND entries.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM entries 
      WHERE entries.id = work_shifts.entry_id 
      AND entries.user_id = auth.uid()
    )
  );

-- Users can delete work shifts for their own entries
CREATE POLICY "Users can delete their own work shifts"
  ON work_shifts FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM entries 
      WHERE entries.id = work_shifts.entry_id 
      AND entries.user_id = auth.uid()
    )
  );
