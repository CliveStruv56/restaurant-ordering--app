-- FLEXIBLE MENU OPTIONS SYSTEM
-- Supports beverages with milk types, main courses with sides, pizzas with toppings, etc.
-- Admin configurable with icons, defaults, and dependencies

-- ============================================
-- STEP 1: Create Option Groups Table
-- ============================================
CREATE TABLE IF NOT EXISTS option_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,                    -- "Milk Types", "Sizes", "Pizza Toppings"
  description TEXT,
  selection_type VARCHAR(20) DEFAULT 'single',   -- 'single' or 'multiple'
  is_required BOOLEAN DEFAULT false,             -- Must customer select from this group?
  sort_order INTEGER DEFAULT 0,                  -- Display order
  icon_url VARCHAR(500),                         -- Optional group icon
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 2: Create Options Table
-- ============================================
CREATE TABLE IF NOT EXISTS options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  option_group_id UUID NOT NULL REFERENCES option_groups(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,                    -- "Oat Milk", "Large", "Extra Cheese"
  description TEXT,
  price_adjustment DECIMAL(10,2) DEFAULT 0.00,  -- Price change (+/-)
  icon_url VARCHAR(500),                         -- Option icon/image
  is_available BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false,              -- Auto-selected by default
  depends_on_option_id UUID REFERENCES options(id), -- Show only if other option selected
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 3: Link Categories to Option Groups
-- ============================================
CREATE TABLE IF NOT EXISTS category_option_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  option_group_id UUID NOT NULL REFERENCES option_groups(id) ON DELETE CASCADE,
  is_required BOOLEAN DEFAULT false,             -- Required for this category?
  sort_order INTEGER DEFAULT 0,                  -- Display order within category
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(category_id, option_group_id)
);

-- ============================================
-- STEP 4: Create Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_options_group_id ON options(option_group_id);
CREATE INDEX IF NOT EXISTS idx_options_depends_on ON options(depends_on_option_id);
CREATE INDEX IF NOT EXISTS idx_category_option_groups_category ON category_option_groups(category_id);
CREATE INDEX IF NOT EXISTS idx_category_option_groups_option_group ON category_option_groups(option_group_id);

-- ============================================
-- STEP 5: Enable Row Level Security
-- ============================================
ALTER TABLE option_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE options ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_option_groups ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access to option_groups" ON option_groups;
DROP POLICY IF EXISTS "Allow public read access to options" ON options;
DROP POLICY IF EXISTS "Allow public read access to category_option_groups" ON category_option_groups;
DROP POLICY IF EXISTS "Allow admin users to manage option_groups" ON option_groups;
DROP POLICY IF EXISTS "Allow admin users to manage options" ON options;
DROP POLICY IF EXISTS "Allow admin users to manage category_option_groups" ON category_option_groups;

-- Public read access
CREATE POLICY "Allow public read access to option_groups" ON option_groups
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access to options" ON options
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access to category_option_groups" ON category_option_groups
  FOR SELECT USING (true);

-- Admin management access
CREATE POLICY "Allow admin users to manage option_groups" ON option_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Allow admin users to manage options" ON options
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Allow admin users to manage category_option_groups" ON category_option_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ============================================
-- STEP 6: Sample Data - Beverages
-- ============================================
-- Insert Beverage Option Groups
INSERT INTO option_groups (name, description, selection_type, is_required, sort_order) VALUES
  ('Milk Types', 'Choose your milk preference', 'single', true, 1),
  ('Coffee Sizes', 'Select your drink size', 'single', true, 2),
  ('Coffee Extras', 'Add extras to your drink', 'multiple', false, 3)
ON CONFLICT DO NOTHING;

-- Get the IDs for the option groups we just created
DO $$
DECLARE
  milk_group_id UUID;
  size_group_id UUID;
  extras_group_id UUID;
  beverages_category_id UUID;
BEGIN
  -- Get option group IDs
  SELECT id INTO milk_group_id FROM option_groups WHERE name = 'Milk Types';
  SELECT id INTO size_group_id FROM option_groups WHERE name = 'Coffee Sizes';
  SELECT id INTO extras_group_id FROM option_groups WHERE name = 'Coffee Extras';
  
  -- Insert Milk Options
  INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
    (milk_group_id, 'Whole Milk', 'Standard whole milk', 0.00, true, 1),
    (milk_group_id, 'Skim Milk', 'Fat-free skim milk', 0.00, false, 2),
    (milk_group_id, 'Almond Milk', 'Dairy-free almond milk', 0.50, false, 3),
    (milk_group_id, 'Oat Milk', 'Creamy oat milk', 0.75, false, 4),
    (milk_group_id, 'Soy Milk', 'Dairy-free soy milk', 0.50, false, 5),
    (milk_group_id, 'Coconut Milk', 'Rich coconut milk', 0.75, false, 6),
    (milk_group_id, 'No Milk', 'Black coffee', 0.00, false, 7)
  ON CONFLICT DO NOTHING;
  
  -- Insert Size Options
  INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
    (size_group_id, 'Small', '8oz cup', 0.00, false, 1),
    (size_group_id, 'Medium', '12oz cup', 0.50, true, 2),
    (size_group_id, 'Large', '16oz cup', 1.00, false, 3),
    (size_group_id, 'Extra Large', '20oz cup', 1.50, false, 4)
  ON CONFLICT DO NOTHING;
  
  -- Insert Extra Options (with dependencies)
  INSERT INTO options (option_group_id, name, description, price_adjustment, sort_order) VALUES
    (extras_group_id, 'Extra Shot', 'Additional espresso shot', 0.75, 1),
    (extras_group_id, 'Decaf', 'Decaffeinated coffee', 0.00, 2),
    (extras_group_id, 'Extra Hot', 'Served extra hot', 0.00, 3),
    (extras_group_id, 'Whipped Cream', 'Fresh whipped cream', 0.50, 4),
    (extras_group_id, 'Vanilla Syrup', 'Sweet vanilla flavoring', 0.50, 5),
    (extras_group_id, 'Caramel Syrup', 'Rich caramel flavoring', 0.50, 6)
  ON CONFLICT DO NOTHING;
  
  -- Link to Beverages category (if it exists)
  SELECT id INTO beverages_category_id FROM categories WHERE LOWER(name) LIKE '%bever%' OR LOWER(name) LIKE '%drink%' OR LOWER(name) LIKE '%coffee%' LIMIT 1;
  
  IF beverages_category_id IS NOT NULL THEN
    INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order) VALUES
      (beverages_category_id, milk_group_id, true, 1),
      (beverages_category_id, size_group_id, true, 2),
      (beverages_category_id, extras_group_id, false, 3)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- ============================================
-- STEP 7: Sample Data - Main Courses
-- ============================================
INSERT INTO option_groups (name, description, selection_type, is_required, sort_order) VALUES
  ('Cooking Preference', 'How would you like it cooked?', 'single', false, 1),
  ('Side Dishes', 'Choose your sides', 'multiple', false, 2),
  ('Dietary Options', 'Special dietary requirements', 'multiple', false, 3)
ON CONFLICT DO NOTHING;

-- Get the IDs and insert main course options
DO $$
DECLARE
  cooking_group_id UUID;
  sides_group_id UUID;
  dietary_group_id UUID;
  mains_category_id UUID;
BEGIN
  SELECT id INTO cooking_group_id FROM option_groups WHERE name = 'Cooking Preference';
  SELECT id INTO sides_group_id FROM option_groups WHERE name = 'Side Dishes';
  SELECT id INTO dietary_group_id FROM option_groups WHERE name = 'Dietary Options';
  
  -- Cooking preferences
  INSERT INTO options (option_group_id, name, description, price_adjustment, is_default, sort_order) VALUES
    (cooking_group_id, 'Rare', 'Cool red center', 0.00, false, 1),
    (cooking_group_id, 'Medium Rare', 'Warm red center', 0.00, false, 2),
    (cooking_group_id, 'Medium', 'Warm pink center', 0.00, true, 3),
    (cooking_group_id, 'Medium Well', 'Slightly pink center', 0.00, false, 4),
    (cooking_group_id, 'Well Done', 'Fully cooked', 0.00, false, 5)
  ON CONFLICT DO NOTHING;
  
  -- Side dishes
  INSERT INTO options (option_group_id, name, description, price_adjustment, sort_order) VALUES
    (sides_group_id, 'French Fries', 'Golden crispy fries', 2.50, 1),
    (sides_group_id, 'Sweet Potato Fries', 'Crispy sweet potato fries', 3.00, 2),
    (sides_group_id, 'Garden Salad', 'Fresh mixed greens', 3.50, 3),
    (sides_group_id, 'Onion Rings', 'Beer battered onion rings', 3.00, 4),
    (sides_group_id, 'Soup of the Day', 'Chef''s daily soup', 2.50, 5)
  ON CONFLICT DO NOTHING;
  
  -- Dietary options
  INSERT INTO options (option_group_id, name, description, price_adjustment, sort_order) VALUES
    (dietary_group_id, 'Gluten Free', 'Prepared gluten-free', 0.00, 1),
    (dietary_group_id, 'Dairy Free', 'No dairy products', 0.00, 2),
    (dietary_group_id, 'Vegan', 'Plant-based preparation', 0.00, 3),
    (dietary_group_id, 'Low Carb', 'Reduced carbohydrates', 0.00, 4)
  ON CONFLICT DO NOTHING;
  
  -- Link to Main Courses category
  SELECT id INTO mains_category_id FROM categories WHERE LOWER(name) LIKE '%main%' OR LOWER(name) LIKE '%entree%' OR LOWER(name) LIKE '%burger%' LIMIT 1;
  
  IF mains_category_id IS NOT NULL THEN
    INSERT INTO category_option_groups (category_id, option_group_id, is_required, sort_order) VALUES
      (mains_category_id, cooking_group_id, false, 1),
      (mains_category_id, sides_group_id, false, 2),
      (mains_category_id, dietary_group_id, false, 3)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- ============================================
-- STEP 8: Useful Views for Easy Querying
-- ============================================

-- Drop view if it exists
DROP VIEW IF EXISTS category_options_view;

-- View to get all options for a category
CREATE VIEW category_options_view AS
SELECT 
  c.id as category_id,
  c.name as category_name,
  og.id as option_group_id,
  og.name as option_group_name,
  og.description as option_group_description,
  og.selection_type,
  cog.is_required as group_required,
  og.sort_order as group_sort_order,
  o.id as option_id,
  o.name as option_name,
  o.description as option_description,
  o.price_adjustment,
  o.icon_url,
  o.is_available,
  o.is_default,
  o.depends_on_option_id,
  o.sort_order as option_sort_order
FROM categories c
JOIN category_option_groups cog ON c.id = cog.category_id
JOIN option_groups og ON cog.option_group_id = og.id
JOIN options o ON og.id = o.option_group_id
WHERE o.is_available = true
ORDER BY c.name, cog.sort_order, og.sort_order, o.sort_order;

-- Grant access to the view
GRANT SELECT ON category_options_view TO anon, authenticated;

-- ============================================
-- STEP 9: Helper Functions
-- ============================================

-- Drop function if it exists
DROP FUNCTION IF EXISTS get_menu_item_options(UUID);

-- Function to get all options for a specific menu item (by category)
CREATE OR REPLACE FUNCTION get_menu_item_options(menu_item_id UUID)
RETURNS TABLE (
  option_group_id UUID,
  option_group_name VARCHAR,
  selection_type VARCHAR,
  is_required BOOLEAN,
  option_id UUID,
  option_name VARCHAR,
  price_adjustment DECIMAL,
  icon_url VARCHAR,
  is_default BOOLEAN,
  depends_on_option_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    cov.option_group_id,
    cov.option_group_name,
    cov.selection_type,
    cov.group_required,
    cov.option_id,
    cov.option_name,
    cov.price_adjustment,
    cov.icon_url,
    cov.is_default,
    cov.depends_on_option_id
  FROM category_options_view cov
  JOIN menu_items mi ON mi.category_id = cov.category_id
  WHERE mi.id = menu_item_id
  ORDER BY cov.group_sort_order, cov.option_sort_order;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_menu_item_options(UUID) TO anon, authenticated;

-- ============================================
-- STEP 10: Data Verification
-- ============================================
SELECT 'Menu Options System Setup Complete!' as status;

SELECT 'Option Groups Created:' as info;
SELECT name, selection_type, is_required FROM option_groups ORDER BY sort_order;

SELECT 'Sample Options Created:' as info;  
SELECT 
  og.name as group_name,
  o.name as option_name,
  o.price_adjustment,
  o.is_default
FROM options o
JOIN option_groups og ON o.option_group_id = og.id
ORDER BY og.sort_order, o.sort_order
LIMIT 20;

SELECT 'Category Mappings:' as info;
SELECT 
  c.name as category_name,
  og.name as option_group_name,
  cog.is_required
FROM category_option_groups cog
JOIN categories c ON cog.category_id = c.id
JOIN option_groups og ON cog.option_group_id = og.id
ORDER BY c.name, cog.sort_order;