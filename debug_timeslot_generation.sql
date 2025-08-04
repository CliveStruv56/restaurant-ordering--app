-- Debug Timeslot Generation - Comprehensive Check
-- Run this to diagnose why timeslots aren't being generated

-- 1. Check if we have restaurant settings
SELECT 'Restaurant Settings Check:' as step;
SELECT setting_key, setting_value FROM restaurant_settings ORDER BY setting_key;

-- 2. Check if we have opening hours
SELECT 'Opening Hours Check:' as step;
SELECT day_of_week, is_open, open_time, close_time FROM opening_hours ORDER BY day_of_week;

-- 3. Check what day of week today is
SELECT 'Today Info:' as step;
SELECT 
  CURRENT_DATE as today,
  EXTRACT(DOW FROM CURRENT_DATE) as day_of_week_number,
  CASE EXTRACT(DOW FROM CURRENT_DATE)
    WHEN 0 THEN 'Sunday'
    WHEN 1 THEN 'Monday' 
    WHEN 2 THEN 'Tuesday'
    WHEN 3 THEN 'Wednesday'
    WHEN 4 THEN 'Thursday'
    WHEN 5 THEN 'Friday'
    WHEN 6 THEN 'Saturday'
  END as day_name;

-- 4. Check if opening hours exist for today
SELECT 'Opening Hours for Today:' as step;
SELECT * FROM opening_hours WHERE day_of_week = EXTRACT(DOW FROM CURRENT_DATE);

-- 5. Manual step-by-step test
DO $$
DECLARE
  day_num INTEGER;
  opening_record RECORD;
  slot_time TIME;
  slot_interval INTEGER := 15;
  buffer_start INTEGER := 30;
  buffer_end INTEGER := 30;
  end_time TIME;
  test_date DATE := CURRENT_DATE;
  slot_count INTEGER := 0;
BEGIN
  RAISE NOTICE '=== DEBUGGING TIMESLOT GENERATION ===';
  
  -- Get day of week
  day_num := EXTRACT(DOW FROM test_date);
  RAISE NOTICE 'Testing for date: %, day of week: %', test_date, day_num;
  
  -- Get opening hours
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  IF NOT FOUND THEN
    RAISE NOTICE 'ERROR: No opening hours found for day %', day_num;
    RAISE NOTICE 'Available opening hours:';
    FOR opening_record IN SELECT * FROM opening_hours ORDER BY day_of_week LOOP
      RAISE NOTICE '  Day %: % - % (open: %)', opening_record.day_of_week, opening_record.open_time, opening_record.close_time, opening_record.is_open;
    END LOOP;
    RETURN;
  END IF;
  
  IF NOT opening_record.is_open THEN
    RAISE NOTICE 'Restaurant is closed on day % (%)', day_num, 
      CASE day_num WHEN 0 THEN 'Sunday' WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' 
           WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' WHEN 6 THEN 'Saturday' END;
    RETURN;
  END IF;
  
  RAISE NOTICE 'Restaurant hours: % to %', opening_record.open_time, opening_record.close_time;
  
  -- Get settings
  SELECT COALESCE(setting_value::INTEGER, 15) INTO slot_interval 
  FROM restaurant_settings WHERE setting_key = 'timeslot_interval_minutes';
  
  SELECT COALESCE(setting_value::INTEGER, 30) INTO buffer_start 
  FROM restaurant_settings WHERE setting_key = 'buffer_start_minutes';
  
  SELECT COALESCE(setting_value::INTEGER, 30) INTO buffer_end 
  FROM restaurant_settings WHERE setting_key = 'buffer_end_minutes';
  
  slot_interval := COALESCE(slot_interval, 15);
  buffer_start := COALESCE(buffer_start, 30);
  buffer_end := COALESCE(buffer_end, 30);
  
  RAISE NOTICE 'Settings - Interval: % min, Buffer start: % min, Buffer end: % min', 
    slot_interval, buffer_start, buffer_end;
  
  -- Calculate times
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  RAISE NOTICE 'First slot time: %, Last slot time: %', slot_time, end_time;
  
  IF slot_time > end_time THEN
    RAISE NOTICE 'ERROR: First slot time (%) is after last slot time (%). Buffers too large!', slot_time, end_time;
    RETURN;
  END IF;
  
  -- Test the loop
  WHILE slot_time <= end_time LOOP
    slot_count := slot_count + 1;
    RAISE NOTICE 'Slot %: %', slot_count, slot_time;
    
    -- Try to insert the slot
    BEGIN
      INSERT INTO timeslots (date, time, is_available)
      VALUES (test_date, slot_time, true);
      RAISE NOTICE '  -> Successfully inserted';
    EXCEPTION
      WHEN unique_violation THEN
        RAISE NOTICE '  -> Already exists';
      WHEN OTHERS THEN
        RAISE NOTICE '  -> Error: %', SQLERRM;
    END;
    
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
    
    -- Safety break to avoid infinite loop
    IF slot_count > 100 THEN
      RAISE NOTICE 'SAFETY BREAK: Generated % slots', slot_count;
      EXIT;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Total slots that should be created: %', slot_count;
END $$;

-- 6. Check what timeslots we have now
SELECT 'Current Timeslots:' as step;
SELECT date, time, is_available FROM timeslots WHERE date >= CURRENT_DATE ORDER BY date, time;

-- 7. Check the count
SELECT 'Timeslot Count:' as step;
SELECT 
  COUNT(*) as total_timeslots,
  COUNT(*) FILTER (WHERE date = CURRENT_DATE) as today_timeslots,
  COUNT(*) FILTER (WHERE date >= CURRENT_DATE) as future_timeslots
FROM timeslots;