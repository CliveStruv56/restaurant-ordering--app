-- COMPLETE ROBUST TIMESLOT SOLUTION
-- This creates a fully automated timeslot management system

-- ============================================
-- PART 1: Setup Tables and Views
-- ============================================

-- Ensure tables exist
CREATE TABLE IF NOT EXISTS restaurant_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key VARCHAR(100) UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS opening_hours (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  is_open BOOLEAN DEFAULT true,
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(day_of_week)
);

CREATE TABLE IF NOT EXISTS timeslots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL,
  time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  max_orders INTEGER DEFAULT 10,
  current_orders INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date, time)
);

CREATE TABLE IF NOT EXISTS timeslot_maintenance_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  execution_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  result JSON,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PART 2: Core Functions
-- ============================================

-- Function to generate timeslots for a specific date
DROP FUNCTION IF EXISTS generate_timeslots_for_date(DATE);
CREATE OR REPLACE FUNCTION generate_timeslots_for_date(target_date DATE)
RETURNS INTEGER AS $$
DECLARE
  day_num INTEGER;
  opening_record RECORD;
  slot_time TIME;
  slot_interval INTEGER := 15;
  buffer_start INTEGER := 30;
  buffer_end INTEGER := 30;
  slots_created INTEGER := 0;
  end_time TIME;
BEGIN
  -- Get day of week (0 = Sunday, 6 = Saturday)
  day_num := EXTRACT(DOW FROM target_date);
  
  -- Get opening hours for this day
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  -- If restaurant is closed on this day, return 0
  IF NOT FOUND OR NOT opening_record.is_open THEN
    RETURN 0;
  END IF;
  
  -- Get current settings from database
  BEGIN
    SELECT setting_value::INTEGER INTO slot_interval 
    FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  EXCEPTION WHEN OTHERS THEN
    slot_interval := 15; -- default
  END;
  
  BEGIN
    SELECT setting_value::INTEGER INTO buffer_start 
    FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  EXCEPTION WHEN OTHERS THEN
    buffer_start := 30; -- default
  END;
  
  BEGIN
    SELECT setting_value::INTEGER INTO buffer_end 
    FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  EXCEPTION WHEN OTHERS THEN
    buffer_end := 30; -- default
  END;
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  -- Generate slots
  WHILE slot_time <= end_time LOOP
    INSERT INTO timeslots (date, time, is_available, max_orders, current_orders)
    VALUES (target_date, slot_time, true, 10, 0)
    ON CONFLICT (date, time) DO NOTHING;
    
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  -- Return count of slots for this date
  SELECT COUNT(*) INTO slots_created FROM timeslots WHERE date = target_date;
  RETURN slots_created;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 3: Daily Maintenance System
-- ============================================

-- Main maintenance function
DROP FUNCTION IF EXISTS maintain_timeslots();
CREATE OR REPLACE FUNCTION maintain_timeslots()
RETURNS JSON AS $$
DECLARE
  advance_days INTEGER := 7;
  slots_deleted INTEGER := 0;
  slots_created INTEGER := 0;
  days_processed INTEGER := 0;
  target_date DATE;
  day_slots INTEGER;
  result JSON;
BEGIN
  -- Get advance booking days setting
  BEGIN
    SELECT setting_value::INTEGER INTO advance_days
    FROM restaurant_settings WHERE setting_key = 'advance_booking_days';
    advance_days := COALESCE(advance_days, 7);
  EXCEPTION WHEN OTHERS THEN
    advance_days := 7;
  END;
  
  -- STEP 1: Delete old timeslots (before today)
  DELETE FROM timeslots WHERE date < CURRENT_DATE;
  GET DIAGNOSTICS slots_deleted = ROW_COUNT;
  
  -- STEP 2: Delete timeslots beyond advance booking window
  DELETE FROM timeslots WHERE date > CURRENT_DATE + (advance_days || ' days')::INTERVAL;
  
  -- STEP 3: Generate timeslots for missing days in the window
  FOR i IN 0..(advance_days - 1) LOOP
    target_date := CURRENT_DATE + i;
    
    -- Check if timeslots already exist for this date
    IF NOT EXISTS (SELECT 1 FROM timeslots WHERE date = target_date LIMIT 1) THEN
      -- Generate timeslots for this date
      day_slots := generate_timeslots_for_date(target_date);
      slots_created := slots_created + day_slots;
      days_processed := days_processed + 1;
    END IF;
  END LOOP;
  
  -- Return summary as JSON
  result := json_build_object(
    'execution_time', NOW(),
    'slots_deleted', slots_deleted,
    'slots_created', slots_created,
    'days_processed', days_processed,
    'advance_days', advance_days,
    'date_range', json_build_object(
      'start', CURRENT_DATE,
      'end', CURRENT_DATE + (advance_days - 1)
    )
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to run and log maintenance
DROP FUNCTION IF EXISTS run_timeslot_maintenance();
CREATE OR REPLACE FUNCTION run_timeslot_maintenance()
RETURNS void AS $$
DECLARE
  maintenance_result JSON;
BEGIN
  -- Run maintenance
  maintenance_result := maintain_timeslots();
  
  -- Log the result
  INSERT INTO timeslot_maintenance_log (result)
  VALUES (maintenance_result);
  
  -- Clean up old logs (keep only last 30 days)
  DELETE FROM timeslot_maintenance_log 
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Manual trigger function for app
DROP FUNCTION IF EXISTS trigger_timeslot_maintenance();
CREATE OR REPLACE FUNCTION trigger_timeslot_maintenance()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  PERFORM run_timeslot_maintenance();
  
  -- Get the latest log entry
  SELECT result INTO result
  FROM timeslot_maintenance_log
  ORDER BY created_at DESC
  LIMIT 1;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 4: Views
-- ============================================

-- Create optimized available timeslots view
DROP VIEW IF EXISTS available_timeslots CASCADE;
CREATE VIEW available_timeslots AS
SELECT 
  t.id,
  t.date,
  t.time,
  t.is_available,
  t.max_orders,
  t.current_orders,
  t.created_at,
  t.updated_at,
  (t.current_orders < t.max_orders) AS has_capacity,
  oh.is_open AS restaurant_open
FROM timeslots t
LEFT JOIN opening_hours oh ON oh.day_of_week = EXTRACT(DOW FROM t.date)
WHERE t.is_available = true
  AND (
    -- For future dates, show all slots
    t.date > CURRENT_DATE
    OR 
    -- For today, only show slots at least 15 minutes in the future
    (t.date = CURRENT_DATE AND t.time::time > (CURRENT_TIME + INTERVAL '15 minutes'))
  )
  AND COALESCE(oh.is_open, true) = true
  AND t.current_orders < t.max_orders
ORDER BY t.date, t.time;

-- Grant permissions
GRANT SELECT ON available_timeslots TO anon, authenticated;
GRANT SELECT ON timeslot_maintenance_log TO authenticated;

-- ============================================
-- PART 5: Initial Setup Data
-- ============================================

-- Insert default settings
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

-- Insert default opening hours
INSERT INTO opening_hours (day_of_week, is_open, open_time, close_time) VALUES
  (0, true, '10:00', '21:00'), -- Sunday
  (1, true, '09:00', '22:00'), -- Monday
  (2, true, '09:00', '22:00'), -- Tuesday
  (3, true, '09:00', '22:00'), -- Wednesday
  (4, true, '09:00', '22:00'), -- Thursday
  (5, true, '09:00', '23:00'), -- Friday
  (6, true, '10:00', '23:00')  -- Saturday
ON CONFLICT (day_of_week) DO NOTHING;

-- ============================================
-- PART 6: Run Initial Setup
-- ============================================

-- Run initial maintenance to create timeslots
SELECT 'Running initial maintenance...' as info;
SELECT trigger_timeslot_maintenance() as maintenance_result;

-- ============================================
-- PART 7: Verification
-- ============================================

SELECT 'Setup Complete - Verification:' as info;

SELECT 'Timeslots by date:' as info;
SELECT 
  date,
  COUNT(*) as slot_count,
  MIN(time) as first_slot,
  MAX(time) as last_slot
FROM timeslots
WHERE date >= CURRENT_DATE
GROUP BY date
ORDER BY date;

SELECT 'Sample available timeslots:' as info;
SELECT date, time, has_capacity, restaurant_open
FROM available_timeslots
LIMIT 15;

SELECT 'Maintenance log:' as info;
SELECT execution_time, result->>'slots_created' as created, result->>'slots_deleted' as deleted
FROM timeslot_maintenance_log
ORDER BY execution_time DESC
LIMIT 5;

-- ============================================
-- PART 8: Instructions for Production
-- ============================================

-- To set up automatic daily execution in Supabase:
-- 1. Go to Database -> Extensions
-- 2. Enable pg_cron extension
-- 3. Run this command to schedule daily maintenance at 2 AM:

-- SELECT cron.schedule(
--   'timeslot-daily-maintenance',
--   '0 2 * * *', -- Run at 2 AM every day
--   $$SELECT run_timeslot_maintenance();$$
-- );

-- To manually run maintenance from the app, call:
-- SELECT trigger_timeslot_maintenance();

SELECT 'Setup instructions complete!' as info;