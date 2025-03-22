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
  v_note_content text;
  v_target_note_id uuid;
  v_max_position integer;
  -- Declare loop variables explicitly
  v_note_id uuid;
  v_current_content text;
  v_current_position integer;
BEGIN
  -- Get current note info
  SELECT project_id, parent_id, position, content
  INTO v_project_id, v_old_parent_id, v_old_position, v_note_content
  FROM notes
  WHERE id = p_note_id;

  IF v_project_id IS NULL THEN
    RAISE EXCEPTION 'Note not found';
  END IF;

  -- Get max position at target level
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

  -- Log initial state
  RAISE NOTICE 'Moving note: % (ID: %)', v_note_content, p_note_id;
  RAISE NOTICE 'From: parent=%, position=%', v_old_parent_id, v_old_position;
  RAISE NOTICE 'To: parent=%, position=%', p_new_parent_id, p_new_position;

  -- If moving within the same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    IF v_old_position = p_new_position THEN
      RAISE NOTICE 'No movement needed - same position';
      RETURN;
    END IF;

    -- Find the note at the target position
    SELECT id INTO v_target_note_id
    FROM notes
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    AND position = p_new_position;

    IF v_target_note_id IS NOT NULL THEN
      -- Direct position swap
      UPDATE notes
      SET position = 
        CASE id
          WHEN p_note_id THEN p_new_position
          WHEN v_target_note_id THEN v_old_position
        END,
        updated_at = CURRENT_TIMESTAMP
      WHERE id IN (p_note_id, v_target_note_id);
      
      RAISE NOTICE 'Swapped positions with note ID: %', v_target_note_id;
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

    -- Update the note's position and parent
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

  -- Log final positions
  RAISE NOTICE 'Final positions at target parent:';
  RAISE NOTICE '----------------------------------------';
  RAISE NOTICE 'ID | Content | Position';
  RAISE NOTICE '----------------------------------------';
  
  FOR v_note_id, v_current_content, v_current_position IN
    SELECT id, content, position
    FROM notes
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    ORDER BY position
  LOOP
    RAISE NOTICE '% | % | %', 
      v_note_id, 
      v_current_content, 
      v_current_position;
  END LOOP;
  
  RAISE NOTICE '----------------------------------------';
END;
$$ LANGUAGE plpgsql;