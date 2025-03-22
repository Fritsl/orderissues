
import { useCallback } from 'react';
import { useNoteStore } from '../store';
import { Note } from '../types';

export const useNoteReorder = () => {
  const notes = useNoteStore(state => state.notes);
  const setNotes = useNoteStore(state => state.setNotes);

  const reorderNotes = useCallback((draggedId: string, targetId: string, position: 'before' | 'after') => {
    console.log('Reordering notes:', { draggedId, targetId, position });
    
    // Find notes at their current positions
    const draggedNoteIndex = notes.findIndex(n => n.id === draggedId);
    const targetNoteIndex = notes.findIndex(n => n.id === targetId);
    
    if (draggedNoteIndex === -1 || targetNoteIndex === -1) {
      console.warn('Missing notes for reorder:', { draggedNoteIndex, targetNoteIndex });
      return;
    }

    // Create new array and remove dragged note
    const newNotes = [...notes];
    const [draggedNote] = newNotes.splice(draggedNoteIndex, 1);
    
    // Calculate insert position
    const insertIndex = position === 'after' ? 
      targetNoteIndex : 
      targetNoteIndex > draggedNoteIndex ? targetNoteIndex - 1 : targetNoteIndex;
    
    // Insert at new position
    newNotes.splice(insertIndex, 0, draggedNote);
    
    // Update store
    setNotes(newNotes);
    
    console.log('Reorder complete:', { 
      draggedNote: draggedNote.content,
      targetNote: notes[targetNoteIndex].content,
      newPosition: insertIndex
    });
  }, [notes, setNotes]);

  return { reorderNotes };
};
