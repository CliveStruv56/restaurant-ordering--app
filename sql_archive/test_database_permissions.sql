-- TEST DATABASE PERMISSIONS AND DATA
-- Run this to check if data is being saved and if permissions are working

-- 1. Check if any option groups exist at all (bypass RLS)
SELECT 'CHECKING ALL OPTION GROUPS (BYPASS RLS):' as test_info;
SELECT id, name, selection_type, is_required, created_at 
FROM option_groups 
ORDER BY created_at DESC;

-- 2. Check current user and role
SELECT 'CURRENT USER INFO:' as test_info;
SELECT 
    auth.uid() as user_id,
    u.email,
    u.role,
    u.created_at
FROM users u 
WHERE u.id = auth.uid();

-- 3. Test RLS policy - try to select with current user context
SELECT 'TESTING RLS POLICIES:' as test_info;
SET row_security = on;
SELECT id, name, selection_type, is_required 
FROM option_groups 
ORDER BY created_at DESC;

-- 4. Check if we can insert (test the admin policy)
SELECT 'TESTING INSERT PERMISSIONS:' as test_info;
DO $$
BEGIN
    INSERT INTO option_groups (name, description, selection_type, is_required) 
    VALUES ('Test Group', 'Test description', 'single', false);
    
    RAISE NOTICE 'Insert successful - permissions are working';
    
    -- Clean up the test record
    DELETE FROM option_groups WHERE name = 'Test Group';
    RAISE NOTICE 'Test record cleaned up';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Insert failed - permission issue: %', SQLERRM;
END $$;

-- 5. Check table structure
SELECT 'CHECKING TABLE STRUCTURE:' as test_info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'option_groups' 
ORDER BY ordinal_position;

-- 6. Check if there are any constraints causing issues
SELECT 'CHECKING CONSTRAINTS:' as test_info;
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'option_groups'::regclass;