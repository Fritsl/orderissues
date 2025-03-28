import { StateCreator } from 'zustand';
import { Store } from '../types';
import { findNoteById, removeNoteById } from '../../utils';
import { supabase } from '../../supabase';
import { handleDatabaseError } from '../../errors';
import { produce } from 'immer';

export interface Store {
  notes: Note[];
  title: string;
  isEditMode: boolean;
  setNotes: (notes: Note[]) => void; // Added setNotes function
}

export const createNoteSlice: StateCreator<Store> = (set, get) => ({
  notes: [],
  isEditMode: false,
  setNotes: (notes) => set({ notes }), // Added setNotes implementation
  undoStack: [],
  canUndo: false,
  lastUndoAction: null,
  expandedNotes: new Set<string>(),
  currentLevel: 0,
  canExpandMore: false,
  canCollapseMore: false,
  isImporting: false, // Added import flag
  setIsImporting: (value: boolean) => set({ isImporting: value }),

  undo: async () => {
    const { undoStack } = get();
    if (undoStack.length > 0) {
      const command = undoStack[undoStack.length - 1];
      await command.undo();
      set(state => ({
        undoStack: state.undoStack.slice(0, -1),
        canUndo: state.undoStack.length > 1,
        lastUndoAction: state.undoStack.length > 1 ? state.undoStack[state.undoStack.length - 2].description : null
      }));
    }
  },

  moveNote: (id: string, newParentId: string | null, newPosition: number, newLevel: number) => {
      console.log('moveNote called:', { id, newParentId, newPosition, newLevel });
      set(state => {
        const draggedNote = state.notes.find(n => n.id === id);
        if (!draggedNote) return state;

        // Create new array without the dragged note
        let updatedNotes = state.notes.filter(n => n.id !== id);

        // Preserve the original level of the note
        const updatedDraggedNote = {
          ...draggedNote,
          position: newPosition
        };

        // Insert the note at the new position
        updatedNotes.splice(newPosition, 0, updatedDraggedNote);

        // Update positions of all notes at the same level
        updatedNotes = updatedNotes.map((note, index) => ({
          ...note,
          position: index
        }));

        return {
          notes: updatedNotes
        };
      });
    },

  deleteNote: async (id: string) => {
    try {

      // First get the note to check project_id
      const { data: note, error: noteError } = await supabase
        .from('notes')
        .select('project_id')
        .eq('id', id)
        .single();


      if (noteError) throw noteError;
      if (!note) throw new Error('Note not found');

      // Call RPC function

      const { error: deleteError } = await supabase
        .rpc('delete_note_safely', { note_id: id });

      if (deleteError) throw deleteError;

      set(state => ({
        notes: removeNoteById(state.notes, id)
      }));

      // Update project's note count in state
      set(state => ({
        projects: state.projects.map(p =>
          p.id === note.project_id
            ? { ...p, note_count: Math.max(0, (p.note_count || 0) - 1) }
            : p
        )
      }));

    } catch (error) {
      console.error('Error in deleteNote:', {
        error,
        noteId: id,
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        errorStack: error instanceof Error ? error.stack : undefined
      });
      throw handleDatabaseError(error, 'Failed to delete note');
    }
  },

  addNote: async (parentId: string | null = null, content: string = '') => {
    try {
      const user = await database.auth.getCurrentUser();
      const projectId = await database.projects.getCurrentProjectId();
      if (!projectId) return;

      const noteId = await database.notes.create(user.id, projectId, parentId, content);

      const newNote = {
        id: noteId,
        content: content,
        children: [],
        isEditing: !get().isImporting, // Only edit if not importing
        unsavedContent: '',
        user_id: user.id,
        project_id: projectId,
        is_discussion: false,
        parent_id: parentId,
        images: []
      };

      set(state => {
        if (!parentId) {
          return { notes: [...state.notes, newNote] };
        }

        const updateChildren = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === parentId) {
              return { ...note, children: [...note.children, newNote] };
            }
            return { ...note, children: updateChildren(note.children) };
          });
        };

        return { notes: updateChildren(state.notes) };
      });
      return newNote;
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to add note');
    }
  },

  updateNote: (id: string, content: string) => {
    set(state => {
      const updateNoteContent = (notes: Store['notes']): Store['notes'] => {
        return notes.map(note => {
          if (note.id === id) {
            // Only update unsavedContent, don't trigger save
            return { 
              ...note, 
              unsavedContent: content,
              content: note.content // Preserve original content
            };
          }
          if (note.children.length > 0) {
            return { ...note, children: updateNoteContent(note.children) };
          }
          return note;
        });
      };
      return { notes: updateNoteContent(state.notes) };
    });
  },

  saveNote: async (id: string) => {
    const note = findNoteById(get().notes, id);

    // Handle empty new notes
    if (note?.content === '' && !note?.unsavedContent) {
      await database.notes.delete(id);
      set(state => ({ notes: removeNoteById(state.notes, id) }));
      return;
    }

    // Only save if there are actual changes
    if (note && note.unsavedContent !== undefined && note.unsavedContent !== note.content) {
      try {
        await database.notes.update(id, note.unsavedContent);
        set(state => {
          const updateNoteContent = (notes: Store['notes']): Store['notes'] => {
            return notes.map(n => {
              if (n.id === id) {
                return { ...n, content: note.unsavedContent, unsavedContent: undefined };
              }
              if (n.children.length > 0) {
                return { ...n, children: updateNoteContent(n.children) };
              }
              return n;
            });
          };
          return { notes: updateNoteContent(state.notes) };
        });
      } catch (error) {
        throw handleDatabaseError(error, 'Failed to save note');
      }
    }
  },

  toggleEdit: (id: string) => {
    set(state => {
      const updateNoteEdit = (notes: Store['notes']): Store['notes'] => {
        return notes.map(note => {
          if (note.id === id) {
            const newIsEditing = !note.isEditing;
            set(state => ({ ...state, isEditMode: newIsEditing }));
            return { ...note, isEditing: newIsEditing };
          }
          if (note.children.length > 0) {
            return { ...note, children: updateNoteEdit(note.children) };
          }
          return note;
        });
      };
      return {
        notes: updateNoteEdit(state.notes)
      };
    });
  },

  setCurrentLevel: (level: number) => {
    console.log('setCurrentLevel called with level:', level);
    console.log('Stack trace:', new Error().stack);
    const state = get();
    const treeDepth = Math.max(...state.notes.map(note => {
      let depth = 0;
      const traverse = (note: Store['notes'][0], currentDepth = 0) => {
        depth = Math.max(depth, currentDepth);
        note.children.forEach(child => traverse(child, currentDepth + 1));
      };
      traverse(note);
      return depth;
    }));

    const newLevel = Math.max(0, Math.min(level, treeDepth));
    console.log('Setting level to:', newLevel, 'from original:', level);
    const newExpandedNotes = new Set(state.expandedNotes);

    const updateExpanded = (notes: Store['notes'], currentDepth = 0) => {
      notes.forEach(note => {
        if (note.children.length > 0) {
          if (currentDepth < newLevel) {
            newExpandedNotes.add(note.id);
          } else {
            newExpandedNotes.delete(note.id);
          }
          updateExpanded(note.children, currentDepth + 1);
        }
      });
    };

    updateExpanded(state.notes);

    // Save the level to the database
    const saveLevel = async () => {
      try {
        // Save level to localStorage instead since we don't need database persistence for this
        localStorage.setItem('currentLevel', newLevel.toString());
      } catch (error) {
        console.error('Failed to save level:', error);
      }
    };
    saveLevel();

    set({
      expandedNotes: newExpandedNotes,
      currentLevel: newLevel,
      canExpandMore: newLevel < treeDepth,
      canCollapseMore: newLevel > 0
    });
  },

  expandOneLevel: () => {
    const state = get();
    return state.setCurrentLevel(state.currentLevel + 1);
  },

  collapseOneLevel: () => {
    const state = get();
    return state.setCurrentLevel(state.currentLevel - 1);
  },

  setEditMode: (isEditing: boolean) => set({ isEditMode: isEditing }),

  addImage: async (noteId: string, url: string) => {
    try {
      const image = await database.images.add(noteId, url);

      set(state => {
        const updateNoteImages = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === noteId) {
              return {
                ...note,
                images: [...(note.images || []), image]
              };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteImages(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteImages(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to add image');
    }
  },

  removeImage: async (noteId: string, imageId: string) => {
    try {
      await database.images.remove(imageId);

      set(state => {
        const updateNoteImages = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === noteId) {
              return {
                ...note,
                images: (note.images || []).filter(img => img.id !== imageId)
              };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteImages(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteImages(state.notes)
        };
      });

    } catch (error) {
      console.error('Error removing image:', error);
      throw handleDatabaseError(error, 'Failed to remove image');
    }
  },

  moveImage: async (noteId: string, imageId: string, newPosition: number) => {
    try {
      await database.images.move(noteId, imageId, newPosition);

      // Get updated note data to ensure correct order
      const { data: updatedImages, error } = await supabase
        .from('note_images')
        .select('*')
        .eq('note_id', noteId)
        .order('position');

      if (error) throw error;

      set(state => {
        const updateNoteImages = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === noteId) {
              return { ...note, images: updatedImages };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteImages(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteImages(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to move image');
    }
  },

  toggleDiscussion: async (id: string, value: boolean) => {
    try {
      await database.notes.toggleDiscussion(id, value);
      set(state => {
        const updateNoteDiscussion = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === id) {
              return { ...note, is_discussion: value };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteDiscussion(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteDiscussion(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to toggle discussion');
    }
  },

  toggleTime: async (id: string, time: string | null) => {
    try {
      await database.notes.toggleTime(id, time);
      set(state => {
        const updateNoteTime = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === id) {
              return { ...note, time_set: time };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteTime(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteTime(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to set time');
    }
  },

  setYoutubeUrl: async (id: string, url: string | null) => {
    try {
      const { error } = await supabase
        .from('notes')
        .update({ youtube_url: url })
        .eq('id', id);

      if (error) throw error;

      set(state => {
        const updateNoteYoutube = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === id) {
              return { ...note, youtube_url: url };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteYoutube(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteYoutube(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to set YouTube URL');
    }
  },

  setUrl: async (id: string, url: string | null, displayText: string | null) => {
    try {
      const { error } = await supabase
        .from('notes')
        .update({ 
          url: url,
          url_display_text: displayText 
        })
        .eq('id', id);

      if (error) throw error;

      set(state => {
        const updateNoteUrl = (notes: Store['notes']): Store['notes'] => {
          return notes.map(note => {
            if (note.id === id) {
              return { 
                ...note, 
                url: url,
                url_display_text: displayText 
              };
            }
            if (note.children.length > 0) {
              return { ...note, children: updateNoteUrl(note.children) };
            }
            return note;
          });
        };

        return {
          notes: updateNoteUrl(state.notes)
        };
      });
    } catch (error) {
      throw handleDatabaseError(error, 'Failed to set URL');
    }
  },

  printNotes: () => {
    const { notes, expandedNotes } = get();
    let result = '';

    const formatNote = (note: Store['notes'][0], level = 0) => {
      const indent = '    '.repeat(level);
      result += `${indent}${note.content || 'Empty note...'}\n`;
      if (note.children.length > 0 && expandedNotes.has(note.id)) {
        note.children.forEach(child => formatNote(child, level + 1));
      }
    };

    notes.forEach(note => formatNote(note));
    return result;
  },

  importNotes: async (parsedNotes: any) => {
    try {
      if (!parsedNotes?.project?.notes?.note) {
        throw new Error('No valid notes to import');
      }

      set({ isImporting: true });

      const processNote = async (note: any, parentId?: string) => {
        const content = typeof note.content === 'string' ? note.content : note.content[0];

        const response = await get().addNote(parentId, content);

        if (response?.id) {
          if (note.$.time) await get().toggleTime(response.id, note.$.time);
          if (note.$.youtube) await get().setYoutubeUrl(response.id, note.$.youtube);
          if (note.$.discussion === 'true') await get().toggleDiscussion(response.id, true);
          if (note.$.url) await get().setUrl(response.id, note.$.url, note.$['url-text']);
        }
        if (note.note) {
          await Promise.all(note.note.map(child => processNote(child, response?.id)));
        }
      };

      await Promise.all(parsedNotes.project.notes.note.map(note => processNote(note)));
      set({ isImporting: false });
    } catch (error) {
      set({ isImporting: false });
      throw handleDatabaseError(error, 'Failed to import notes');
    }
  }
});