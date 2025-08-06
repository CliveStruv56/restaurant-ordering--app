-- CLEANUP DUPLICATE OPTIONS SCRIPT
-- This will identify and remove duplicate options in the database

-- Step 1: Identify duplicate options
SELECT 'DUPLICATE OPTIONS IDENTIFIED:' as status;
SELECT 
    option_group_id,
    name,
    description,
    price_adjustment,
    COUNT(*) as duplicate_count,
    ARRAY_AGG(id) as option_ids
FROM options 
GROUP BY option_group_id, name, description, price_adjustment
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Identify duplicate option groups
SELECT 'DUPLICATE OPTION GROUPS IDENTIFIED:' as status;
SELECT 
    name,
    selection_type,
    is_required,
    COUNT(*) as duplicate_count,
    ARRAY_AGG(id) as group_ids
FROM option_groups 
GROUP BY name, selection_type, is_required
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 3: Clean up duplicate options (keep the first one, delete the rest)
DO $$
DECLARE
    duplicate_record RECORD;
    ids_to_delete UUID[];
    keep_id UUID;
    delete_count INTEGER := 0;
BEGIN
    -- Find and clean up duplicate options
    FOR duplicate_record IN
        SELECT 
            option_group_id,
            name,
            description,
            price_adjustment,
            ARRAY_AGG(id ORDER BY created_at) as option_ids
        FROM options 
        GROUP BY option_group_id, name, description, price_adjustment
        HAVING COUNT(*) > 1
    LOOP
        -- Keep the first (oldest) option, delete the rest
        keep_id := duplicate_record.option_ids[1];
        ids_to_delete := duplicate_record.option_ids[2:];
        
        RAISE NOTICE 'Cleaning up % duplicates for option: % (keeping %)', 
            array_length(ids_to_delete, 1), duplicate_record.name, keep_id;
        
        -- Delete the duplicate options
        DELETE FROM options WHERE id = ANY(ids_to_delete);
        delete_count := delete_count + array_length(ids_to_delete, 1);
    END LOOP;
    
    RAISE NOTICE 'Deleted % duplicate options', delete_count;
END $$;

-- Step 4: Clean up duplicate option groups (keep the first one, delete the rest)
DO $$
DECLARE
    duplicate_group RECORD;
    ids_to_delete UUID[];
    keep_id UUID;
    delete_count INTEGER := 0;
BEGIN
    FOR duplicate_group IN
        SELECT 
            name,
            selection_type,
            is_required,
            ARRAY_AGG(id ORDER BY created_at) as group_ids
        FROM option_groups 
        GROUP BY name, selection_type, is_required
        HAVING COUNT(*) > 1
    LOOP
        -- Keep the first (oldest) group, delete the rest
        keep_id := duplicate_group.group_ids[1];
        ids_to_delete := duplicate_group.group_ids[2:];
        
        RAISE NOTICE 'Cleaning up % duplicate option groups for: % (keeping %)', 
            array_length(ids_to_delete, 1), duplicate_group.name, keep_id;
        
        -- Update any category mappings to point to the kept group
        UPDATE category_option_groups 
        SET option_group_id = keep_id 
        WHERE option_group_id = ANY(ids_to_delete);
        
        -- Delete the duplicate groups (cascade will delete their options)
        DELETE FROM option_groups WHERE id = ANY(ids_to_delete);
        delete_count := delete_count + array_length(ids_to_delete, 1);
    END LOOP;
    
    RAISE NOTICE 'Deleted % duplicate option groups', delete_count;
END $$;

-- Step 5: Clean up duplicate category mappings
DELETE FROM category_option_groups 
WHERE id NOT IN (
    SELECT DISTINCT ON (category_id, option_group_id) id
    FROM category_option_groups
    ORDER BY category_id, option_group_id, created_at
);

-- Step 6: Verify cleanup
SELECT 'CLEANUP VERIFICATION:' as status;

SELECT 'Option Groups Count:' as info, COUNT(*) as count FROM option_groups;
SELECT 'Options Count:' as info, COUNT(*) as count FROM options;
SELECT 'Category Mappings Count:' as info, COUNT(*) as count FROM category_option_groups;

-- Show final option counts per group
SELECT 'Final Option Counts Per Group:' as info;
SELECT 
    og.name as group_name,
    COUNT(o.id) as option_count
FROM option_groups og
LEFT JOIN options o ON og.id = o.option_group_id AND o.is_available = true
GROUP BY og.id, og.name
ORDER BY og.name;