-- Drop all movement related functions if they exist
DROP FUNCTION IF EXISTS move_note CASCADE;
DROP FUNCTION IF EXISTS set_initial_position CASCADE;
DROP FUNCTION IF EXISTS maintain_note_positions CASCADE;
DROP FUNCTION IF EXISTS reorder_note_positions CASCADE;
DROP FUNCTION IF EXISTS normalize_note_positions CASCADE;
DROP FUNCTION IF EXISTS update_note_positions CASCADE;
DROP FUNCTION IF EXISTS handle_note_movement CASCADE;
DROP FUNCTION IF EXISTS maintain_sequences CASCADE;
DROP FUNCTION IF EXISTS maintain_image_positions CASCADE;
DROP FUNCTION IF EXISTS get_sibling_count CASCADE;

-- Drop all movement related triggers if they exist
DROP TRIGGER IF EXISTS maintain_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS reorder_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS after_note_update_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS before_note_update_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS normalize_positions_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS maintain_sequences_trigger ON notes CASCADE;
DROP TRIGGER IF EXISTS maintain_image_positions_trigger ON note_images CASCADE;
DROP TRIGGER IF EXISTS ensure_note_position ON notes CASCADE;

-- Drop all position related tables if they exist
DROP TABLE IF EXISTS note_sequences CASCADE;
DROP TABLE IF EXISTS note_positions CASCADE;

-- Remove all position related columns from remaining tables
ALTER TABLE notes DROP COLUMN IF EXISTS position CASCADE;
ALTER TABLE note_images DROP COLUMN IF EXISTS position CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS sequence_number CASCADE;

-- Drop all position related indexes
DROP INDEX IF EXISTS notes_position_idx;
DROP INDEX IF EXISTS notes_parent_position_idx;
DROP INDEX IF EXISTS notes_project_parent_position_idx;
DROP INDEX IF EXISTS note_sequences_note_id_idx;
DROP INDEX IF EXISTS note_sequences_parent_id_idx;
DROP INDEX IF EXISTS note_sequences_project_id_idx;
DROP INDEX IF EXISTS notes_sequence_number_idx;

-- Drop all position related constraints
ALTER TABLE notes DROP CONSTRAINT IF EXISTS valid_position_check;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS position_non_negative;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS sequence_order_check;