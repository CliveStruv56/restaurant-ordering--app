-- Script to make a user an admin
-- Run this in your Supabase SQL Editor

-- First, check if the users table exists and has the necessary columns
-- If not, this will create it
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  address TEXT,
  role TEXT DEFAULT 'customer',
  preferences JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Create policy for users to update their own data
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Create policy for admins to read all user data
CREATE POLICY "Admins can read all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Insert or update the current user to be an admin
-- Replace 'your-email@example.com' with your actual email
DO $$
DECLARE
  user_id UUID;
  user_email TEXT;
BEGIN
  -- Get the user ID for the email you want to make admin
  -- IMPORTANT: Replace this email with your actual email
  user_email := 'clive@platform91.com'; -- <-- CHANGE THIS TO YOUR EMAIL
  
  -- Get the user ID from auth.users
  SELECT id INTO user_id 
  FROM auth.users 
  WHERE email = user_email
  LIMIT 1;
  
  IF user_id IS NOT NULL THEN
    -- Insert or update the user in the users table
    INSERT INTO users (id, email, role)
    VALUES (user_id, user_email, 'admin')
    ON CONFLICT (id) 
    DO UPDATE SET 
      role = 'admin',
      email = EXCLUDED.email,
      updated_at = NOW();
    
    RAISE NOTICE 'User % has been granted admin role', user_email;
  ELSE
    RAISE NOTICE 'User with email % not found in auth.users', user_email;
  END IF;
END $$;

-- Verify the admin role was set
SELECT id, email, role, created_at, updated_at 
FROM users 
WHERE role = 'admin';

-- Also check if there are any users in the auth.users table
SELECT id, email, created_at 
FROM auth.users 
LIMIT 10;