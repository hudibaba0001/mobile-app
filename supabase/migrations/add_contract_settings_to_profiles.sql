-- Migration: Add contract settings to profiles table
-- Run this in Supabase SQL Editor

-- Add contract settings columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS contract_percent INTEGER DEFAULT 100,
ADD COLUMN IF NOT EXISTS full_time_hours INTEGER DEFAULT 40,
ADD COLUMN IF NOT EXISTS tracking_start_date DATE,
ADD COLUMN IF NOT EXISTS opening_flex_minutes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS employer_mode TEXT DEFAULT 'standard';

-- Add constraints
ALTER TABLE profiles
ADD CONSTRAINT contract_percent_range CHECK (contract_percent >= 0 AND contract_percent <= 100),
ADD CONSTRAINT full_time_hours_positive CHECK (full_time_hours > 0),
ADD CONSTRAINT employer_mode_valid CHECK (employer_mode IN ('standard', 'strict', 'flexible'));

-- Add comment for documentation
COMMENT ON COLUMN profiles.contract_percent IS 'Work contract percentage (0-100)';
COMMENT ON COLUMN profiles.full_time_hours IS 'Full-time hours per week';
COMMENT ON COLUMN profiles.tracking_start_date IS 'Date from which to start tracking balances';
COMMENT ON COLUMN profiles.opening_flex_minutes IS 'Opening balance in minutes (positive = credit, negative = deficit)';
COMMENT ON COLUMN profiles.employer_mode IS 'Employer validation mode: standard, strict, or flexible';
