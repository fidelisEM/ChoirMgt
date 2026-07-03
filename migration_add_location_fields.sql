-- Migration: Add location fields to choirs table
-- Run this against your Supabase database to add the missing location columns

-- Add location fields to choirs table
ALTER TABLE choirs 
ADD COLUMN IF NOT EXISTS country VARCHAR,
ADD COLUMN IF NOT EXISTS diocese VARCHAR,
ADD COLUMN IF NOT EXISTS parish VARCHAR,
ADD COLUMN IF NOT EXISTS location VARCHAR;

-- Add indexes for better query performance on location fields
CREATE INDEX IF NOT EXISTS idx_choirs_country ON choirs(country);
CREATE INDEX IF NOT EXISTS idx_choirs_diocese ON choirs(diocese);
CREATE INDEX IF NOT EXISTS idx_choirs_parish ON choirs(parish);

-- Add schedule field if needed
ALTER TABLE choirs 
ADD COLUMN IF NOT EXISTS schedule VARCHAR;

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'choirs' 
AND column_name IN ('country', 'diocese', 'parish', 'location', 'schedule')
ORDER BY ordinal_position;

-- Display current choirs table structure
\d choirs;