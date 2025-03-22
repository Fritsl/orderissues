/*
  # Update title constraints

  1. Changes
    - Increase title length limit to 200 characters
    - Allow more English language characters including apostrophes
    - Update title validation regex
    - Maintain existing data integrity

  2. Details
    - Allows longer titles while maintaining UI usability
    - Supports common English punctuation
    - Preserves existing title uniqueness constraints
*/

-- Drop existing title constraints
ALTER TABLE settings
DROP CONSTRAINT IF EXISTS title_length_check,
DROP CONSTRAINT IF EXISTS title_characters_check;

-- Add new constraints with updated limits and character set
ALTER TABLE settings
ADD CONSTRAINT title_length_check 
  CHECK (length(trim(title)) BETWEEN 1 AND 200),
ADD CONSTRAINT title_characters_check 
  CHECK (title ~ '^[a-zA-Z0-9\s\-_.,!?()'']+$');

-- Update copy_project function to handle longer titles
CREATE OR REPLACE FUNCTION copy_project(
  source_id uuid,
  target_user_id uuid,
  target_title text
) RETURNS uuid AS $$
DECLARE
  new_project_id uuid;
  id_map jsonb := '{}'::jsonb;
  validated_title text;
  base_title text;
  counter integer := 1;
BEGIN
  -- Get source project title if target title is null or empty
  IF target_title IS NULL OR TRIM(target_title) = '' THEN
    SELECT title INTO target_title
    FROM settings
    WHERE id = source_id;
  END IF;

  -- Prepare base title
  base_title := TRIM(target_title);
  IF base_title = '' THEN
    base_title := 'New Project';
  END IF;

  -- Truncate base title if needed (leave room for suffix)
  IF LENGTH(base_title) > 190 THEN -- Leave room for " (Copy N)" suffix
    base_title := SUBSTRING(base_title, 1, 190);
  END IF;

  -- Initial title attempt
  validated_title := base_title || ' (Copy)';
  
  -- Ensure unique title
  WHILE EXISTS (
    SELECT 1 FROM settings 
    WHERE user_id = target_user_id 
    AND title = validated_title
    AND deleted_at IS NULL
  ) LOOP
    validated_title := base_title || ' (Copy ' || counter || ')';
    counter := counter + 1;
  END LOOP;

  -- Copy project settings
  INSERT INTO settings (
    user_id,
    title,
    description,
    note_count,
    last_level
  )
  SELECT 
    target_user_id,
    validated_title,
    description,
    note_count,
    last_level
  FROM settings
  WHERE id = source_id
  RETURNING id INTO new_project_id;

  -- First pass: Create all notes with new IDs
  WITH RECURSIVE note_tree AS (
    SELECT 
      id,
      content,
      parent_id,
      position,
      is_discussion,
      time_set,
      youtube_url,
      url,
      url_display_text
    FROM notes
    WHERE project_id = source_id
  )
  INSERT INTO notes (
    id,
    content,
    parent_id,
    project_id,
    position,
    is_discussion,
    time_set,
    youtube_url,
    url,
    url_display_text,
    user_id
  )
  SELECT
    gen_random_uuid(),
    content,
    parent_id,  -- We'll update these in the second pass
    new_project_id,
    position,
    is_discussion,
    time_set,
    youtube_url,
    url,
    url_display_text,
    target_user_id
  FROM note_tree
  RETURNING id, (SELECT id FROM notes WHERE id = parent_id) AS old_id
  INTO id_map;

  -- Second pass: Update parent_id references using the id_map
  UPDATE notes n
  SET parent_id = (
    SELECT id 
    FROM notes 
    WHERE project_id = new_project_id 
    AND id = id_map->n.parent_id::text
  )
  WHERE project_id = new_project_id
  AND parent_id IS NOT NULL;

  -- Copy images
  INSERT INTO note_images (
    note_id,
    url,
    storage_path,
    position
  )
  SELECT
    (SELECT id FROM notes WHERE project_id = new_project_id AND id = id_map->note_images.note_id::text),
    url,
    storage_path,
    position
  FROM note_images
  WHERE note_id IN (
    SELECT id FROM notes WHERE project_id = source_id
  );

  RETURN new_project_id;
END;
$$ LANGUAGE plpgsql;