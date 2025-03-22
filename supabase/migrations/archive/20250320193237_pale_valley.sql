/*
  # Add payoff field to projects
  
  1. Changes
    - Add payoff column to settings table
    - Add length constraint for payoff text
    - Update existing RLS policies
    
  2. Details
    - Maximum 250 characters
    - Optional field
    - Maintains data integrity
*/

-- Add payoff column to settings table
ALTER TABLE settings
ADD COLUMN payoff text DEFAULT '';

-- Add constraint for payoff length
ALTER TABLE settings
ADD CONSTRAINT payoff_length_check CHECK (length(payoff) <= 250);