-- TEST SCRIPT: Verify entire options flow works
-- This will test the complete chain from menu items to options

-- 1. First, let's see what menu items exist and their categories
SELECT 'MENU ITEMS AND CATEGORIES:' as test_section;
SELECT 
    mi.id as menu_item_id,
    mi.name as menu_item_name,
    mi.category_id,
    c.name as category_name
FROM menu_items mi
LEFT JOIN categories c ON mi.category_id = c.id
ORDER BY c.name, mi.name
LIMIT 10;

-- 2. Check what option groups exist
SELECT 'OPTION GROUPS:' as test_section;
SELECT id, name, selection_type, is_required, created_at 
FROM option_groups 
ORDER BY created_at;

-- 3. Check what options exist
SELECT 'OPTIONS:' as test_section;
SELECT 
    o.id,
    o.name,
    og.name as group_name,
    o.price_adjustment,
    o.is_default
FROM options o
JOIN option_groups og ON o.option_group_id = og.id
ORDER BY og.name, o.sort_order
LIMIT 20;

-- 4. Check category-option group mappings
SELECT 'CATEGORY OPTION MAPPINGS:' as test_section;
SELECT 
    c.name as category_name,
    og.name as option_group_name,
    cog.is_required,
    cog.sort_order
FROM category_option_groups cog
JOIN categories c ON cog.category_id = c.id
JOIN option_groups og ON cog.option_group_id = og.id
ORDER BY c.name, cog.sort_order;

-- 5. Test the RPC function with a real menu item
SELECT 'RPC FUNCTION TEST:' as test_section;
DO $$
DECLARE
    test_menu_item_id UUID;
BEGIN
    -- Get the first menu item
    SELECT id INTO test_menu_item_id FROM menu_items LIMIT 1;
    
    IF test_menu_item_id IS NOT NULL THEN
        RAISE NOTICE 'Testing RPC function with menu item ID: %', test_menu_item_id;
        
        -- Test the function
        PERFORM get_menu_item_options(test_menu_item_id);
        RAISE NOTICE 'RPC function executed successfully';
    ELSE
        RAISE NOTICE 'No menu items found to test with';
    END IF;
END $$;

-- 6. Actually call the RPC function to see results
SELECT 'RPC FUNCTION RESULTS:' as test_section;
SELECT * FROM get_menu_item_options(
    (SELECT id FROM menu_items LIMIT 1)
) LIMIT 10;

-- 7. Check if any menu items are linked to categories that have option groups
SELECT 'MENU ITEMS WITH AVAILABLE OPTIONS:' as test_section;
SELECT DISTINCT
    mi.id as menu_item_id,
    mi.name as menu_item_name,
    c.name as category_name,
    COUNT(cog.id) as option_groups_count
FROM menu_items mi
JOIN categories c ON mi.category_id = c.id
JOIN category_option_groups cog ON c.id = cog.category_id
GROUP BY mi.id, mi.name, c.name
ORDER BY option_groups_count DESC;