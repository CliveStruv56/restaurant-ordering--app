-- Remove foreign key constraint temporarily for demo user creation
-- This allows admin-created users without requiring auth.users entries

-- First, check what constraints exist
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass
AND contype = 'f';

-- Drop the foreign key constraint (common names in Supabase)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_foreign;
ALTER TABLE users DROP CONSTRAINT IF EXISTS public_users_id_fkey;

-- Verify constraints have been removed
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass;

-- Note: In production, you would instead:
-- 1. Use Supabase Auth Admin API to create real auth users
-- 2. Use database triggers to automatically create profile records
-- 3. Keep the foreign key constraint for data integrity

-- This removal is only for demo purposes to allow manual user creation