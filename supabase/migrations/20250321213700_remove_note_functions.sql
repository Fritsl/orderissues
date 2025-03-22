
-- Remove all note movement related functions
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer);
DROP FUNCTION IF EXISTS update_note_positions(jsonb);
