const moveNote = async (noteId: string, newParentId: string | null, newPosition: number) => {
  try {
    console.log('Moving note:', {
      noteId,
      newParentId,
      newPosition,
    });

    const { data: notesBefore } = await supabase
      .from('notes')
      .select('id, position, parent_id')
      .order('position');
    console.log('Notes before move:', notesBefore);

    const result = await supabase.rpc('move_note', {
      p_note_id: noteId,
      p_new_parent_id: newParentId,
      p_new_position: newPosition,
    });
    console.log('Move result:', result);

    const { data: notesAfter } = await supabase
      .from('notes')
      .select('id, position, parent_id')
      .order('position');
    console.log('Notes after move:', notesAfter);
  } catch (error) {
    console.error('Error moving note:', error);
    // Handle error appropriately, e.g., display an error message to the user
  }
};