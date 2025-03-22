
-- Drop everything first
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Grant necessary permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create base tables
CREATE TABLE IF NOT EXISTS settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  title text NOT NULL DEFAULT 'New Project',
  description text NOT NULL DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_modified_at timestamptz DEFAULT now(),
  note_count integer DEFAULT 0,
  deleted_at timestamptz DEFAULT NULL,
  CONSTRAINT title_length_check CHECK (length(trim(title)) BETWEEN 1 AND 50),
  CONSTRAINT title_whitespace_check CHECK (title = trim(title)),
  CONSTRAINT title_characters_check CHECK (title ~ '^[a-zA-Z0-9\s\-_.,!?()]+$'),
  CONSTRAINT description_length_check CHECK (length(description) <= 500),
  CONSTRAINT unique_title_per_user UNIQUE (user_id, title)
);

CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content text DEFAULT '',
  user_id uuid NOT NULL REFERENCES auth.users(id),
  project_id uuid NOT NULL REFERENCES settings(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES notes(id) ON DELETE CASCADE,
  is_discussion boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS note_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  url text,
  storage_path text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS notes_project_id_idx ON notes(project_id);
CREATE INDEX IF NOT EXISTS notes_parent_id_idx ON notes(parent_id);
CREATE INDEX IF NOT EXISTS note_images_note_id_idx ON note_images(note_id);

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_images ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can read own settings"
  ON settings FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own settings"
  ON settings FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own settings"
  ON settings FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can read own notes"
  ON notes FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own notes"
  ON notes FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own notes"
  ON notes FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own notes"
  ON notes FOR DELETE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own note images"
  ON note_images FOR ALL TO authenticated
  USING (note_id IN (SELECT id FROM notes WHERE user_id = auth.uid()));
