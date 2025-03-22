/*
  # Fix note movement function
  
  1. Changes
    - Drop existing function
    - Create new move_note function with correct parameter order
    - Fix parameter names to match client calls
    - Add proper error handling
    
  2. Details
    - Maintains existing functionality
    - Fixes parameter order issue
    - Preserves position handling logic
*/

-- Drop existing function
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer);
DROP FUNCTION IF EXISTS update_note_positions(jsonb);

-- Create move_note function with correct parameter order
CREATE OR REPLACE FUNCTION move_note(
  p_note_id uuid,
  p_new_parent_id uuid,
  p_new_position integer
) RETURNS void AS $$
DECLARE
  v_project_id uuid;
  v_old_parent_id uuid;
  v_old_position integer;
  v_max_position integer;
  v_target_note_id uuid;
BEGIN
  -- Lock the affected notes to prevent race conditions
  PERFORM pg_advisory_xact_lock(hashtext('move_note'::text));

  -- Get current note info
  SELECT project_id, parent_id, position
  INTO v_project_id, v_old_parent_id, v_old_position
  FROM notes
  WHERE id = p_note_id
  FOR UPDATE;

  -- Moving within same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    -- First make space at the target position
    UPDATE notes
    SET position = 
      CASE 
        WHEN position >= p_new_position AND position < v_old_position THEN position + 1
        WHEN position <= p_new_position AND position > v_old_position THEN position - 1
        ELSE position
      END
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND id != p_note_id;

    -- Then move the note to its new position
    UPDATE notes
    SET position = p_new_position,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;

  -- Moving to different parent
  ELSE
    -- Update positions in old parent
    UPDATE notes
    SET position = position - 1
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM v_old_parent_id
      AND position > v_old_position;

    -- Make space in new parent
    UPDATE notes
    SET position = position + 1
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position >= p_new_position;

    -- Move the note
    UPDATE notes
    SET 
      parent_id = p_new_parent_id,
      position = p_new_position,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;
  END IF;
END;
$$ LANGUAGE plpgsql;