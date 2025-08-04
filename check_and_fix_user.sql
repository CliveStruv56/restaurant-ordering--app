-- Check and fix user profile for clive@platform91.com
-- Run this in your Supabase SQL Editor

-- First, let's see what users exist
SELECT '=== ALL USERS ===' as info;
SELECT id, email, full_name, role, created_at FROM public.users ORDER BY created_at DESC;

-- Check if clive@platform91.com exists in auth.users
SELECT '=== AUTH USERS ===' as info;
SELECT id, email, created_at FROM auth.users WHERE email = 'clive@platform91.com';

-- Check if clive@platform91.com has a profile in public.users
SELECT '=== USER PROFILE CHECK ===' as info;
SELECT id, email, full_name, role, created_at 
FROM public.users 
WHERE email = 'clive@platform91.com';

-- If no profile exists, create one (replace the UUID with the actual auth user ID)
-- You'll need to get the auth user ID from the query above
-- INSERT INTO public.users (id, email, full_name, role) 
-- VALUES (
--   'REPLACE_WITH_ACTUAL_AUTH_USER_ID',
--   'clive@platform91.com',
--   'Clive',
--   'admin'
-- );

-- To make clive@platform91.com an admin (if profile exists):
-- UPDATE public.users 
-- SET role = 'admin' 
-- WHERE email = 'clive@platform91.com';

-- Show final result
SELECT '=== FINAL RESULT ===' as info;
SELECT id, email, full_name, role, created_at 
FROM public.users 
WHERE email = 'clive@platform91.com'; 