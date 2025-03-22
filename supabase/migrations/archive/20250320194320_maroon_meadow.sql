/*
  # Fix user payoff update functionality

  1. Changes
    - Add proper validation to update_user_payoff function
    - Add length constraint for payoff text
    - Add proper error handling
    - Add function to get user payoff

  2. Details
    - Ensures payoff text is valid
    - Maintains data integrity
    - Improves error handling
*/

-- Drop existing function
DROP FUNCTION IF EXISTS update_user_payoff(uuid, text);

-- Create improved function with validation
CREATE OR REPLACE FUNCTION update_user_payoff(p_user_id uuid, p_payoff text)
RETURNS void AS $$
BEGIN
  -- Validate payoff length
  IF length(p_payoff) > 250 THEN
    RAISE EXCEPTION 'Payoff text cannot exceed 250 characters';
  END IF;

  -- Update user metadata with new payoff
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN raw_user_meta_data IS NULL THEN 
        jsonb_build_object('payoff', p_payoff)
      ELSE 
        raw_user_meta_data || jsonb_build_object('payoff', p_payoff)
    END
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get user payoff
CREATE OR REPLACE FUNCTION get_user_payoff(p_user_id uuid)
RETURNS text AS $$
BEGIN
  RETURN (
    SELECT (raw_user_meta_data->>'payoff')::text
    FROM auth.users
    WHERE id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;