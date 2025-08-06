-- Admin RLS Policies for Restaurant App
-- Run this in your Supabase SQL Editor

-- First, let's check if we have a users table with roles
-- If not, we'll create a simple policy based on authentication

-- Policy for menu_items table - Allow authenticated users to perform all operations
-- This is a simplified approach. In production, you'd want more granular control

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access to menu_items" ON menu_items;
DROP POLICY IF EXISTS "Allow authenticated users to manage menu_items" ON menu_items;

-- Create comprehensive policy for menu_items
CREATE POLICY "Allow authenticated users to manage menu_items" ON menu_items
  FOR ALL USING (auth.role() = 'authenticated');

-- Policy for categories table - Allow authenticated users to perform all operations
DROP POLICY IF EXISTS "Allow public read access to categories" ON categories;
DROP POLICY IF EXISTS "Allow authenticated users to manage categories" ON categories;

-- Create comprehensive policy for categories
CREATE POLICY "Allow authenticated users to manage categories" ON categories
  FOR ALL USING (auth.role() = 'authenticated');

-- Alternative: If you want to restrict to admin users only, you can use this approach:
-- (Uncomment and modify if you have a users table with role column)

/*
-- First, ensure the users table has the correct structure
-- This assumes you have a users table with a role column

-- Policy for menu_items - Admin only
CREATE POLICY "Allow admin users to manage menu_items" ON menu_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Policy for categories - Admin only  
CREATE POLICY "Allow admin users to manage categories" ON categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );
*/

-- For now, let's use the simpler approach that allows all authenticated users
-- This will work for testing and development 