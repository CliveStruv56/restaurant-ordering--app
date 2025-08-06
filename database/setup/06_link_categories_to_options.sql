-- Link existing categories to their appropriate option groups
-- This script ensures categories are properly connected to options

-- First, let's see what categories we have
SELECT id, name FROM categories;

-- Let's also see what option groups we have
SELECT id, name FROM option_groups;

-- Now let's properly link them
DO $$
DECLARE
  beverages_category_id UUID;
  mains_category_id UUID;
  milk_group_id UUID;
  size_group_id UUID;
  extras_group_id UUID;
  cooking_group_id UUID;
  sides_group_id UUID;
  dietary_group_id UUID;
BEGIN
  -- Get category IDs
  SELECT id INTO beverages_category_id FROM categories 
  WHERE LOWER(name) LIKE '%beverage%' OR LOWER(name) LIKE '%drink%' OR LOWER(name) LIKE '%coffee%'
  LIMIT 1;
  
  SELECT id INTO mains_category_id FROM categories 
  WHERE LOWER(name) LIKE '%main%' OR LOWER(name) LIKE '%entree%' OR LOWER(name) LIKE '%burger%'
  LIMIT 1;

  -- Get option group IDs
  SELECT id INTO milk_group_id FROM option_groups WHERE name = 'Milk Types';
  SELECT id INTO size_group_id FROM option_groups WHERE name = 'Coffee Sizes';
  SELECT id INTO extras_group_id FROM option_groups WHERE name = 'Coffee Extras';
  SELECT id INTO cooking_group_id FROM option_groups WHERE name = 'Cooking Preference';
  SELECT id INTO sides_group_id FROM option_groups WHERE name = 'Side Dishes';
  SELECT id INTO dietary_group_id FROM option_groups WHERE name = 'Dietary Options';

  -- Clear existing links to avoid duplicates
  DELETE FROM category_option_groups;

  -- Link beverages category to coffee options
  IF beverages_category_id IS NOT NULL THEN
    IF milk_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (beverages_category_id, milk_group_id, true, 1);
    END IF;
    
    IF size_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (beverages_category_id, size_group_id, true, 2);
    END IF;
    
    IF extras_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (beverages_category_id, extras_group_id, false, 3);
    END IF;
  END IF;

  -- Link mains category to main course options
  IF mains_category_id IS NOT NULL THEN
    IF cooking_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (mains_category_id, cooking_group_id, false, 1);
    END IF;
    
    IF sides_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (mains_category_id, sides_group_id, false, 2);
    END IF;
    
    IF dietary_group_id IS NOT NULL THEN
      INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order)
      VALUES (mains_category_id, dietary_group_id, false, 3);
    END IF;
  END IF;
END $$;

-- Show the results
SELECT 
  c.name as category_name,
  og.name as option_group_name,
  cog.is_required,
  cog.sort_order
FROM category_option_groups cog
JOIN categories c ON c.id = cog.category_id
JOIN option_groups og ON og.id = cog.option_group_id
ORDER BY c.name, cog.sort_order;