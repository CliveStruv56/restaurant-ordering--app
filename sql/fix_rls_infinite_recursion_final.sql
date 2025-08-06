-- Fix infinite recursion in RLS policies by using auth.jwt() instead of querying users table
-- This prevents the policy from querying the same table it's protecting

-- Drop ALL existing policies to start clean
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "admins_select_all_users" ON users;
DROP POLICY IF EXISTS "admins_view_all_users" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "admins_update_all_users" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "admins_insert_users" ON users;
DROP POLICY IF EXISTS "admins_delete_users" ON users;

-- Create non-recursive policies using auth.jwt() claims instead of querying users table

-- 1. Allow users to view their own profile
CREATE POLICY "users_select_own" ON users
    FOR SELECT
    USING (auth.uid() = id);

-- 2. Allow anyone with admin role in JWT to view all users (NO RECURSION)
CREATE POLICY "admins_select_all_users" ON users
    FOR SELECT
    USING (
        -- Check if the JWT token contains admin role
        (auth.jwt() ->> 'role') = 'admin'
        OR
        -- Fallback: allow users to see their own profile
        auth.uid() = id
    );

-- 3. Allow users to update their own profile
CREATE POLICY "users_update_own" ON users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Allow admins to update any user (NO RECURSION)
CREATE POLICY "admins_update_all_users" ON users
    FOR UPDATE
    USING ((auth.jwt() ->> 'role') = 'admin')
    WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

-- 5. Allow authenticated users to insert their own profile
CREATE POLICY "users_insert_own" ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 6. Allow admins to insert new users (NO RECURSION)
CREATE POLICY "admins_insert_users" ON users
    FOR INSERT
    WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

-- 7. Allow admins to delete users (NO RECURSION)
CREATE POLICY "admins_delete_users" ON users
    FOR DELETE
    USING (
        (auth.jwt() ->> 'role') = 'admin'
        AND auth.uid() != id  -- Can't delete themselves
    );

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Update the current user's JWT to include admin role
-- This is a workaround since we removed the foreign key constraint
UPDATE auth.users 
SET raw_app_meta_data = jsonb_set(
    COALESCE(raw_app_meta_data, '{}'),
    '{role}',
    '"admin"'
)
WHERE id = auth.uid();

-- Verify policies are created
SELECT 
    policyname,
    cmd,
    permissive,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;