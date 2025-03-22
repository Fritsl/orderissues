import React, { useState } from 'react';
import { X, Upload } from 'lucide-react';
import { useNoteStore } from '../store';
import { validateImportData } from '../lib/utils/import';

interface ImportJsonModalProps {
  onClose: () => void;
}

export function ImportJsonModal({ onClose }: ImportJsonModalProps) {
  const { addNote } = useNoteStore();
  const [error, setError] = useState<string | null>(null);
  const [jsonText, setJsonText] = useState('');

  const importNotes = async (notes: any[], parentId: string | null = null) => {
    for (const note of notes) {
      const newNote = await addNote(parentId, note.content);
      
      if (newNote) {
        // Update note properties
        if (note.is_discussion) {
          await useNoteStore.getState().toggleDiscussion(newNote.id, true);
        }
        if (note.time_set) {
          await useNoteStore.getState().toggleTime(newNote.id, note.time_set);
        }
        if (note.youtube_url) {
          await useNoteStore.getState().setYoutubeUrl(newNote.id, note.youtube_url);
        }
        if (note.url) {
          await useNoteStore.getState().setUrl(newNote.id, note.url, note.url_display_text);
        }

        // Import children recursively
        if (note.children && note.children.length > 0) {
          await importNotes(note.children, newNote.id);
        }
      }
    }
  };

  const handleImport = async () => {
    try {
      useNoteStore.getState().setIsImporting(true);
      
      if (!jsonText.trim()) {
        throw new Error('Please enter JSON data');
      }

      const jsonData = JSON.parse(jsonText);
      
      if (!validateImportData(jsonData)) {
        throw new Error('Invalid JSON format');
      }

      await importNotes(jsonData.notes);
      onClose();
    } catch (error) {
      console.error('Import error:', error);
      setError(error instanceof Error ? error.message : 'Failed to import notes');
    } finally {
      useNoteStore.getState().setIsImporting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl">
        <div className="flex items-center justify-between px-4 py-3 border-b">
          <h2 className="text-lg font-semibold text-gray-900">Import Notes from JSON</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        <div className="p-4">
          <textarea
            className="w-full h-96 px-3 py-2 text-sm font-mono bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder="Paste your JSON here..."
            value={jsonText}
            onChange={(e) => setJsonText(e.target.value)}
            spellCheck={false}
          />
          {error && (
            <p className="mt-2 text-sm text-red-600">{error}</p>
          )}
          <div className="mt-4 flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={handleImport}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Import
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}