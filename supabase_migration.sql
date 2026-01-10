-- Migration script to fix column names in entries table
-- Run this if you already created the table with the old schema (quoted "from" and "to" columns)

-- Option 1: Rename columns (preserves existing data)
-- Check if old columns exist and rename them
DO $$
BEGIN
  -- Rename "from" to from_location if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'entries' AND column_name = 'from'
  ) THEN
    ALTER TABLE entries RENAME COLUMN "from" TO from_location;
    RAISE NOTICE 'Renamed column "from" to from_location';
  END IF;

  -- Rename "to" to to_location if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'entries' AND column_name = 'to'
  ) THEN
    ALTER TABLE entries RENAME COLUMN "to" TO to_location;
    RAISE NOTICE 'Renamed column "to" to to_location';
  END IF;
END $$;

-- Option 2: If you want to start fresh (deletes all data!)
-- Uncomment the next line only if you want to delete everything:
-- DROP TABLE IF EXISTS entries CASCADE;
-- Then run supabase_schema.sql to recreate the table

