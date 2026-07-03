-- Migration: Add role and level columns to choir_members table
-- Run this against your Supabase database to add the missing columns

-- Add role column with default value and constraint
ALTER TABLE choir_members 
ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'choir' 
CHECK (role IN ('leader', 'committee', 'board', 'choir', 'patron', 'trainer'));

-- Add level column with default value and constraint  
ALTER TABLE choir_members 
ADD COLUMN IF NOT EXISTS level VARCHAR DEFAULT 'choir' 
CHECK (level IN ('national', 'diocese', 'parish', 'choir'));

-- Update existing records to have default role and level values
UPDATE choir_members 
SET role = 'choir', level = 'choir' 
WHERE role IS NULL OR level IS NULL;

-- Add indexes for the new columns for better query performance
CREATE INDEX IF NOT EXISTS idx_choir_members_role ON choir_members(role);
CREATE INDEX IF NOT EXISTS idx_choir_members_level ON choir_members(level);

-- Verify the changes
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_name = 'choir_members' 
AND column_name IN ('role', 'level')
ORDER BY ordinal_position;