/*
  # Fix note movement function with proper logging

  1. Changes
    - Fix loop variable declaration in FOR loop
    - Add proper logging of note movement
    - Maintain position integrity
    - Fix error handling

  2. Details
    - Uses proper record variable declaration
    - Logs movement details
    - Maintains data consistency
*/

-- Drop existing move_note function
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer);

-- Create improved move_note function with logging
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
  v_note_content text;
  v_note record;
BEGIN
  -- Get current note info
  SELECT project_id, parent_id, position, content
  INTO v_project_id, v_old_parent_id, v_old_position, v_note_content
  FROM notes
  WHERE id = p_note_id;

  IF v_project_id IS NULL THEN
    RAISE EXCEPTION 'Note not found';
  END IF;

  -- Log initial state
  RAISE NOTICE 'Moving note: % (ID: %)', v_note_content, p_note_id;
  RAISE NOTICE 'From: parent=%, position=%', v_old_parent_id, v_old_position;
  RAISE NOTICE 'To: parent=%, position=%', p_new_parent_id, p_new_position;

  -- Get max position at target level
  SELECT COALESCE(MAX(position), -1)
  INTO v_max_position
  FROM notes
  WHERE project_id = v_project_id
  AND parent_id IS NOT DISTINCT FROM p_new_parent_id
  AND id != p_note_id;

  RAISE NOTICE 'Max position at target level: %', v_max_position;

  -- Validate position
  IF p_new_position < 0 THEN
    p_new_position := 0;
    RAISE NOTICE 'Adjusted negative position to 0';
  ELSIF p_new_position > v_max_position + 1 THEN
    p_new_position := v_max_position + 1;
    RAISE NOTICE 'Adjusted position to max + 1: %', p_new_position;
  END IF;

  -- If moving within the same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    IF v_old_position = p_new_position THEN
      RAISE NOTICE 'No movement needed - same position';
      RETURN;
    END IF;

    RAISE NOTICE 'Moving within same parent from % to %', v_old_position, p_new_position;

    -- Moving up (to a lower position number)
    IF p_new_position < v_old_position THEN
      RAISE NOTICE 'Moving up - shifting positions % to % up by 1', p_new_position, v_old_position - 1;
      
      UPDATE notes
      SET position = position + 1
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position >= p_new_position
      AND position < v_old_position;
    
    -- Moving down (to a higher position number)
    ELSE
      RAISE NOTICE 'Moving down - shifting positions % to % down by 1', v_old_position + 1, p_new_position;
      
      UPDATE notes
      SET position = position - 1
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position > v_old_position
      AND position <= p_new_position;
    END IF;

  -- Moving to different parent
  ELSE
    RAISE NOTICE 'Moving to different parent';
    
    -- Close gap at old position
    UPDATE notes
    SET position = position - 1
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM v_old_parent_id
    AND position > v_old_position;

    -- Make space at new position
    UPDATE notes
    SET position = position + 1
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    AND position >= p_new_position;
  END IF;

  -- Update the note's position and parent
  UPDATE notes
  SET 
    parent_id = p_new_parent_id,
    position = p_new_position,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_note_id;

  RAISE NOTICE 'Note updated successfully to position %', p_new_position;

  -- Log final state
  RAISE NOTICE 'Final positions at target parent:';
  FOR v_note IN (
    SELECT id, content, position
    FROM notes
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    ORDER BY position
  ) LOOP
    RAISE NOTICE '  % (ID: %): position %', v_note.content, v_note.id, v_note.position;
  END LOOP;

  -- Update project's last modified timestamp
  UPDATE settings
  SET last_modified_at = CURRENT_TIMESTAMP
  WHERE id = v_project_id;
END;
$$ LANGUAGE plpgsql;