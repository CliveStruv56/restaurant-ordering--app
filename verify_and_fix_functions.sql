-- Verify and Fix Functions Script
-- Run this to check and recreate the timeslot generation functions

-- First, let's check if the functions exist
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('generate_timeslots_for_date', 'generate_upcoming_timeslots');

-- Drop and recreate the functions to ensure they work
DROP FUNCTION IF EXISTS generate_upcoming_timeslots();
DROP FUNCTION IF EXISTS generate_timeslots_for_date(DATE);

-- Recreate generate_timeslots_for_date function
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
  
  -- Get settings with defaults
  SELECT COALESCE(setting_value::INTEGER, 15) INTO slot_interval 
  FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT COALESCE(setting_value::INTEGER, 30) INTO buffer_start 
  FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  
  SELECT COALESCE(setting_value::INTEGER, 30) INTO buffer_end 
  FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  
  -- Ensure defaults if no settings found (handle empty result set)
  slot_interval := COALESCE(slot_interval, 15);
  buffer_start := COALESCE(buffer_start, 30);
  buffer_end := COALESCE(buffer_end, 30);
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  
  -- Generate slots
  WHILE slot_time <= (opening_record.close_time - (buffer_end || ' minutes')::INTERVAL) LOOP
    -- Insert timeslot if it doesn't exist
    INSERT INTO timeslots (date, time, is_available)
    VALUES (target_date, slot_time, true)
    ON CONFLICT (date, time) DO NOTHING;
    
    -- Move to next slot
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  -- Return total slots for this date (not just newly created)
  SELECT COUNT(*) INTO slots_created FROM timeslots WHERE date = target_date;
  RETURN slots_created;
END;
$$ LANGUAGE plpgsql;

-- Recreate generate_upcoming_timeslots function
CREATE OR REPLACE FUNCTION generate_upcoming_timeslots()
RETURNS INTEGER AS $$
DECLARE
  total_slots INTEGER := 0;
  start_date DATE;
  i INTEGER;
  day_slots INTEGER;
BEGIN
  start_date := CURRENT_DATE;
  
  FOR i IN 0..6 LOOP
    day_slots := generate_timeslots_for_date(start_date + i);
    total_slots := total_slots + day_slots;
  END LOOP;
  
  RETURN total_slots;
END;
$$ LANGUAGE plpgsql;

-- Test the functions
SELECT generate_upcoming_timeslots() as total_timeslots_generated;

-- Show what we have
SELECT DATE(date) as date, COUNT(*) as timeslot_count 
FROM timeslots 
GROUP BY DATE(date) 
ORDER BY date;