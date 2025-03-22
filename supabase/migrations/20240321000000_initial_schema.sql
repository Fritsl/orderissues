
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create base tables
CREATE TABLE IF NOT EXISTS settings (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id),
    title text NOT NULL DEFAULT 'New Project',
    description text DEFAULT '',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    last_modified_at timestamptz DEFAULT now(),
    note_count integer DEFAULT 0,
    deleted_at timestamptz DEFAULT NULL,
    CONSTRAINT title_length CHECK (char_length(title) BETWEEN 1 AND 50)
);

CREATE TABLE IF NOT EXISTS notes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    content text DEFAULT '',
    user_id uuid REFERENCES auth.users(id),
    project_id uuid REFERENCES settings(id) ON DELETE CASCADE,
    parent_id uuid REFERENCES notes(id) ON DELETE CASCADE,
    is_discussion boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own settings"
    ON settings FOR ALL TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own notes"
    ON notes FOR ALL TO authenticated
    USING (user_id = auth.uid());

-- Create indexes
CREATE INDEX IF NOT EXISTS notes_project_id_idx ON notes(project_id);
CREATE INDEX IF NOT EXISTS notes_parent_id_idx ON notes(parent_id);
