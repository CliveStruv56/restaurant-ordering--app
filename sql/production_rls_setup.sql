-- Production-ready RLS policies for users table
-- This avoids infinite recursion while maintaining proper security

-- First, re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to start clean
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "admins_select_all_users" ON users;
DROP POLICY IF EXISTS "admins_view_all_users" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "admins_update_all_users" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "admins_insert_users" ON users;
DROP POLICY IF EXISTS "admins_delete_users" ON users;

-- SOLUTION 1: Use auth.jwt() claims instead of querying users table
-- This requires setting role in JWT token during login

-- 1. Users can view their own profile
CREATE POLICY "users_view_own_profile" ON users
    FOR SELECT
    USING (auth.uid() = id);

-- 2. Users can update their own profile  
CREATE POLICY "users_update_own_profile" ON users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 3. Admins can view all users (using JWT role claim)
CREATE POLICY "admins_view_all_users" ON users
    FOR SELECT
    USING (
        auth.uid() = id  -- Users can see themselves
        OR 
        (auth.jwt() ->> 'role') = 'admin'  -- Admins can see everyone
    );

-- 4. Admins can update any user (using JWT role claim)
CREATE POLICY "admins_update_any_user" ON users
    FOR UPDATE
    USING ((auth.jwt() ->> 'role') = 'admin')
    WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

-- 5. Admins can insert new users (using JWT role claim)
CREATE POLICY "admins_insert_users" ON users
    FOR INSERT
    WITH CHECK ((auth.jwt() ->> 'role') = 'admin');

-- 6. Admins can delete users (except themselves)
CREATE POLICY "admins_delete_users" ON users
    FOR DELETE
    USING (
        (auth.jwt() ->> 'role') = 'admin'
        AND auth.uid() != id
    );

-- 7. Allow new user registration (for sign-up process)
CREATE POLICY "allow_user_registration" ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- IMPORTANT: This requires updating JWT tokens with role information
-- Add this function to update JWT with user role
CREATE OR REPLACE FUNCTION update_user_jwt_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the auth.users metadata with role information
    UPDATE auth.users 
    SET raw_app_meta_data = jsonb_set(
        COALESCE(raw_app_meta_data, '{}'),
        '{role}',
        to_jsonb(NEW.role)
    )
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically update JWT when role changes
DROP TRIGGER IF EXISTS update_jwt_role_trigger ON users;
CREATE TRIGGER update_jwt_role_trigger
    AFTER INSERT OR UPDATE OF role ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_user_jwt_role();