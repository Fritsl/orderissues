/*
  # Simplify note position handling
  
  1. Changes
    - Remove complex position handling from database
    - Add simple batch update function
    - Maintain parent-child relationships only
    
  2. Details
    - Client handles position ordering
    - Database stores final state
    - Simpler, more reliable approach
*/

-- Drop existing move_note function
DROP FUNCTION IF EXISTS move_note(uuid, uuid, integer);

-- Create simple batch update function
CREATE OR REPLACE FUNCTION update_note_positions(
  p_updates jsonb -- Array of {id: uuid, position: integer, parent_id: uuid}
) RETURNS void AS $$
DECLARE
  v_project_id uuid;
  v_update record;
BEGIN
  -- Get project_id from first note
  SELECT project_id INTO v_project_id
  FROM notes
  WHERE id = (p_updates->0->>'id')::uuid;

  -- Update each note's position and parent
  FOR v_update IN 
    SELECT * FROM jsonb_array_elements(p_updates) 
  LOOP
    UPDATE notes
    SET 
      position = (v_update->>'position')::integer,
      parent_id = NULLIF((v_update->>'parent_id')::uuid, NULL),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = (v_update->>'id')::uuid;
  END LOOP;

  -- Update project's last modified timestamp
  IF v_project_id IS NOT NULL THEN
    UPDATE settings
    SET last_modified_at = CURRENT_TIMESTAMP
    WHERE id = v_project_id;
  END IF;
END;
$$ LANGUAGE plpgsql;