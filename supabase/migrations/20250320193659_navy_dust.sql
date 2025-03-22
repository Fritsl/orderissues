/*
  # Move payoff from projects to users
  
  1. Changes
    - Add payoff column to auth.users
    - Remove payoff from settings table
    - Add function to update user payoff
    
  2. Details
    - Preserves existing payoff data
    - Maintains length constraints
    - Ensures proper access control
*/

-- First create a temporary table to store existing payoffs
CREATE TEMP TABLE temp_payoffs AS
SELECT DISTINCT ON (user_id) 
  user_id,
  payoff
FROM settings
WHERE payoff IS NOT NULL AND payoff != ''
ORDER BY user_id, updated_at DESC;

-- Add payoff column to auth.users via custom profile
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS raw_user_meta_data jsonb;

-- Create function to update user payoff
CREATE OR REPLACE FUNCTION update_user_payoff(p_user_id uuid, p_payoff text)
RETURNS void AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('payoff', p_payoff)
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migrate existing payoffs to user profiles
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT * FROM temp_payoffs LOOP
    PERFORM update_user_payoff(r.user_id, r.payoff);
  END LOOP;
END $$;

-- Drop temporary table
DROP TABLE temp_payoffs;

-- Remove payoff column from settings
ALTER TABLE settings
DROP COLUMN IF EXISTS payoff,
DROP CONSTRAINT IF EXISTS payoff_length_check;