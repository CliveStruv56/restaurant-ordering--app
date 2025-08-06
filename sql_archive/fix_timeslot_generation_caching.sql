-- Fix Timeslot Generation to Always Use Current Settings
-- This ensures the functions read fresh values from the database

-- Drop existing functions
DROP FUNCTION IF EXISTS generate_upcoming_timeslots();
DROP FUNCTION IF EXISTS generate_timeslots_for_date(DATE);

-- Create improved generate_timeslots_for_date function
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
  end_time TIME;
  actual_slots_created INTEGER := 0;
BEGIN
  -- Get day of week (0 = Sunday, 6 = Saturday)
  day_num := EXTRACT(DOW FROM target_date);
  
  RAISE NOTICE 'Generating timeslots for date: %, day of week: %', target_date, day_num;
  
  -- Get opening hours for this day
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  -- If restaurant is closed on this day, return 0
  IF NOT FOUND OR NOT opening_record.is_open THEN
    RAISE NOTICE 'Restaurant closed on day %', day_num;
    RETURN 0;
  END IF;
  
  -- Get FRESH settings directly from database (no caching)
  SELECT setting_value::INTEGER INTO STRICT slot_interval 
  FROM restaurant_settings 
  WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT setting_value::INTEGER INTO STRICT buffer_start 
  FROM restaurant_settings 
  WHERE setting_key = 'buffer_start_minutes';
  
  SELECT setting_value::INTEGER INTO STRICT buffer_end 
  FROM restaurant_settings 
  WHERE setting_key = 'buffer_end_minutes';
  
  -- Log what we're using
  RAISE NOTICE 'Using settings - Interval: % min, Buffer start: % min, Buffer end: % min', 
    slot_interval, buffer_start, buffer_end;
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  RAISE NOTICE 'Generating slots from % to %', slot_time, end_time;
  
  -- First, delete existing timeslots for this date to ensure clean generation
  DELETE FROM timeslots WHERE date = target_date;
  
  -- Generate slots
  WHILE slot_time <= end_time LOOP
    INSERT INTO timeslots (date, time, is_available, max_orders, current_orders)
    VALUES (target_date, slot_time, true, 10, 0);
    
    actual_slots_created := actual_slots_created + 1;
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  RAISE NOTICE 'Created % timeslots for %', actual_slots_created, target_date;
  RETURN actual_slots_created;
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE NOTICE 'Missing settings, using defaults';
    -- Use defaults if settings are missing
    slot_interval := 15;
    buffer_start := 30;
    buffer_end := 30;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- Create improved generate_upcoming_timeslots function
CREATE OR REPLACE FUNCTION generate_upcoming_timeslots()
RETURNS INTEGER AS $$
DECLARE
  total_slots INTEGER := 0;
  start_date DATE;
  i INTEGER;
  day_slots INTEGER;
  advance_days INTEGER;
BEGIN
  start_date := CURRENT_DATE;
  
  -- Get advance booking days setting
  SELECT setting_value::INTEGER INTO advance_days
  FROM restaurant_settings 
  WHERE setting_key = 'advance_booking_days';
  
  -- Default to 7 if not found
  advance_days := COALESCE(advance_days, 7);
  
  RAISE NOTICE 'Generating timeslots for next % days starting from %', advance_days, start_date;
  
  -- Clear ALL future timeslots first to ensure clean slate
  DELETE FROM timeslots WHERE date >= start_date;
  RAISE NOTICE 'Cleared existing future timeslots';
  
  -- Generate for each day
  FOR i IN 0..(advance_days - 1) LOOP
    day_slots := generate_timeslots_for_date(start_date + i);
    total_slots := total_slots + day_slots;
    RAISE NOTICE 'Day %: Generated % slots', start_date + i, day_slots;
  END LOOP;
  
  RAISE NOTICE 'Total timeslots generated: %', total_slots;
  RETURN total_slots;
END;
$$ LANGUAGE plpgsql;

-- Test the functions
SELECT 'Current Settings:' as info;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key IN ('timeslot_interval_minutes', 'buffer_start_minutes', 'buffer_end_minutes', 'advance_booking_days')
ORDER BY setting_key;

-- Generate timeslots with current settings
SELECT 'Generating timeslots...' as info;
SELECT generate_upcoming_timeslots() as total_generated;

-- Show sample results
SELECT 'Sample timeslots (showing intervals):' as info;
WITH timeslot_intervals AS (
  SELECT 
    date,
    time,
    LAG(time) OVER (PARTITION BY date ORDER BY time) as prev_time,
    EXTRACT(EPOCH FROM (time - LAG(time) OVER (PARTITION BY date ORDER BY time)))/60 as minutes_between
  FROM timeslots
  WHERE date >= CURRENT_DATE
)
SELECT 
  date,
  time,
  COALESCE(minutes_between::TEXT || ' min interval', 'First slot') as interval_from_previous
FROM timeslot_intervals
ORDER BY date, time
LIMIT 15;