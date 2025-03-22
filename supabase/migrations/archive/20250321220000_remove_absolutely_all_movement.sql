-- Drop ALL functions that could be related to note movement/positioning
DROP FUNCTION IF EXISTS set_position();
DROP FUNCTION IF EXISTS get_position();
DROP FUNCTION IF EXISTS set_initial_position();
DROP FUNCTION IF EXISTS maintain_position();
DROP FUNCTION IF EXISTS reposition_notes();
DROP FUNCTION IF EXISTS handle_movement();
DROP FUNCTION IF EXISTS calculate_position();
DROP FUNCTION IF EXISTS update_positions();
DROP FUNCTION IF EXISTS normalize_positions();
DROP FUNCTION IF EXISTS sort_notes();
DROP FUNCTION IF EXISTS order_notes();
DROP FUNCTION IF EXISTS sequence_notes();

-- Drop ALL triggers that could affect note positioning
DROP TRIGGER IF EXISTS position_trigger ON notes;
DROP TRIGGER IF EXISTS movement_trigger ON notes;
DROP TRIGGER IF EXISTS sequence_trigger ON notes;
DROP TRIGGER IF EXISTS order_trigger ON notes;
DROP TRIGGER IF EXISTS sort_trigger ON notes;

-- Drop ALL position-related columns from ALL tables
ALTER TABLE notes DROP COLUMN IF EXISTS sort_order CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS sequence_num CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS display_order CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS tree_position CASCADE;
ALTER TABLE notes DROP COLUMN IF EXISTS sort_position CASCADE;

-- Drop ALL position-related indexes
DROP INDEX IF EXISTS note_order_idx;
DROP INDEX IF EXISTS note_sequence_idx;
DROP INDEX IF EXISTS note_position_idx;
DROP INDEX IF EXISTS note_sort_idx;
DROP INDEX IF EXISTS note_tree_idx;

-- Drop ALL position-related constraints
ALTER TABLE notes DROP CONSTRAINT IF EXISTS order_check;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS sequence_check;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS position_check;
ALTER TABLE notes DROP CONSTRAINT IF EXISTS sort_check;