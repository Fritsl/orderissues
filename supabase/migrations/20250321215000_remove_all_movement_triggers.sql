
-- Drop all movement-related functions and triggers
DROP FUNCTION IF EXISTS move_note CASCADE;
DROP FUNCTION IF EXISTS maintain_note_positions CASCADE;
DROP FUNCTION IF EXISTS reorder_note_positions CASCADE;
DROP FUNCTION IF EXISTS normalize_note_positions CASCADE;

-- Drop any movement-related triggers
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS reorder_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS normalize_positions_trigger ON notes CASCADE;

-- Drop indexes used for position ordering
DROP INDEX IF EXISTS notes_position_idx;
DROP INDEX IF EXISTS notes_parent_position_idx;

-- Remove position column from notes table
ALTER TABLE notes DROP COLUMN IF EXISTS position;
