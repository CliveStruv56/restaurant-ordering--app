-- Temporarily disable RLS for demo purposes
-- This will allow the user management system to work without recursion issues

-- Disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "admins_select_all_users" ON users;
DROP POLICY IF EXISTS "admins_view_all_users" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "admins_update_all_users" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "admins_insert_users" ON users;
DROP POLICY IF EXISTS "admins_delete_users" ON users;

-- Grant necessary permissions for demo
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO anon;

-- Verify RLS is disabled
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE tablename = 'users';

-- This should now work without any restrictions
SELECT id, full_name, email, role, created_at 
FROM users 
ORDER BY created_at DESC;