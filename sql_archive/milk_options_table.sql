-- Create milk_options table
CREATE TABLE IF NOT EXISTS milk_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price_adjustment DECIMAL(10,2) DEFAULT 0.00,
  is_available BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample milk options
INSERT INTO milk_options (name, description, price_adjustment, sort_order) VALUES
  ('Whole Milk', 'Standard whole milk', 0.00, 1),
  ('Skim Milk', 'Fat-free skim milk', 0.00, 2),
  ('2% Milk', 'Reduced fat milk', 0.00, 3),
  ('Almond Milk', 'Dairy-free almond milk', 0.50, 4),
  ('Soy Milk', 'Dairy-free soy milk', 0.50, 5),
  ('Oat Milk', 'Dairy-free oat milk', 0.75, 6),
  ('Coconut Milk', 'Dairy-free coconut milk', 0.75, 7),
  ('No Milk', 'No milk option', 0.00, 8);

-- Enable Row Level Security
ALTER TABLE milk_options ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Allow public read access to milk_options" ON milk_options
  FOR SELECT USING (true);

-- Create policies for admin management
CREATE POLICY "Allow admin users to manage milk_options" ON milk_options
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  ); 