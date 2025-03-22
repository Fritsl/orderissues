
import { useCallback } from 'react';
import { useNoteStore } from '../store';
import { Note } from '../types';

export const useNoteReorder = () => {
  const notes = useNoteStore(state => state.notes);
  const setNotes = useNoteStore(state => state.setNotes);

  const reorderNotes = useCallback((draggedId: string, targetId: string, position: 'before' | 'after') => {
    console.log('Reordering notes:', { draggedId, targetId, position });
    const newNotes = [...notes];
    
    // Find indices
    const draggedNote = newNotes.find(n => n.id === draggedId);
    const targetNote = newNotes.find(n => n.id === targetId);
    
    console.log('Found notes:', { 
      draggedNote: draggedNote ? { id: draggedNote.id, content: draggedNote.content } : null,
      targetNote: targetNote ? { id: targetNote.id, content: targetNote.content } : null
    });
    
    if (!draggedNote || !targetNote) {
      console.warn('Missing notes for reorder:', { draggedNote, targetNote });
      return;
    }
    
    // Remove dragged note
    const filteredNotes = newNotes.filter(n => n.id !== draggedId);
    
    // Find target index
    const targetIndex = filteredNotes.findIndex(n => n.id === targetId);
    const insertIndex = position === 'after' ? targetIndex + 1 : targetIndex;
    
    // Insert note at new position
    filteredNotes.splice(insertIndex, 0, draggedNote);
    
    // Update store
    setNotes(filteredNotes);
  }, [notes, setNotes]);

  return { reorderNotes };
};
