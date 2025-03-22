import { supabase } from '../lib/supabase';

const moveNote = async (noteId: string, newParentId: string | null, newPosition: number) => {
  // Only update parent_id in database if moving to different parent
  if (newParentId !== null) {
    try {
      await supabase
        .from('notes')
        .update({ parent_id: newParentId })
        .eq('id', noteId);
    } catch (error) {
      console.error('Error updating note parent:', error);
    }
  }
};

export { moveNote };