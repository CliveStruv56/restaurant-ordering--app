-- TIMESLOT DAILY MAINTENANCE SYSTEM
-- This creates a robust system for maintaining timeslots automatically

-- ========================================
-- STEP 1: Create maintenance function
-- ========================================
DROP FUNCTION IF EXISTS maintain_timeslots();

CREATE OR REPLACE FUNCTION maintain_timeslots()
RETURNS JSON AS $$
DECLARE
  advance_days INTEGER;
  slots_deleted INTEGER := 0;
  slots_created INTEGER := 0;
  days_processed INTEGER := 0;
  target_date DATE;
  day_slots INTEGER;
  result JSON;
BEGIN
  -- Get advance booking days setting
  SELECT COALESCE(setting_value::INTEGER, 7) INTO advance_days
  FROM restaurant_settings 
  WHERE setting_key = 'advance_booking_days';
  
  RAISE NOTICE 'Maintaining timeslots for next % days', advance_days;
  
  -- STEP 1: Delete old timeslots (before today)
  DELETE FROM timeslots WHERE date < CURRENT_DATE;
  GET DIAGNOSTICS slots_deleted = ROW_COUNT;
  RAISE NOTICE 'Deleted % old timeslots', slots_deleted;
  
  -- STEP 2: Delete timeslots beyond advance booking window
  DELETE FROM timeslots WHERE date > CURRENT_DATE + (advance_days || ' days')::INTERVAL;
  
  -- STEP 3: Generate timeslots for each day in the window
  FOR i IN 0..(advance_days - 1) LOOP
    target_date := CURRENT_DATE + i;
    
    -- Check if timeslots already exist for this date
    IF NOT EXISTS (SELECT 1 FROM timeslots WHERE date = target_date LIMIT 1) THEN
      -- Generate timeslots for this date
      day_slots := generate_timeslots_for_date(target_date);
      slots_created := slots_created + day_slots;
      days_processed := days_processed + 1;
      RAISE NOTICE 'Generated % slots for %', day_slots, target_date;
    ELSE
      RAISE NOTICE 'Timeslots already exist for %', target_date;
    END IF;
  END LOOP;
  
  -- Return summary as JSON
  result := json_build_object(
    'execution_time', NOW(),
    'slots_deleted', slots_deleted,
    'slots_created', slots_created,
    'days_processed', days_processed,
    'advance_days', advance_days
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 2: Create a maintenance log table
-- ========================================
CREATE TABLE IF NOT EXISTS timeslot_maintenance_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  execution_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  result JSON,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- STEP 3: Create a function to run maintenance and log it
-- ========================================
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

-- ========================================
-- STEP 4: Create Supabase Edge Function for daily execution
-- ========================================
-- Note: This needs to be set up in Supabase Dashboard
-- Go to Database -> Extensions -> Enable pg_cron
-- Then run this to schedule daily execution at 2 AM:

-- SELECT cron.schedule(
--   'timeslot-daily-maintenance',
--   '0 2 * * *', -- Run at 2 AM every day
--   $$SELECT run_timeslot_maintenance();$$
-- );

-- ========================================
-- STEP 5: Create a manual trigger for testing
-- ========================================
-- You can call this function manually to test the maintenance
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

-- ========================================
-- STEP 6: Fix the generate_timeslots_for_date function
-- ========================================
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
    RETURN 0;
  END IF;
  
  -- Get fresh settings from database
  SELECT setting_value::INTEGER INTO slot_interval 
  FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_start 
  FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  
  SELECT setting_value::INTEGER INTO buffer_end 
  FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  
  -- Use defaults if settings missing
  slot_interval := COALESCE(slot_interval, 15);
  buffer_start := COALESCE(buffer_start, 30);
  buffer_end := COALESCE(buffer_end, 30);
  
  -- Calculate start and end times with buffers
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  -- Generate slots
  WHILE slot_time <= end_time LOOP
    INSERT INTO timeslots (date, time, is_available, max_orders, current_orders)
    VALUES (target_date, slot_time, true, 10, 0)
    ON CONFLICT (date, time) DO NOTHING;
    
    GET DIAGNOSTICS slots_created = ROW_COUNT;
    slots_created := slots_created + GET DIAGNOSTICS;
    
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
  -- Return actual count of slots for this date
  SELECT COUNT(*) INTO slots_created FROM timeslots WHERE date = target_date;
  RETURN slots_created;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 7: Run initial maintenance
-- ========================================
SELECT 'Running initial maintenance...' as info;
SELECT trigger_timeslot_maintenance() as maintenance_result;

-- ========================================
-- STEP 8: Show results
-- ========================================
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

SELECT 'Sample timeslots:' as info;
SELECT date, time, is_available
FROM timeslots
WHERE date >= CURRENT_DATE
ORDER BY date, time
LIMIT 20;