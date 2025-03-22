
CREATE OR REPLACE FUNCTION move_note(
  p_note_id UUID,
  p_new_parent_id UUID,
  p_new_position INTEGER
) RETURNS void AS $$
DECLARE
  v_old_position INTEGER;
  v_old_parent_id UUID;
  v_project_id UUID;
BEGIN
  -- Get current note info
  SELECT position, parent_id, project_id INTO v_old_position, v_old_parent_id, v_project_id
  FROM notes 
  WHERE id = p_note_id;

  RAISE NOTICE 'Moving note % from parent % pos % to parent % pos %',
    p_note_id, v_old_parent_id, v_old_position, p_new_parent_id, p_new_position;

  -- If moving within the same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    IF v_old_position = p_new_position THEN
      RETURN; -- No movement needed
    END IF;

    -- Moving up (to a lower position number)
    IF p_new_position < v_old_position THEN
      UPDATE notes
      SET position = position + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position >= p_new_position
      AND position < v_old_position;
    
    -- Moving down (to a higher position number)
    ELSE
      UPDATE notes
      SET position = position - 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
      AND position > v_old_position
      AND position <= p_new_position;
    END IF;

    -- Update the moved note's position
    UPDATE notes
    SET position = p_new_position,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;

  -- Moving to different parent  
  ELSE
    -- Close gap at old position
    UPDATE notes
    SET position = position - 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM v_old_parent_id
    AND position > v_old_position;

    -- Make space at new position
    UPDATE notes
    SET position = position + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    AND position >= p_new_position;

    -- Update the note's position and parent
    UPDATE notes
    SET 
      parent_id = p_new_parent_id,
      position = p_new_position,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;
  END IF;
END;
$$ LANGUAGE plpgsql;
