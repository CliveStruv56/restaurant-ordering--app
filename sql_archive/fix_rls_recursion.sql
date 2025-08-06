-- FIX RLS INFINITE RECURSION
-- This fixes the circular reference in the users table policies

-- First, drop the problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Allow admin users to manage all users" ON users;

-- Create simpler, non-recursive policies for users table
-- Users can view and update their own profile (no recursion)
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- For admin access, we'll create a simpler policy that doesn't recurse
-- This assumes you have an admin check that doesn't involve querying the users table
CREATE POLICY "Allow admin users to manage all users" ON users
  FOR ALL USING (
    -- Check if user has admin role using a direct auth metadata check
    -- or use a simpler approach without table recursion
    auth.jwt() ->> 'role' = 'admin'
    OR
    -- Alternative: use a service role bypass (you can customize this)
    auth.role() = 'service_role'
  );

-- If the above doesn't work with your auth setup, use this simpler version:
-- Comment out the above policy and uncomment this one if needed:
/*
DROP POLICY IF EXISTS "Allow admin users to manage all users" ON users;
CREATE POLICY "Allow admin users to manage all users" ON users
  FOR ALL USING (false); -- Temporarily disable admin access via RLS
*/

SELECT 'RLS recursion fix applied!' as status;