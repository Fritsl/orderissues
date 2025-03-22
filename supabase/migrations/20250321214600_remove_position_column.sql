
-- Remove position column from notes table if it still exists
ALTER TABLE notes DROP COLUMN IF EXISTS position;
