-- DEEP DEBUG: Check Options System Status
-- Run this to see exactly what's in the database and identify issues

-- 1. Check if tables exist and have data
SELECT 'OPTION GROUPS TABLE:' as debug_info;
SELECT COUNT(*) as total_option_groups FROM option_groups;
SELECT * FROM option_groups ORDER BY created_at;

SELECT 'OPTIONS TABLE:' as debug_info;
SELECT COUNT(*) as total_options FROM options;
SELECT * FROM options ORDER BY created_at LIMIT 10;

SELECT 'CATEGORY OPTION GROUPS TABLE:' as debug_info;
SELECT COUNT(*) as total_category_mappings FROM category_option_groups;
SELECT * FROM category_option_groups;

-- 2. Check categories that exist
SELECT 'EXISTING CATEGORIES:' as debug_info;
SELECT id, name FROM categories ORDER BY name;

-- 3. Check RLS policies
SELECT 'RLS POLICIES CHECK:' as debug_info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('option_groups', 'options', 'category_option_groups');

-- 4. Test the RPC function
SELECT 'RPC FUNCTION TEST:' as debug_info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'get_menu_item_options';

-- 5. Check if view exists
SELECT 'VIEW CHECK:' as debug_info;
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name = 'category_options_view';

-- 6. Test a sample query that the app would make
SELECT 'SAMPLE APP QUERY:' as debug_info;
SELECT og.*, 
       (SELECT COUNT(*) FROM options WHERE option_group_id = og.id) as option_count
FROM option_groups og
ORDER BY sort_order;