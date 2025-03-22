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
  v_note_record record;
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

  -- If moving within the same parent
  IF v_old_parent_id IS NOT DISTINCT FROM p_new_parent_id THEN
    -- Find the note at the target position
    SELECT id INTO v_target_note_id
    FROM notes
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    AND position = p_new_position
    AND id != p_note_id;

    IF v_target_note_id IS NOT NULL THEN
      -- Simple position swap
      UPDATE notes
      SET position = 
        CASE id
          WHEN p_note_id THEN p_new_position
          WHEN v_target_note_id THEN v_old_position
        END,
        updated_at = CURRENT_TIMESTAMP
      WHERE id IN (p_note_id, v_target_note_id);
      
      RAISE NOTICE 'Swapped positions with note ID: %', v_target_note_id;
    ELSE
      -- Moving to an empty position
      UPDATE notes
      SET 
        position = p_new_position,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = p_note_id;
      
      RAISE NOTICE 'Moved to empty position: %', p_new_position;
    END IF;

  -- Moving to different parent
  ELSE
    RAISE NOTICE 'Moving to different parent';
    
    -- Update the note's position and parent
    UPDATE notes
    SET 
      parent_id = p_new_parent_id,
      position = p_new_position,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = p_note_id;

    -- Normalize positions at both old and new parent levels
    WITH ordered_notes AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY position) - 1 as new_pos
      FROM notes
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM v_old_parent_id
    )
    UPDATE notes n
    SET position = o.new_pos
    FROM ordered_notes o
    WHERE n.id = o.id;

    WITH ordered_notes AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY position) - 1 as new_pos
      FROM notes
      WHERE project_id = v_project_id
      AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    )
    UPDATE notes n
    SET position = o.new_pos
    FROM ordered_notes o
    WHERE n.id = o.id;
  END IF;

  -- Update project's last modified timestamp
  UPDATE settings
  SET last_modified_at = CURRENT_TIMESTAMP
  WHERE id = v_project_id;

  -- Log final positions
  RAISE NOTICE 'Final positions:';
  FOR v_note_record IN (
    SELECT id, content, position
    FROM notes
    WHERE project_id = v_project_id
    AND parent_id IS NOT DISTINCT FROM p_new_parent_id
    ORDER BY position
  ) LOOP
    RAISE NOTICE '  % (ID: %): position %', 
      v_note_record.content, 
      v_note_record.id, 
      v_note_record.position;
  END LOOP;
END;
$$ LANGUAGE plpgsql;