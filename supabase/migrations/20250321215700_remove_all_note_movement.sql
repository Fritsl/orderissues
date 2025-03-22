-- Drop all remaining note sequence related objects
DROP TABLE IF EXISTS note_sequences CASCADE;
DROP INDEX IF EXISTS note_sequences_note_id_idx;
DROP INDEX IF EXISTS note_sequences_parent_id_idx;
DROP INDEX IF EXISTS note_sequences_project_id_idx;

-- Drop all note movement related functions
DROP FUNCTION IF EXISTS maintain_sequences() CASCADE;
DROP FUNCTION IF EXISTS maintain_image_positions() CASCADE;
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS update_note_positions(jsonb) CASCADE;

-- Drop all note position related triggers
DROP TRIGGER IF EXISTS maintain_sequences_trigger ON notes;
DROP TRIGGER IF EXISTS maintain_image_positions_trigger ON note_images;

-- Remove any remaining position columns
ALTER TABLE notes DROP COLUMN IF EXISTS position CASCADE;
ALTER TABLE note_images DROP COLUMN IF EXISTS position CASCADE;

-- Remove any position related constraints
ALTER TABLE notes DROP CONSTRAINT IF EXISTS valid_position_check;