-- CHECK AND FIX RLS POLICIES
-- This script checks current policies and applies a more aggressive fix

-- Step 1: Check what policies currently exist
SELECT 'CURRENT POLICIES ON USERS TABLE:' as status;
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
WHERE schemaname = 'public' 
AND tablename = 'users'
ORDER BY policyname;

-- Step 2: Check if RLS is enabled
SELECT 'RLS STATUS:' as status;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- Step 3: Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Allow admin users to manage all users" ON users;
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON users;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON users;

-- Drop any other policies that might exist
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'users'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON users', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 4: Temporarily disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Step 5: Re-enable RLS with simple, non-recursive policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create minimal, non-recursive policies
CREATE POLICY "users_select_own" ON users
    FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
    FOR UPDATE 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Step 6: Check if orders table has recursive policies
SELECT 'CHECKING ORDERS TABLE POLICIES:' as status;
SELECT 
    policyname,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'orders'
AND qual LIKE '%users%';

-- Step 7: Fix orders table if needed
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
DROP POLICY IF EXISTS "Users can create own orders" ON orders;
DROP POLICY IF EXISTS "Allow admin users to manage all orders" ON orders;

-- Create simple orders policies without user table references
CREATE POLICY "orders_select_own" ON orders
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "orders_insert_own" ON orders
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Step 8: Fix order_items table
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;
DROP POLICY IF EXISTS "Allow admin users to manage all order items" ON order_items;

-- Create simple order_items policies
CREATE POLICY "order_items_select_own" ON order_items
    FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "order_items_insert_own" ON order_items
    FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Step 9: Verify final state
SELECT 'FINAL POLICY COUNT:' as status;
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('users', 'orders', 'order_items')
GROUP BY tablename;

SELECT 'RLS FIX COMPLETE!' as final_status;