-- COMPREHENSIVE RLS SECURITY SETUP (FIXED)
-- This script sets up proper Row Level Security for all tables

-- ============================================
-- STEP 1: Identify tables vs views
-- ============================================

-- Check what available_timeslots actually is
SELECT 'OBJECT TYPES CHECK:' as status;
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('available_timeslots', 'category_options_view')
ORDER BY table_name;

-- ============================================
-- STEP 2: Only enable RLS on actual TABLES (not views)
-- ============================================

-- Skip available_timeslots and category_options_view since they are views
-- Views inherit security from their underlying tables

-- ============================================
-- STEP 3: Verify and enhance table RLS policies
-- ============================================

-- Check and enhance users table (if not already secured)
DO $$
BEGIN
  -- Enable RLS if not already enabled and if it's a table
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND table_type = 'BASE TABLE'
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
-- STEP 4: Enhance menu-related RLS policies
-- ============================================

-- Enable RLS on menu tables if they exist and are tables
DO $$
BEGIN
  -- Menu items
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'menu_items' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
  END IF;
  
  -- Categories
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'categories' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

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
-- STEP 5: Secure order-related tables
-- ============================================

-- Enable RLS on order tables
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'orders' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'order_items' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

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
-- STEP 6: Secure restaurant settings
-- ============================================

-- Enable RLS on settings tables
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'restaurant_settings' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE restaurant_settings ENABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'opening_hours' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE opening_hours ENABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'timeslots' 
    AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE timeslots ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

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
-- STEP 7: Security verification
-- ============================================

-- Show which objects are tables vs views
SELECT 'TABLES VS VIEWS:' as status;
SELECT 
  table_name,
  table_type,
  CASE 
    WHEN table_type = 'BASE TABLE' THEN 'Can have RLS'
    WHEN table_type = 'VIEW' THEN 'Inherits from underlying tables'
    ELSE 'Other'
  END as rls_capability
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name NOT LIKE 'pg_%'
ORDER BY table_type, table_name;

-- Check RLS status for actual tables only
SELECT 'RLS STATUS FOR TABLES:' as status;
SELECT 
  t.table_name,
  COALESCE(pt.rowsecurity, false) as rls_enabled
FROM information_schema.tables t
LEFT JOIN pg_tables pt ON pt.tablename = t.table_name
WHERE t.table_schema = 'public' 
  AND t.table_type = 'BASE TABLE'
  AND t.table_name NOT LIKE 'pg_%'
ORDER BY t.table_name;

-- Check policies
SELECT 'POLICY COUNT BY TABLE:' as status;
SELECT 
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

SELECT 'RLS SECURITY SETUP COMPLETE!' as final_status;