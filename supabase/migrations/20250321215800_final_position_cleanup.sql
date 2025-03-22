-- Drop all remaining position and movement related functions
DROP FUNCTION IF EXISTS get_sibling_count CASCADE;
DROP FUNCTION IF EXISTS maintain_note_positions CASCADE;
DROP FUNCTION IF EXISTS reorder_note_positions CASCADE;
DROP FUNCTION IF EXISTS normalize_note_positions CASCADE;
DROP FUNCTION IF EXISTS move_note CASCADE;
DROP FUNCTION IF EXISTS update_note_positions CASCADE;
DROP FUNCTION IF EXISTS handle_note_movement CASCADE;
DROP FUNCTION IF EXISTS maintain_sequences CASCADE;
DROP FUNCTION IF EXISTS maintain_image_positions CASCADE;
DROP FUNCTION IF EXISTS move_note CASCADE;

-- Drop all remaining position related triggers
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS reorder_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS after_note_update_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS before_note_update_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS normalize_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS maintain_sequences_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS maintain_image_positions_trigger ON note_images CASCADE;

-- Remove all remaining position related columns and objects
DROP TABLE IF EXISTS note_sequences CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS position CASCADE;
ALTER TABLE note_images DROP COLUMN IF EXISTS position CASCADE;
DROP INDEX IF EXISTS notes_position_idx;
DROP INDEX IF EXISTS notes_parent_position_idx;
DROP INDEX IF EXISTS notes_project_parent_position_idx;
DROP INDEX IF EXISTS note_sequences_note_id_idx;
DROP INDEX IF EXISTS note_sequences_parent_id_idx;
DROP INDEX IF EXISTS note_sequences_project_id_idx;

-- Remove position related constraints
ALTER TABLE notes DROP CONSTRAINT IF EXISTS valid_position_check;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS position_non_negative;