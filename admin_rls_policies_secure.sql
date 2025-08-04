-- Secure Admin RLS Policies for Restaurant App
-- Run this in your Supabase SQL Editor

-- This version specifically checks for admin role in the users table

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public read access to menu_items" ON menu_items;
DROP POLICY IF EXISTS "Allow authenticated users to manage menu_items" ON menu_items;
DROP POLICY IF EXISTS "Allow admin users to manage menu_items" ON menu_items;

DROP POLICY IF EXISTS "Allow public read access to categories" ON categories;
DROP POLICY IF EXISTS "Allow authenticated users to manage categories" ON categories;
DROP POLICY IF EXISTS "Allow admin users to manage categories" ON categories;

-- Create read policy for menu_items (public access)
CREATE POLICY "Allow public read access to menu_items" ON menu_items
  FOR SELECT USING (true);

-- Create admin-only policy for menu_items (insert, update, delete)
CREATE POLICY "Allow admin users to manage menu_items" ON menu_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create read policy for categories (public access)
CREATE POLICY "Allow public read access to categories" ON categories
  FOR SELECT USING (true);

-- Create admin-only policy for categories (insert, update, delete)
CREATE POLICY "Allow admin users to manage categories" ON categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('menu_items', 'categories')
ORDER BY tablename, policyname; 