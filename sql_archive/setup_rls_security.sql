-- COMPREHENSIVE RLS SECURITY SETUP
-- This script sets up proper Row Level Security for all tables

-- ============================================
-- STEP 1: Enable RLS on missing tables
-- ============================================

-- Enable RLS on available_timeslots
ALTER TABLE available_timeslots ENABLE ROW LEVEL SECURITY;

-- Note: category_options_view is a VIEW, not a table, so RLS is handled by underlying tables

-- ============================================
-- STEP 2: Drop existing policies if they exist (to avoid conflicts)
-- ============================================

-- Available timeslots policies
DROP POLICY IF EXISTS "Allow public read access to available_timeslots" ON available_timeslots;
DROP POLICY IF EXISTS "Allow admin users to manage available_timeslots" ON available_timeslots;

-- ============================================
-- STEP 3: Create RLS policies for available_timeslots
-- ============================================

-- Public read access (customers need to see available times)
CREATE POLICY "Allow public read access to available_timeslots" ON available_timeslots
  FOR SELECT USING (true);

-- Admin management access (only admins can create/update/delete timeslots)
CREATE POLICY "Allow admin users to manage available_timeslots" ON available_timeslots
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 4: Verify and enhance other table RLS policies
-- ============================================

-- Check and enhance users table (if not already secured)
DO $$
BEGIN
  -- Enable RLS if not already enabled
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'users' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Drop and recreate users policies for consistency
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Allow admin users to manage all users" ON users;

-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Admins can manage all users
CREATE POLICY "Allow admin users to manage all users" ON users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 5: Enhance menu-related RLS policies
-- ============================================

-- Menu items - public read, admin manage
DROP POLICY IF EXISTS "Allow public read access to menu_items" ON menu_items;
DROP POLICY IF EXISTS "Allow admin users to manage menu_items" ON menu_items;

CREATE POLICY "Allow public read access to menu_items" ON menu_items
  FOR SELECT USING (is_available = true);

CREATE POLICY "Allow admin users to manage menu_items" ON menu_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Categories - public read, admin manage
DROP POLICY IF EXISTS "Allow public read access to categories" ON categories;
DROP POLICY IF EXISTS "Allow admin users to manage categories" ON categories;

CREATE POLICY "Allow public read access to categories" ON categories
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage categories" ON categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 6: Secure order-related tables
-- ============================================

-- Orders - users see own orders, admins see all
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
DROP POLICY IF EXISTS "Users can create own orders" ON orders;
DROP POLICY IF EXISTS "Allow admin users to manage all orders" ON orders;

CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders" ON orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow admin users to manage all orders" ON orders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Order items - linked to user's orders
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;
DROP POLICY IF EXISTS "Allow admin users to manage all order items" ON order_items;

CREATE POLICY "Users can view own order items" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own order items" ON order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Allow admin users to manage all order items" ON order_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 7: Secure restaurant settings
-- ============================================

-- Restaurant settings - public read, admin manage
DROP POLICY IF EXISTS "Allow public read access to restaurant_settings" ON restaurant_settings;
DROP POLICY IF EXISTS "Allow admin users to manage restaurant_settings" ON restaurant_settings;

CREATE POLICY "Allow public read access to restaurant_settings" ON restaurant_settings
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage restaurant_settings" ON restaurant_settings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Opening hours - public read, admin manage
DROP POLICY IF EXISTS "Allow public read access to opening_hours" ON opening_hours;
DROP POLICY IF EXISTS "Allow admin users to manage opening_hours" ON opening_hours;

CREATE POLICY "Allow public read access to opening_hours" ON opening_hours
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage opening_hours" ON opening_hours
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Timeslots - public read, admin manage
DROP POLICY IF EXISTS "Allow public read access to timeslots" ON timeslots;
DROP POLICY IF EXISTS "Allow admin users to manage timeslots" ON timeslots;

CREATE POLICY "Allow public read access to timeslots" ON timeslots
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage timeslots" ON timeslots
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 8: Security verification
-- ============================================

-- Check RLS status for all tables
SELECT 'RLS STATUS CHECK:' as status;
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  hasoids
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE 'pg_%'
ORDER BY tablename;

-- Check policies
SELECT 'POLICY COUNT BY TABLE:' as status;
SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- List all policies
SELECT 'ALL POLICIES:' as status;
SELECT 
  tablename,
  policyname,
  permissive,
  cmd,
  qual IS NOT NULL as has_using_clause,
  with_check IS NOT NULL as has_check_clause
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT 'RLS SECURITY SETUP COMPLETE!' as final_status;