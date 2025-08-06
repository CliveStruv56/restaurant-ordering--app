-- Check if options system tables exist
SELECT 'option_groups table exists' as status WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'option_groups'
);

SELECT 'options table exists' as status WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'options'
);

SELECT 'category_option_groups table exists' as status WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'category_option_groups'
);

-- Check if RPC function exists
SELECT 'get_menu_item_options function exists' as status WHERE EXISTS (
  SELECT FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_name = 'get_menu_item_options'
);

-- Count existing data
SELECT 'Option groups count: ' || COUNT(*) as info FROM option_groups;
SELECT 'Options count: ' || COUNT(*) as info FROM options;
SELECT 'Category option mappings count: ' || COUNT(*) as info FROM category_option_groups;