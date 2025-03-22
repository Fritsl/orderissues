import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';

export function PayoffEditor() {
  const [payoff, setPayoff] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    const loadPayoff = async () => {
      try {
        setIsLoading(true);
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        if (currentUser?.user_metadata?.payoff) {
          setPayoff(currentUser.user_metadata.payoff);
        }
      } catch (err) {
        console.error('Failed to load payoff:', err);
        setError('Failed to load payoff');
      } finally {
        setIsLoading(false);
      }
    };

    loadPayoff();
  }, [user?.id]); // Reload when user changes

  const handleSave = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const trimmedPayoff = payoff.trim();

      // Update the payoff in the database
      const { error } = await supabase.rpc('update_user_payoff', {
        p_payoff: trimmedPayoff
      });

      if (error) throw error;

      // Update local state
      setPayoff(trimmedPayoff);
      setIsEditing(false);

      // Refresh auth to get updated metadata
      await supabase.auth.refreshSession();

    } catch (err) {
      console.error('Failed to update payoff:', err);
      setError('Failed to update payoff');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="px-4 py-2 border-b border-gray-700">
        <div className="h-5 bg-gray-700 rounded animate-pulse"></div>
      </div>
    );
  }
  if (!isEditing) {
    return (
      <div 
        className="px-4 py-2 border-b border-gray-700 cursor-pointer hover:bg-gray-700"
        onClick={() => setIsEditing(true)}
      >
        <p className="text-sm text-gray-300">
          {payoff || 'Click to add payoff text'}
        </p>
      </div>
    );
  }

  return (
    <div className="px-4 py-2 border-b border-gray-700">
      <input
        type="text"
        value={payoff}
        onChange={(e) => setPayoff(e.target.value)}
        onBlur={handleSave}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            handleSave();
          }
          if (e.key === 'Escape') {
            setIsEditing(false);
          }
        }}
        className="w-full px-2 py-1 bg-gray-700 text-white rounded border border-gray-600 text-sm"
        placeholder="Enter your payoff text"
        maxLength={250}
        autoFocus />
      {error && (
        <p className="text-xs text-red-400 mt-1">{error}</p>
      )}
    </div>
  );
}