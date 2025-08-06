-- FIX SCRIPT: Ensure proper linking between categories and option groups
-- This will manually link existing categories to the sample option groups

-- Step 1: Check what categories exist
SELECT 'Current categories:' as info;
SELECT id, name FROM categories ORDER BY name;

-- Step 2: Ensure we have some basic option groups (in case the sample data didn't insert)
INSERT INTO option_groups (name, description, selection_type, is_required, sort_order) VALUES
  ('Drink Sizes', 'Choose your drink size', 'single', true, 1),
  ('Milk Options', 'Choose your milk preference', 'single', false, 2),
  ('Add Extras', 'Add extras to your order', 'multiple', false, 3)
ON CONFLICT (name) DO NOTHING;

-- Step 3: Create some basic options for testing
DO $$
DECLARE
    sizes_group_id UUID;
    milk_group_id UUID;
    extras_group_id UUID;
BEGIN
    -- Get the group IDs
    SELECT id INTO sizes_group_id FROM option_groups WHERE name = 'Drink Sizes';
    SELECT id INTO milk_group_id FROM option_groups WHERE name = 'Milk Options';
    SELECT id INTO extras_group_id FROM option_groups WHERE name = 'Add Extras';
    
    -- Insert size options
    IF sizes_group_id IS NOT NULL THEN
        INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
            (sizes_group_id, 'Small', 'Small size', 0.00, false, 1),
            (sizes_group_id, 'Medium', 'Medium size', 0.50, true, 2),
            (sizes_group_id, 'Large', 'Large size', 1.00, false, 3)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Insert milk options
    IF milk_group_id IS NOT NULL THEN
        INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
            (milk_group_id, 'Regular Milk', 'Standard milk', 0.00, true, 1),
            (milk_group_id, 'Almond Milk', 'Dairy-free almond milk', 0.50, false, 2),
            (milk_group_id, 'Oat Milk', 'Creamy oat milk', 0.60, false, 3)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Insert extras
    IF extras_group_id IS NOT NULL THEN
        INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
            (extras_group_id, 'Extra Shot', 'Additional espresso shot', 0.75, false, 1),
            (extras_group_id, 'Whipped Cream', 'Fresh whipped cream', 0.50, false, 2),
            (extras_group_id, 'Extra Hot', 'Served extra hot', 0.00, false, 3)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Step 4: Link ALL categories to at least one option group for testing
DO $$
DECLARE
    category_record RECORD;
    sizes_group_id UUID;
BEGIN
    -- Get a basic option group ID
    SELECT id INTO sizes_group_id FROM option_groups WHERE name = 'Drink Sizes';
    
    IF sizes_group_id IS NOT NULL THEN
        -- Link every category to the sizes group for testing
        FOR category_record IN SELECT id, name FROM categories LOOP
            INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order) 
            VALUES (category_record.id, sizes_group_id, false, 1)
            ON CONFLICT (category_id, option_group_id) DO NOTHING;
            
            RAISE NOTICE 'Linked category % to Drink Sizes option group', category_record.name;
        END LOOP;
    END IF;
END $$;

-- Step 5: Verify the linking worked
SELECT 'Verification - Categories with option groups:' as info;
SELECT 
    c.name as category_name,
    og.name as option_group_name,
    COUNT(o.id) as options_count
FROM categories c
JOIN category_option_groups cog ON c.id = cog.category_id
JOIN option_groups og ON cog.option_group_id = og.id
LEFT JOIN options o ON og.id = o.option_group_id
GROUP BY c.name, og.name
ORDER BY c.name;

-- Step 6: Test the RPC function
SELECT 'Testing RPC function with first menu item:' as info;
SELECT * FROM get_menu_item_options(
    (SELECT id FROM menu_items LIMIT 1)
);