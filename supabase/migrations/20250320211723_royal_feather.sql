/*
  # Add get_user_payoff function
  
  1. Changes
    - Add function to get user's payoff from metadata
    - Maintain security with SECURITY DEFINER
    - Return empty string if no payoff set
    
  2. Details
    - Allows third-party apps to fetch payoff
    - Maintains data privacy
    - Handles null cases gracefully
*/

-- Create function to get user payoff
CREATE OR REPLACE FUNCTION get_user_payoff(p_user_id uuid)
RETURNS text AS $$
BEGIN
  RETURN COALESCE(
    (
      SELECT (raw_user_meta_data->>'payoff')::text
      FROM auth.users
      WHERE id = p_user_id
    ),
    '' -- Return empty string if no payoff is set
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;