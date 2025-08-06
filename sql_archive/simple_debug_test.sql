-- SIMPLE DEBUG TEST
-- Just check what's actually in the database

-- Check if any option groups exist (raw query)
SELECT COUNT(*) as total_option_groups FROM option_groups;

-- Show all option groups
SELECT id, name, selection_type, is_required, created_at FROM option_groups ORDER BY created_at DESC;

-- Check current user
SELECT auth.uid() as current_user_id;

-- Check if current user is admin
SELECT u.email, u.role FROM users u WHERE u.id = auth.uid();

-- Try to insert a test record manually
INSERT INTO option_groups (name, description, selection_type, is_required) 
VALUES ('Manual Test Group', 'Manually inserted for testing', 'single', false);

-- Check if it was inserted
SELECT COUNT(*) as count_after_insert FROM option_groups;

-- Clean up
DELETE FROM option_groups WHERE name = 'Manual Test Group';