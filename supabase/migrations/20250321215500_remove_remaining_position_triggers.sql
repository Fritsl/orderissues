
-- Drop all remaining position-related triggers
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS reorder_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS after_note_update_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS before_note_update_trigger ON notes CASCADE;

-- Drop all remaining position-related functions
DROP FUNCTION IF EXISTS maintain_note_positions() CASCADE;
DROP FUNCTION IF EXISTS reorder_note_positions() CASCADE;
DROP FUNCTION IF EXISTS normalize_note_positions() CASCADE;
DROP FUNCTION IF EXISTS move_note() CASCADE;
DROP FUNCTION IF EXISTS update_note_positions() CASCADE;
DROP FUNCTION IF EXISTS handle_note_movement() CASCADE;

-- Remove any position-related columns and indexes
ALTER TABLE notes DROP COLUMN IF EXISTS position CASCADE;
DROP INDEX IF EXISTS notes_position_idx;
DROP INDEX IF EXISTS notes_parent_position_idx;
DROP INDEX IF EXISTS notes_project_parent_position_idx;
