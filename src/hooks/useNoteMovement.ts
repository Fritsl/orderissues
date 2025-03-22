
import { Note } from '../types';
import { useNoteStore } from '../store';

export const useNoteMovement = (note: Note) => {
  const { notes, moveNote } = useNoteStore();
  
  // Get siblings at the same level
  const siblings = notes.filter(n => n.parent_id === note.parent_id);
  const currentIndex = siblings.findIndex(n => n.id === note.id);
  const maxIndex = siblings.length - 1;

  const handleMoveUp = () => {
    if (currentIndex > 0) {
      moveNote(note.id, note.parent_id, currentIndex - 1);
    }
  };

  const handleMoveDown = () => {
    if (currentIndex < maxIndex) {
      moveNote(note.id, note.parent_id, currentIndex + 1);
    }
  };

  return {
    handleMoveUp,
    handleMoveDown,
    currentIndex,
    maxIndex
  };
};
