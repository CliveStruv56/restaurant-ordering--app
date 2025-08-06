-- Setup Existing Users
-- Run this in your Supabase SQL Editor

-- First, let's see what users exist in auth.users
SELECT id, email, created_at FROM auth.users;

-- Create profiles for existing auth users who don't have profiles yet
INSERT INTO public.users (id, email, full_name, role, created_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', SPLIT_PART(au.email, '@', 1)) as full_name,
  'customer' as role,
  au.created_at
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- Check the results
SELECT * FROM public.users;

-- To make a user an admin, run this (replace with actual user email):
-- UPDATE public.users 
-- SET role = 'admin' 
-- WHERE email = 'your-admin-email@example.com';

-- To make a user staff:
-- UPDATE public.users 
-- SET role = 'staff' 
-- WHERE email = 'staff-email@example.com';

-- View all users with their roles
SELECT email, full_name, role, created_at FROM public.users ORDER BY created_at DESC; 