import React from 'react';
import { Folder, Trash, FolderPlus, Clock, Copy, FileText, Download, Upload, Undo, ExternalLink } from 'lucide-react';

interface MenuItemsProps {
  onShowProjects: () => void;
  onShowTrash: () => void;
  userEmail: string | undefined;
  onNewProject: () => void;
  onDuplicateProject: () => void;
  onShowTimedNotes: () => void;
  onImportJson: () => void;
  onCopyNotes: () => void;
  onExportJson: () => void;
  onSignOut: () => void;
  onClose: () => void;
  onEditDescription: () => void;
  onUndo: () => void;
  canUndo: boolean;
  lastUndoAction: string | null;
}

export const MenuItems: React.FC<MenuItemsProps> = ({
  onShowProjects,
  onShowTrash,
  onNewProject,
  onImportJson,
  onDuplicateProject,
  onShowTimedNotes,
  onCopyNotes,
  onExportJson,
  onSignOut,
  userEmail,
  onClose,
  onEditDescription,
  onUndo,
  canUndo,
  lastUndoAction,
}) => (
  <div className="fixed right-4 mt-2 w-64 bg-gray-800 rounded-lg shadow-lg py-1">
    {canUndo && (
      <button
        onClick={() => { onUndo(); onClose(); }}
        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
      >
        <Undo className="w-4 h-4" />
        <span className="flex-1 text-left">
          Undo{lastUndoAction ? `: ${lastUndoAction}` : ''}
        </span>
      </button>
    )}
    {canUndo && <div className="border-t border-gray-700 my-1"></div>}
    <button
      onClick={() => {
        onNewProject();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <FolderPlus className="w-4 h-4" />
      <span>New Project</span>
    </button>
    <a
      href="https://fastpresenterviwer.netlify.app"
      target="_self"
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <ExternalLink className="w-4 h-4" />
      <span>Open Viewer</span>
    </a>
    <button
      onClick={() => {
        onShowProjects();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Folder className="w-4 h-4" />
      <span>Projects</span>
    </button>
    <button
      onClick={() => {
        onDuplicateProject();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Copy className="w-4 h-4" />
      <span>Duplicate Project</span>
    </button>
    <button
      onClick={() => {
        onShowTimedNotes();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Clock className="w-4 h-4" />
      <span>View Timed Notes</span>
    </button>
    <div className="border-t border-gray-700 my-1"></div>
    <button
      onClick={() => {
        onCopyNotes();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <FileText className="w-4 h-4" />
      <span>Copy as Text</span>
    </button>
    <button
      onClick={() => {
        onExportJson();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Download className="w-4 h-4" />
      <span>Export as JSON</span>
    </button>
    <button
      onClick={() => {
        onImportJson();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Upload className="w-4 h-4" />
      <span>Import from JSON</span>
    </button>
    <div className="border-t border-gray-700 my-1"></div>

    <button
      onClick={() => {
        onEditDescription();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <FileText className="w-4 h-4" />
      <span>Edit Description</span>
    </button>

    <button
      onClick={() => {
        onShowTrash();
        onClose();
      }}
      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-700 transition-colors"
    >
      <Trash className="w-4 h-4" />
      <span>Trash</span>
    </button>
    {userEmail && (
      <div className="px-4 py-2 text-sm text-gray-400 border-t border-gray-700">
        <div className="truncate">{userEmail}</div>
        <button
          onClick={() => {
            onSignOut();
            onClose();
          }}
          className="text-red-400 hover:text-red-300 transition-colors mt-1"
        >
          Sign out
        </button>
      </div>
    )}
  </div>
);