-- Restaurant App Database Setup
-- Run this in your Supabase SQL Editor

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create menu_items table
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id),
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  tags TEXT[],
  customizations JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample categories
INSERT INTO categories (id, name, description, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Appetizers', 'Start your meal with our delicious appetizers', 1),
  ('550e8400-e29b-41d4-a716-446655440002', 'Main Courses', 'Our signature main dishes', 2),
  ('550e8400-e29b-41d4-a716-446655440003', 'Pasta', 'Fresh pasta dishes made to order', 3),
  ('550e8400-e29b-41d4-a716-446655440004', 'Pizza', 'Wood-fired pizzas with premium toppings', 4),
  ('550e8400-e29b-41d4-a716-446655440005', 'Salads', 'Fresh and healthy salad options', 5),
  ('550e8400-e29b-41d4-a716-446655440006', 'Desserts', 'Sweet endings to your meal', 6),
  ('550e8400-e29b-41d4-a716-446655440007', 'Beverages', 'Refreshing drinks and cocktails', 7);

-- Insert sample menu items
INSERT INTO menu_items (name, description, price, category_id, image_url, tags, customizations) VALUES
  -- Appetizers
  ('Bruschetta', 'Toasted bread topped with fresh tomatoes, basil, and garlic', 8.50, '550e8400-e29b-41d4-a716-446655440001', 'https://images.unsplash.com/photo-1572445271230-a78b5944a659?w=400', ARRAY['vegetarian', 'gluten-free'], '{"sauces": ["olive oil", "balsamic"], "additions": ["cheese", "prosciutto"]}'),
  ('Calamari', 'Crispy fried squid served with marinara sauce', 12.00, '550e8400-e29b-41d4-a716-446655440001', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400', ARRAY['seafood', 'fried'], '{"sauces": ["marinara", "aioli"], "spice_level": ["mild", "medium", "hot"]}'),
  ('Caprese Salad', 'Fresh mozzarella, tomatoes, and basil with balsamic glaze', 10.50, '550e8400-e29b-41d4-a716-446655440001', 'https://images.unsplash.com/photo-1551248429-40975aa4de74?w=400', ARRAY['vegetarian', 'fresh'], '{"dressing": ["balsamic", "olive oil"], "additions": ["avocado", "prosciutto"]}'),
  
  -- Main Courses
  ('Grilled Salmon', 'Atlantic salmon with seasonal vegetables and lemon butter sauce', 24.00, '550e8400-e29b-41d4-a716-446655440002', 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', ARRAY['seafood', 'healthy'], '{"cooking": ["medium rare", "medium", "well done"], "sides": ["rice", "potatoes", "vegetables"]}'),
  ('Beef Tenderloin', '8oz tenderloin with roasted potatoes and asparagus', 28.00, '550e8400-e29b-41d4-a716-446655440002', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400', ARRAY['beef', 'premium'], '{"cooking": ["rare", "medium rare", "medium", "well done"], "sauces": ["peppercorn", "mushroom", "red wine"]}'),
  ('Chicken Marsala', 'Pan-seared chicken in marsala wine sauce with mushrooms', 22.00, '550e8400-e29b-41d4-a716-446655440002', 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', ARRAY['chicken', 'italian'], '{"sides": ["pasta", "rice", "vegetables"], "sauces": ["extra marsala", "cream sauce"]}'),
  
  -- Pasta
  ('Spaghetti Carbonara', 'Classic pasta with eggs, cheese, pancetta, and black pepper', 16.00, '550e8400-e29b-41d4-a716-446655440003', 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400', ARRAY['pasta', 'italian'], '{"pasta": ["spaghetti", "fettuccine", "linguine"], "additions": ["extra cheese", "extra pancetta", "mushrooms"]}'),
  ('Fettuccine Alfredo', 'Creamy alfredo sauce with parmesan cheese', 15.00, '550e8400-e29b-41d4-a716-446655440003', 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400', ARRAY['pasta', 'vegetarian'], '{"pasta": ["fettuccine", "linguine", "spaghetti"], "additions": ["chicken", "shrimp", "mushrooms"]}'),
  ('Penne Arrabbiata', 'Spicy tomato sauce with garlic and red chili peppers', 14.00, '550e8400-e29b-41d4-a716-446655440003', 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400', ARRAY['pasta', 'spicy'], '{"spice_level": ["mild", "medium", "hot"], "additions": ["chicken", "shrimp", "vegetables"]}'),
  
  -- Pizza
  ('Margherita Pizza', 'Classic pizza with tomato sauce, mozzarella, and basil', 18.00, '550e8400-e29b-41d4-a716-446655440004', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400', ARRAY['pizza', 'vegetarian'], '{"size": ["small", "medium", "large"], "crust": ["thin", "thick"], "toppings": ["extra cheese", "pepperoni", "mushrooms"]}'),
  ('Pepperoni Pizza', 'Traditional pizza topped with pepperoni and mozzarella', 20.00, '550e8400-e29b-41d4-a716-446655440004', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400', ARRAY['pizza', 'meat'], '{"size": ["small", "medium", "large"], "crust": ["thin", "thick"], "toppings": ["extra cheese", "extra pepperoni", "mushrooms"]}'),
  ('Vegetarian Pizza', 'Fresh vegetables with mozzarella and tomato sauce', 19.00, '550e8400-e29b-41d4-a716-446655440004', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400', ARRAY['pizza', 'vegetarian'], '{"size": ["small", "medium", "large"], "crust": ["thin", "thick"], "toppings": ["bell peppers", "mushrooms", "olives", "onions"]}'),
  
  -- Salads
  ('Caesar Salad', 'Romaine lettuce, parmesan cheese, croutons, and caesar dressing', 12.00, '550e8400-e29b-41d4-a716-446655440005', 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400', ARRAY['salad', 'healthy'], '{"dressing": ["caesar", "light caesar"], "additions": ["chicken", "shrimp", "salmon"], "croutons": ["regular", "gluten-free"]}'),
  ('Greek Salad', 'Mixed greens, feta cheese, olives, tomatoes, and cucumber', 11.00, '550e8400-e29b-41d4-a716-446655440005', 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400', ARRAY['salad', 'vegetarian'], '{"dressing": ["greek", "olive oil"], "additions": ["chicken", "shrimp"], "cheese": ["feta", "goat cheese"]}'),
  ('Spinach Salad', 'Fresh spinach with strawberries, almonds, and balsamic vinaigrette', 13.00, '550e8400-e29b-41d4-a716-446655440005', 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400', ARRAY['salad', 'vegetarian'], '{"dressing": ["balsamic", "raspberry"], "additions": ["chicken", "goat cheese"], "nuts": ["almonds", "walnuts", "pecans"]}'),
  
  -- Desserts
  ('Tiramisu', 'Classic Italian dessert with coffee-soaked ladyfingers and mascarpone', 8.00, '550e8400-e29b-41d4-a716-446655440006', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400', ARRAY['dessert', 'italian'], '{"coffee": ["regular", "decaf"], "additions": ["extra coffee", "chocolate shavings"]}'),
  ('Chocolate Lava Cake', 'Warm chocolate cake with molten center, served with vanilla ice cream', 9.00, '550e8400-e29b-41d4-a716-446655440006', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400', ARRAY['dessert', 'chocolate'], '{"ice_cream": ["vanilla", "chocolate", "strawberry"], "additions": ["berries", "whipped cream"]}'),
  ('New York Cheesecake', 'Creamy cheesecake with berry compote', 7.50, '550e8400-e29b-41d4-a716-446655440006', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400', ARRAY['dessert', 'classic'], '{"toppings": ["berry compote", "chocolate sauce", "caramel"], "additions": ["whipped cream"]}'),
  
  -- Beverages
  ('Italian Soda', 'Choice of flavored syrups with sparkling water', 4.50, '550e8400-e29b-41d4-a716-446655440007', 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', ARRAY['beverage', 'non-alcoholic'], '{"flavors": ["raspberry", "strawberry", "vanilla", "lime"], "additions": ["cream", "ice"]}'),
  ('Espresso', 'Single shot of premium Italian espresso', 3.00, '550e8400-e29b-41d4-a716-446655440007', 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', ARRAY['beverage', 'coffee'], '{"size": ["single", "double"], "additions": ["sugar", "milk", "cream"]}'),
  ('House Red Wine', 'Glass of our house red wine selection', 8.00, '550e8400-e29b-41d4-a716-446655440007', 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', ARRAY['beverage', 'alcoholic'], '{"size": ["glass", "bottle"], "temperature": ["room temperature", "chilled"]}');

-- Enable Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Allow public read access to categories" ON categories
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access to menu_items" ON menu_items
  FOR SELECT USING (true); 