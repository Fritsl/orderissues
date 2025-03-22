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
  p_new_parent_id uuid,
  p_new_position integer,
  p_note_id uuid
) RETURNS void AS $$
DECLARE
  v_project_id uuid;
  v_old_parent_id uuid;
  v_old_position integer;
  v_max_position integer;
  v_target_note_id uuid;
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
    -- If no actual movement, return early
    IF v_old_position = p_new_position THEN
      RETURN;
    END IF;

    -- Check if there's a note at the target position
    SELECT id INTO v_target_note_id
    FROM notes
    WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position = p_new_position
      AND id != p_note_id;

    IF v_target_note_id IS NOT NULL THEN
      -- Direct swap with target note
      UPDATE notes
      SET position = 
        CASE id
          WHEN p_note_id THEN p_new_position
          WHEN v_target_note_id THEN v_old_position
        END,
        updated_at = CURRENT_TIMESTAMP
      WHERE id IN (p_note_id, v_target_note_id);
    ELSE
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

      -- Update the moving note's position
      UPDATE notes
      SET 
        position = p_new_position,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = p_note_id;
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

    -- Update the note's parent and position
    UPDATE notes
    SET 
      parent_id = p_new_parent_id,
      position = p_new_position,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;
  END IF;

  -- Update project's last modified timestamp
  UPDATE settings
  SET last_modified_at = CURRENT_TIMESTAMP
  WHERE id = v_project_id;
END;
$$ LANGUAGE plpgsql;