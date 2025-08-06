-- Fix RLS policy to allow admins to view ALL users regardless of role
-- Current issue: admins can only see other admins, not customers/staff

-- Check current policies
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND cmd = 'SELECT';

-- Drop the restrictive policy that might be blocking customer/staff visibility
DROP POLICY IF EXISTS "admins_select_all_users" ON users;

-- Create a new policy that allows admins to see ALL users (any role)
CREATE POLICY "admins_view_all_users" ON users
    FOR SELECT
    USING (
        -- Allow users to see their own profile
        auth.uid() = id
        OR
        -- Allow admins to see ALL users (customers, staff, other admins)
        EXISTS (
            SELECT 1 FROM users admin_user 
            WHERE admin_user.id = auth.uid() 
            AND admin_user.role = 'admin'
        )
    );

-- Verify the new policy
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'admins_view_all_users';

-- Test query that should work now (run this to verify)
-- This should return all users when run as an admin
SELECT id, full_name, email, role, created_at 
FROM users 
ORDER BY created_at DESC;