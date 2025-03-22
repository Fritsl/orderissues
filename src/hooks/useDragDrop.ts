import { useState } from 'react';
import { Note } from '../types';
import { useNoteStore } from '../store';

export const useDragDrop = (note: Note, onError: (error: Error) => void) => {
  const [isDragging, setIsDragging] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const [isParentTarget, setIsParentTarget] = useState(false);
  const [dropZone, setDropZone] = useState<'above' | 'below' | 'child' | null>(null);
  const { moveNote, currentLevel } = useNoteStore();

  const handleDragStart = (e: React.DragEvent) => {
    console.log('Drag started:', {
      noteId: note.id,
      noteContent: note.content.substring(0, 50),
      pos: note.position
    });
    e.dataTransfer.setData('text/plain', note.id);
    e.dataTransfer.effectAllowed = 'move';
    setIsDragging(true);
  };

  const handleDragEnd = () => {
    setIsDragging(false);
    setIsParentTarget(false);
    setDropZone(null);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';

    const rect = e.currentTarget.getBoundingClientRect();
    const isParentZone = e.clientX > rect.right - rect.width * 0.2;
    const relativeY = e.clientY - rect.top;

    setIsDragOver(true);
    setIsParentTarget(isParentZone);

    if (isParentZone) {
      setDropZone('child');
    } else {
      setDropZone(relativeY < rect.height / 2 ? 'above' : 'below');
    }
  };

  const handleDragLeave = (e: React.DragEvent) => {
    if (!e.currentTarget.contains(e.relatedTarget as Node)) {
      setIsDragOver(false);
      setIsParentTarget(false);
      setDropZone(null);
    }
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    setIsParentTarget(false);

    const draggedId = e.dataTransfer.getData('text/plain');
    if (draggedId === note.id) return;

    try {
      const rect = e.currentTarget.getBoundingClientRect();
      const isParentZone = e.clientX > rect.right - rect.width * 0.2;
      const targetPos = parseInt((e.currentTarget as HTMLElement).getAttribute('data-pos') || '0');
      const position = e.clientY < rect.top + rect.height / 2 ? targetPos : targetPos + 1;

      console.log('Drop detected:', {
        draggedId,
        targetId: note.id,
        isParentZone,
        newPos: position,
        mouseY: e.clientY < rect.top + rect.height / 2 ? 'above' : 'below'
      });

      if (isParentZone) {
        console.log('Moving note as child:', { draggedId, newParentId: note.id, pos: 0, level: note.level + 1 });
        moveNote(draggedId, note.id, 0, note.level + 1);
      } else {
        const draggedNote = document.getElementById(draggedId)?.getAttribute('data-level');
        const targetLevel = draggedNote ? parseInt(draggedNote) : note.level;
        console.log('Moving note as sibling:', { draggedId, parentId: note.parent_id, pos: position, level: targetLevel });
        moveNote(draggedId, note.parent_id, position, targetLevel);
      }

      // Force immediate UI update
      requestAnimationFrame(() => {
        const element = document.getElementById(draggedId);
        if (element) {
          element.style.transition = 'transform 0.2s ease-out';
          element.style.transform = 'scale(1.02)';
          setTimeout(() => {
            element.style.transform = 'scale(1)';
          }, 200);
        }
      });

    } catch (error) {
      console.error('Drop error:', error);
      onError(error as Error);
    }

    setDropZone(null);
  };

  return {
    isDragging,
    isDragOver,
    isParentTarget,
    dropZone,
    draggedNote: note,
    handleDragStart,
    handleDragEnd,
    handleDragOver,
    handleDragLeave,
    handleDrop,
    setIsDragOver,
    setDropZone
  };
};