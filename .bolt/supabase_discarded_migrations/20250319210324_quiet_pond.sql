/*
  # Add position column to notes table
  
  1. Changes
    - Add position column to notes table
    - Set default value to 0
    - Add index for performance
    
  2. Details
    - Maintains ordering of notes
    - Ensures backward compatibility
    - Improves query performance
*/

-- Add position column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'notes' 
    AND column_name = 'position'
  ) THEN
    ALTER TABLE notes ADD COLUMN position integer DEFAULT 0;
  END IF;
END $$;

-- Create index for performance
CREATE INDEX IF NOT EXISTS notes_position_idx ON notes(project_id, position);

-- Initialize positions for existing notes based on creation date
WITH ordered_notes AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY project_id 
      ORDER BY created_at
    ) - 1 as new_position
  FROM notes
)
UPDATE notes n
SET position = o.new_position
FROM ordered_notes o
WHERE n.id = o.id;