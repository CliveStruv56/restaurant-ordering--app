-- Fix RLS policies to allow admin user creation
-- This script addresses the "new row violates row-level security policy" error

-- First, let's see what policies exist
-- You can run this in Supabase SQL editor to check current policies:
-- SELECT * FROM pg_policies WHERE tablename = 'users';

-- Drop existing problematic policies that might be blocking user creation
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON users;

-- Create comprehensive RLS policies for users table
-- 1. Allow users to view their own profile
CREATE POLICY "users_select_own" ON users
    FOR SELECT
    USING (auth.uid() = id);

-- 2. Allow admins to view all users
CREATE POLICY "admins_select_all_users" ON users
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- 3. Allow users to update their own profile
CREATE POLICY "users_update_own" ON users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Allow admins to update any user
CREATE POLICY "admins_update_all_users" ON users
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- 5. Allow authenticated users to insert their own profile (for registration)
CREATE POLICY "users_insert_own" ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 6. Allow admins to insert new users (THIS IS THE KEY POLICY FOR ADMIN USER CREATION)
CREATE POLICY "admins_insert_users" ON users
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- 7. Allow admins to delete users (except themselves)
CREATE POLICY "admins_delete_users" ON users
    FOR DELETE
    USING (
        auth.uid() != id AND 
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- Ensure RLS is enabled on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO service_role;

-- Verify the policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;