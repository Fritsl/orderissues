import { useState } from 'react';
import { Note } from '../types';
import { useNoteStore } from '../store';

export const useDragDrop = (note: Note, onError: (error: Error) => void) => {
  const [isDragging, setIsDragging] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const [isParentTarget, setIsParentTarget] = useState(false);
  const [dropZone, setDropZone] = useState<'above' | 'below' | 'child' | null>(null); // Added dropZone state and 'child' option
  const { moveNote, currentLevel } = useNoteStore();

  const handleDragStart = (e: React.DragEvent) => {
    console.log('Drag started:', { noteId: note.id, noteContent: note.content });
    e.dataTransfer.setData('text/plain', note.id);
    e.dataTransfer.effectAllowed = 'move';
    setIsDragging(true);
  };

  const handleDragEnd = () => {
    console.log('Drag ended:', { noteId: note.id });
    setIsDragging(false);
    setIsParentTarget(false);
    setDropZone(null); // Reset dropZone on drag end
  };

  const handleDragOver = (e: React.DragEvent) => {
    console.log('Drag over:', { noteId: note.id, clientX: e.clientX, clientY: e.clientY });
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    const rect = e.currentTarget.getBoundingClientRect();
    const isParentZone = e.clientX > rect.right - rect.width * 0.3;
    const mouseY = e.clientY;
    const relativeY = mouseY - rect.top;

    setIsParentTarget(isParentZone);
    setIsDragOver(true);

    if (isParentZone) {
      setDropZone('child');
    } else {
      setDropZone(relativeY < rect.height / 2 ? 'above' : 'below');
    }
  };

  const handleDragLeave = () => {
    console.log('Drag leave:', { noteId: note.id });
    setIsDragOver(false);
    setIsParentTarget(false);
    setDropZone(null); // Reset dropZone on drag leave
  };

  const handleDrop = async (e: React.DragEvent) => {
    console.log('Drop:', { noteId: note.id, dropZone: dropZone });
    e.preventDefault();
    setIsDragOver(false);
    setIsParentTarget(false);
    setDropZone(null); // Reset dropZone after drop

    const rect = e.currentTarget.getBoundingClientRect();
    const isParentZone = e.clientX > rect.right - rect.width * 0.3;

    const draggedId = e.dataTransfer.getData('text/plain');
    if (draggedId === note.id) return;

    try {
      if (isParentZone) {
        await moveNote(draggedId, note.id, 0, currentLevel);
      } else {
        const newPosition = dropZone === 'above' ? note.position : note.position + 1;
        await moveNote(draggedId, note.parent_id, newPosition, currentLevel);
      }
    } catch (error) {
      console.error('Drop error:', error);
      onError(error as Error);
    }
  };

  return {
    isDragging,
    isDragOver,
    isParentTarget,
    dropZone,
    draggedNote: note, // Include draggedNote
    handleDragStart,
    handleDragEnd,
    handleDragOver,
    handleDragLeave,
    handleDrop,
    setIsDragOver
  };
};