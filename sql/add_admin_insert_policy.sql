-- Minimal fix: Just add the missing admin insert policy
-- This is the safest approach if you want to keep existing policies

-- Check current policies first
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users' AND cmd = 'INSERT';

-- Drop the specific policy if it exists to avoid conflicts
DROP POLICY IF EXISTS "admins_insert_users" ON users;

-- Add the key policy that allows admins to create users
CREATE POLICY "admins_insert_users" ON users
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- Verify the policy was created
SELECT 
    policyname,
    cmd,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'admins_insert_users';