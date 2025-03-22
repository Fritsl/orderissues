
-- Drop any remaining position-related functions
DROP FUNCTION IF EXISTS maintain_note_positions();
DROP FUNCTION IF EXISTS reorder_note_positions();
DROP FUNCTION IF EXISTS normalize_note_positions();
DROP FUNCTION IF EXISTS move_note();

-- Drop any remaining position-related triggers
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes;
DROP TRIGGER IF EXISTS reorder_positions_trigger ON notes;

-- Remove any remaining position-related indexes
DROP INDEX IF EXISTS notes_parent_position_idx;
DROP INDEX IF EXISTS notes_position_idx;
