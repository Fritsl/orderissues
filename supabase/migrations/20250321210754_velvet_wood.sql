/*
  # Fix note movement function

  1. Changes
    - Add explicit exclusion of moving note from position updates
    - Fix position validation and adjustment
    - Improve same-parent movement handling
    - Fix different-parent movement handling

  2. Details
    - Excludes moving note from sibling updates
    - Maintains proper ordering
    - Prevents position conflicts
*/

-- Drop existing move_note function
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer);

-- Create improved move_note function
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
BEGIN
  -- Get current note info
  SELECT project_id, parent_id, position
  INTO v_project_id, v_old_parent_id, v_old_position
  FROM notes
  WHERE id = p_note_id;

  IF v_project_id IS NULL THEN
    RAISE EXCEPTION 'Note not found';
  END IF;

  -- Get max position at target level (excluding the moving note)
  SELECT COALESCE(MAX(position), -1)
  INTO v_max_position
  FROM notes
  WHERE project_id = v_project_id
  AND parent_id IS NOT DISTINCT FROM p_new_parent_id
  AND id != p_note_id;

  -- Validate position
  IF p_new_position < 0 THEN
    p_new_position := 0;
  ELSIF p_new_position > v_max_position + 1 THEN
    p_new_position := v_max_position + 1;
  END IF;

  -- If moving within the same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    IF v_old_position = p_new_position THEN
      RETURN; -- No movement needed
    END IF;

    -- Moving up (to a lower position number)
    IF p_new_position < v_old_position THEN
      UPDATE notes
      SET position = position + 1
      WHERE project_id = v_project_id
        AND parent_id IS NOT DISTINCT FROM p_new_parent_id
        AND id != p_note_id
        AND position >= p_new_position
        AND position < v_old_position;
    
    -- Moving down (to a higher position number)
    ELSE
      UPDATE notes
      SET position = position - 1
      WHERE project_id = v_project_id
        AND parent_id IS NOT DISTINCT FROM p_new_parent_id
        AND id != p_note_id
        AND position > v_old_position
        AND position <= p_new_position;
    END IF;

  -- Moving to different parent
  ELSE
    -- Close gap at old position
    UPDATE notes
    SET position = position - 1
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM v_old_parent_id
      AND id != p_note_id
      AND position > v_old_position;

    -- Make space at new position
    UPDATE notes
    SET position = position + 1
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND id != p_note_id
      AND position >= p_new_position;
  END IF;

  -- Finally, update the note's parent and position
  UPDATE notes
  SET 
    parent_id = p_new_parent_id,
    position = p_new_position,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_note_id;

  -- Update project's last modified timestamp
  UPDATE settings
  SET last_modified_at = CURRENT_TIMESTAMP
  WHERE id = v_project_id;
END;
$$ LANGUAGE plpgsql;