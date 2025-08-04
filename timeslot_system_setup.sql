-- Timeslot System Database Setup
-- Run this in your Supabase SQL Editor

-- Create restaurant_settings table
CREATE TABLE IF NOT EXISTS restaurant_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key VARCHAR(100) UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create opening_hours table
CREATE TABLE IF NOT EXISTS opening_hours (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0 = Sunday, 6 = Saturday
  is_open BOOLEAN DEFAULT true,
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(day_of_week)
);

-- Create timeslots table
CREATE TABLE IF NOT EXISTS timeslots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL,
  time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  max_orders INTEGER DEFAULT 10, -- Maximum orders per timeslot
  current_orders INTEGER DEFAULT 0, -- Current number of orders
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date, time)
);

-- Enable Row Level Security
ALTER TABLE restaurant_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE opening_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeslots ENABLE ROW LEVEL SECURITY;

-- Create policies for restaurant_settings
CREATE POLICY "Allow public read access to restaurant_settings" ON restaurant_settings
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage restaurant_settings" ON restaurant_settings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create policies for opening_hours
CREATE POLICY "Allow public read access to opening_hours" ON opening_hours
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage opening_hours" ON opening_hours
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create policies for timeslots
CREATE POLICY "Allow public read access to timeslots" ON timeslots
  FOR SELECT USING (true);

CREATE POLICY "Allow admin users to manage timeslots" ON timeslots
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Insert default restaurant settings (only if they don't exist)
INSERT INTO restaurant_settings (setting_key, setting_value, description) VALUES
  ('timeslot_interval_minutes', '15', 'Time interval between slots in minutes'),
  ('buffer_start_minutes', '30', 'Buffer time at start of day in minutes'),
  ('buffer_end_minutes', '30', 'Buffer time at end of day in minutes'),
  ('max_orders_per_slot', '10', 'Maximum orders allowed per timeslot'),
  ('advance_booking_days', '7', 'How many days in advance customers can book'),
  ('restaurant_name', 'Restaurant Name', 'Name of the restaurant'),
  ('restaurant_phone', '+44 123 456 7890', 'Restaurant contact phone'),
  ('restaurant_email', 'info@restaurant.com', 'Restaurant contact email')
ON CONFLICT (setting_key) DO NOTHING;

-- Insert default opening hours (Monday to Sunday) - only if they don't exist
INSERT INTO opening_hours (day_of_week, is_open, open_time, close_time) VALUES
  (1, true, '09:00', '22:00'), -- Monday
  (2, true, '09:00', '22:00'), -- Tuesday
  (3, true, '09:00', '22:00'), -- Wednesday
  (4, true, '09:00', '22:00'), -- Thursday
  (5, true, '09:00', '23:00'), -- Friday
  (6, true, '10:00', '23:00'), -- Saturday
  (0, true, '10:00', '21:00')  -- Sunday
ON CONFLICT (day_of_week) DO NOTHING;

-- Add timeslot_id to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS timeslot_id UUID REFERENCES timeslots(id);

-- Create function to generate timeslots for a specific date
CREATE OR REPLACE FUNCTION generate_timeslots_for_date(target_date DATE)
RETURNS INTEGER AS $$
DECLARE
  day_num INTEGER;
  opening_record RECORD;
  slot_time TIME;
  slot_interval INTEGER;
  buffer_start INTEGER;
  buffer_end INTEGER;
  slots_created INTEGER := 0;
BEGIN
  -- Get day of week (0 = Sunday, 6 = Saturday)
  day_num := EXTRACT(DOW FROM target_date);
  
  -- Get opening hours for this day
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  -- If restaurant is closed on this day, return 0
  IF NOT FOUND OR NOT opening_record.is_open THEN
    RETURN 0;
  END IF;
  
  -- Get settings
  SELECT setting_value::INTEGER INTO slot_interval 
  FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_start 
  FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_end 
  FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  
  -- Generate slots
  WHILE slot_time <= (opening_record.close_time - (buffer_end || ' minutes')::INTERVAL) LOOP
    -- Insert timeslot if it doesn't exist
    INSERT INTO timeslots (date, time, is_available)
    VALUES (target_date, slot_time, true)
    ON CONFLICT (date, time) DO NOTHING;
    
    -- Check if slot was actually inserted (not a conflict)
    IF FOUND THEN
      slots_created := slots_created + 1;
    END IF;
    
    -- Move to next slot
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  RETURN slots_created;
END;
$$ LANGUAGE plpgsql;

-- Create function to generate timeslots for next 7 days
CREATE OR REPLACE FUNCTION generate_upcoming_timeslots()
RETURNS INTEGER AS $$
DECLARE
  total_slots INTEGER := 0;
  start_date DATE;
  i INTEGER;
BEGIN
  start_date := CURRENT_DATE;
  
  FOR i IN 0..6 LOOP
    total_slots := total_slots + generate_timeslots_for_date(start_date + i);
  END LOOP;
  
  RETURN total_slots;
END;
$$ LANGUAGE plpgsql;

-- Generate initial timeslots for the next 7 days
SELECT generate_upcoming_timeslots();

-- Create function to update timeslot order count when order is placed
CREATE OR REPLACE FUNCTION update_timeslot_order_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.timeslot_id IS NOT NULL THEN
    -- Increment order count
    UPDATE timeslots 
    SET current_orders = current_orders + 1,
        updated_at = NOW()
    WHERE id = NEW.timeslot_id;
  ELSIF TG_OP = 'DELETE' AND OLD.timeslot_id IS NOT NULL THEN
    -- Decrement order count
    UPDATE timeslots 
    SET current_orders = GREATEST(current_orders - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.timeslot_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle timeslot change
    IF OLD.timeslot_id IS NOT NULL AND OLD.timeslot_id != NEW.timeslot_id THEN
      UPDATE timeslots 
      SET current_orders = GREATEST(current_orders - 1, 0),
          updated_at = NOW()
      WHERE id = OLD.timeslot_id;
    END IF;
    
    IF NEW.timeslot_id IS NOT NULL AND OLD.timeslot_id != NEW.timeslot_id THEN
      UPDATE timeslots 
      SET current_orders = current_orders + 1,
          updated_at = NOW()
      WHERE id = NEW.timeslot_id;
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order timeslot updates
DROP TRIGGER IF EXISTS orders_timeslot_update ON public.orders;
CREATE TRIGGER orders_timeslot_update
  AFTER INSERT OR UPDATE OR DELETE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_timeslot_order_count();

-- Create view for available timeslots
CREATE OR REPLACE VIEW available_timeslots AS
SELECT 
  t.*,
  (t.current_orders < COALESCE(
    (SELECT setting_value::INTEGER FROM restaurant_settings WHERE setting_key = 'max_orders_per_slot'),
    10
  )) AS has_capacity,
  oh.is_open AS restaurant_open
FROM timeslots t
JOIN opening_hours oh ON oh.day_of_week = EXTRACT(DOW FROM t.date)
WHERE t.is_available = true
  AND t.date >= CURRENT_DATE
  AND oh.is_open = true
ORDER BY t.date, t.time;