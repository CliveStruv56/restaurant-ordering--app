-- CLEANUP CATEGORY OPTION MAPPINGS SCRIPT
-- This addresses the real duplicate issue: multiple mappings of the same category to the same option group

-- Step 1: Identify duplicate category-option mappings
SELECT 'DUPLICATE CATEGORY MAPPINGS IDENTIFIED:' as status;
SELECT 
    category_id,
    option_group_id,
    COUNT(*) as duplicate_count,
    ARRAY_AGG(id ORDER BY created_at) as mapping_ids
FROM category_option_groups 
GROUP BY category_id, option_group_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Show what these duplicates look like with names
SELECT 'DUPLICATE MAPPINGS WITH NAMES:' as status;
SELECT 
    c.name as category_name,
    og.name as option_group_name,
    COUNT(*) as duplicate_count
FROM category_option_groups cog
JOIN categories c ON c.id = cog.category_id
JOIN option_groups og ON og.id = cog.option_group_id
GROUP BY c.name, og.name, cog.category_id, cog.option_group_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 3: Clean up duplicate category mappings
DO $$
DECLARE
    duplicate_record RECORD;
    ids_to_delete UUID[];
    keep_id UUID;
    delete_count INTEGER := 0;
BEGIN
    -- Find and clean up duplicate category mappings
    FOR duplicate_record IN
        SELECT 
            category_id,
            option_group_id,
            ARRAY_AGG(id ORDER BY created_at) as mapping_ids
        FROM category_option_groups 
        GROUP BY category_id, option_group_id
        HAVING COUNT(*) > 1
    LOOP
        -- Keep the first (oldest) mapping, delete the rest
        keep_id := duplicate_record.mapping_ids[1];
        ids_to_delete := duplicate_record.mapping_ids[2:];
        
        RAISE NOTICE 'Cleaning up % duplicate mappings for category % -> option group % (keeping %)', 
            array_length(ids_to_delete, 1), duplicate_record.category_id, duplicate_record.option_group_id, keep_id;
        
        -- Delete the duplicate mappings
        DELETE FROM category_option_groups WHERE id = ANY(ids_to_delete);
        delete_count := delete_count + array_length(ids_to_delete, 1);
    END LOOP;
    
    RAISE NOTICE 'Deleted % duplicate category mappings', delete_count;
END $$;

-- Step 4: Verify cleanup
SELECT 'CLEANUP VERIFICATION:' as status;

-- Count total mappings
SELECT 'Category Mappings Count:' as info, COUNT(*) as count FROM category_option_groups;

-- Show unique mappings per category
SELECT 'Unique Mappings Per Category:' as info;
SELECT 
    c.name as category_name,
    COUNT(DISTINCT cog.option_group_id) as unique_option_groups
FROM categories c
LEFT JOIN category_option_groups cog ON c.id = cog.category_id
GROUP BY c.id, c.name
ORDER BY c.name;

-- Show final mapping details
SELECT 'Final Category-Option Mappings:' as info;
SELECT 
    c.name as category_name,
    og.name as option_group_name,
    cog.sort_order
FROM category_option_groups cog
JOIN categories c ON c.id = cog.category_id
JOIN option_groups og ON og.id = cog.option_group_id
ORDER BY c.name, cog.sort_order, og.name;

SELECT 'CATEGORY MAPPING CLEANUP COMPLETE!' as final_status;