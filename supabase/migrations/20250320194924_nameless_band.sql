/*
  # Add payoff support to user profiles
  
  1. Changes
    - Add function to update user payoff
    - Add function to get user payoff
    - Add proper validation
    
  2. Details
    - Stores payoff in user metadata
    - Validates payoff length
    - Provides easy access functions
*/

-- Create function to update user payoff
CREATE OR REPLACE FUNCTION update_user_payoff(p_payoff text)
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
  WHERE id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;