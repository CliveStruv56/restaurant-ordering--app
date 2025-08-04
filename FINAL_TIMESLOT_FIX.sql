-- FINAL COMPLETE TIMESLOT FIX
-- Run this entire script in Supabase SQL Editor to fix all issues

-- ========================================
-- STEP 1: Clean up ALL existing timeslots
-- ========================================
DELETE FROM timeslots;

-- ========================================
-- STEP 2: Fix the functions with correct logic
-- ========================================
DROP FUNCTION IF EXISTS generate_upcoming_timeslots();
DROP FUNCTION IF EXISTS generate_timeslots_for_date(DATE);

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
BEGIN
  -- Get day of week (0 = Sunday, 6 = Saturday)
  day_num := EXTRACT(DOW FROM target_date);
  
  -- Get opening hours for this day
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  -- If restaurant is closed on this day, return 0
  IF NOT FOUND OR NOT opening_record.is_open THEN
    RAISE NOTICE 'No opening hours or closed for day %', day_num;
    RETURN 0;
  END IF;
  
  -- Get settings - IMPORTANT: Ensure we get the actual values from database
  SELECT setting_value::INTEGER INTO slot_interval 
  FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_start 
  FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_end 
  FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  
  -- Use defaults ONLY if settings don't exist
  slot_interval := COALESCE(slot_interval, 15);
  buffer_start := COALESCE(buffer_start, 30);
  buffer_end := COALESCE(buffer_end, 30);
  
  RAISE NOTICE 'Using interval: % minutes', slot_interval;
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  -- Generate slots
  WHILE slot_time <= end_time LOOP
    INSERT INTO timeslots (date, time, is_available)
    VALUES (target_date, slot_time, true)
    ON CONFLICT (date, time) DO NOTHING;
    
    slots_created := slots_created + 1;
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  RETURN slots_created;
END;
$$ LANGUAGE plpgsql;

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
    RAISE NOTICE 'Generated % slots for %', day_slots, start_date + i;
  END LOOP;
  
  RETURN total_slots;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 3: Create the missing view
-- ========================================
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
  (t.current_orders < COALESCE(t.max_orders, 10)) AS has_capacity,
  oh.is_open AS restaurant_open
FROM timeslots t
LEFT JOIN opening_hours oh ON oh.day_of_week = EXTRACT(DOW FROM t.date)
WHERE t.is_available = true
  AND t.date >= CURRENT_DATE
  AND COALESCE(oh.is_open, true) = true
ORDER BY t.date, t.time;

-- Grant permissions on the view
GRANT SELECT ON available_timeslots TO anon, authenticated;

-- ========================================
-- STEP 4: Update restaurant settings to 45 minutes
-- ========================================
UPDATE restaurant_settings 
SET setting_value = '45', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

-- Insert if doesn't exist
INSERT INTO restaurant_settings (setting_key, setting_value, description)
SELECT 'timeslot_interval_minutes', '45', 'Time interval between slots in minutes'
WHERE NOT EXISTS (
  SELECT 1 FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes'
);

-- ========================================
-- STEP 5: Verify settings are correct
-- ========================================
SELECT 'Current Interval Setting:' as info;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key = 'timeslot_interval_minutes';

-- ========================================
-- STEP 6: Generate fresh timeslots with new interval
-- ========================================
SELECT 'Generating timeslots...' as info;
SELECT generate_upcoming_timeslots() as slots_generated;

-- ========================================
-- STEP 7: Verify the results
-- ========================================
SELECT 'Sample timeslots showing intervals:' as info;
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
  prev_time,
  COALESCE(minutes_between::TEXT || ' minutes', 'First slot') as interval_from_previous
FROM timeslot_intervals
ORDER BY date, time
LIMIT 20;

-- ========================================
-- STEP 8: Test the view
-- ========================================
SELECT 'Testing available_timeslots view:' as info;
SELECT COUNT(*) as view_count FROM available_timeslots;

-- ========================================
-- STEP 9: Summary
-- ========================================
SELECT 'Summary by date:' as info;
SELECT 
  date,
  COUNT(*) as slot_count,
  MIN(time) as first_slot,
  MAX(time) as last_slot
FROM timeslots
WHERE date >= CURRENT_DATE
GROUP BY date
ORDER BY date;