import { Note } from '../../types';

interface ImportedNote {
  id?: string;
  content: string;
  position?: number;
  is_discussion?: boolean;
  time_set?: string | null;
  youtube_url?: string | null;
  url?: string | null;
  url_display_text?: string | null;
  children?: ImportedNote[];
}

interface ImportData {
  notes: ImportedNote[];
}

export const validateImportData = (data: unknown): data is ImportData => {
  if (!data || typeof data !== 'object') return false;
  if (!('notes' in data) || !Array.isArray((data as any).notes)) return false;
  
  const validateNote = (note: any): boolean => {
    if (!note || typeof note !== 'object') return false;
    if (typeof note.content !== 'string') return false;
    if (note.children && !Array.isArray(note.children)) return false;
    if (note.children) {
      return note.children.every(validateNote);
    }
    return true;
  };

  return (data as ImportData).notes.every(validateNote);
};