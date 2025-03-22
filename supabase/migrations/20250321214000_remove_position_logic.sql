-- Remove position-related triggers
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes;
DROP FUNCTION IF EXISTS maintain_note_positions();

-- Remove position column from notes table
ALTER TABLE notes DROP COLUMN IF EXISTS position;

-- Remove position-related indexes
DROP INDEX IF EXISTS notes_parent_position_idx;