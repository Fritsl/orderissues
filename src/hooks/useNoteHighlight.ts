import { useEffect } from 'react';
import { useNoteStore } from '../store';
import { findNoteById, findNoteParents } from '../lib/utils';

export const useNoteHighlight = () => {
  const { notes, expandedNotes, setCurrentLevel } = useNoteStore();

  useEffect(() => {
    const highlightNote = async () => {
      const urlParams = new URLSearchParams(window.location.search);
      const noteId = urlParams.get('note');

      if (!noteId || notes.length === 0) return;

      const note = findNoteById(notes, noteId);
      if (!note) return;

      // Find all parent notes
      const parents = findNoteParents(notes, noteId);
      if (!parents) return;

      // Calculate the note's depth level
      const noteLevel = parents.length;

      // Expand to the note's level plus one to show its children if any
      setCurrentLevel(noteLevel + 1);

      // Wait for state updates and DOM to reflect changes
      requestAnimationFrame(() => {
        const element = document.getElementById(noteId);
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
          element.classList.add('highlight-note');
          setTimeout(() => {
            element.classList.remove('highlight-note');
          }, 2000);
        }
      });
    };

    highlightNote();
  }, [notes, expandedNotes, setCurrentLevel]);
};