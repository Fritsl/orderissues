import { Note } from '../../types';

interface ExportedNote {
  id: string;
  content: string;
  position: number;
  is_discussion: boolean;
  time_set: string | null;
  youtube_url: string | null;
  url: string | null;
  url_display_text: string | null;
  children: ExportedNote[];
}

export const exportNotesToJson = (notes: Note[]): string => {
  const formatNote = (note: Note): ExportedNote => ({
    id: note.id,
    content: note.content,
    position: note.position || 0,
    is_discussion: note.is_discussion,
    time_set: note.time_set || null,
    youtube_url: note.youtube_url || null,
    url: note.url || null,
    url_display_text: note.url_display_text || null,
    children: note.children.map(formatNote)
  });

  return JSON.stringify({ notes: notes.map(formatNote) }, null, 2);
};