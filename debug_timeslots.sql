-- Debug Timeslot Generation
-- Run this to see what's happening step by step

-- 1. Check if we have restaurant settings
SELECT 'Restaurant Settings:' as debug_step;
SELECT setting_key, setting_value FROM restaurant_settings ORDER BY setting_key;

-- 2. Check if we have opening hours
SELECT 'Opening Hours:' as debug_step;
SELECT day_of_week, is_open, open_time, close_time FROM opening_hours ORDER BY day_of_week;

-- 3. Check what day of week today is
SELECT 'Today Info:' as debug_step;
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
SELECT 'Opening Hours for Today:' as debug_step;
SELECT * FROM opening_hours WHERE day_of_week = EXTRACT(DOW FROM CURRENT_DATE);

-- 5. Test generating timeslots for today manually
SELECT 'Manual Test for Today:' as debug_step;

DO $$
DECLARE
  day_num INTEGER;
  opening_record RECORD;
  slot_time TIME;
  slot_interval INTEGER := 30; -- Your current setting
  buffer_start INTEGER := 30;
  buffer_end INTEGER := 30;
  end_time TIME;
  test_date DATE := CURRENT_DATE;
BEGIN
  -- Get day of week
  day_num := EXTRACT(DOW FROM test_date);
  RAISE NOTICE 'Testing for date: %, day of week: %', test_date, day_num;
  
  -- Get opening hours
  SELECT * INTO opening_record FROM opening_hours WHERE day_of_week = day_num;
  
  IF NOT FOUND THEN
    RAISE NOTICE 'No opening hours found for day %', day_num;
    RETURN;
  END IF;
  
  IF NOT opening_record.is_open THEN
    RAISE NOTICE 'Restaurant is closed on day %', day_num;
    RETURN;
  END IF;
  
  RAISE NOTICE 'Restaurant hours: % to %', opening_record.open_time, opening_record.close_time;
  
  -- Calculate times
  slot_time := opening_record.open_time + (buffer_start || ' minutes')::INTERVAL;
  end_time := opening_record.close_time - (buffer_end || ' minutes')::INTERVAL;
  
  RAISE NOTICE 'First slot time: %, Last slot time: %', slot_time, end_time;
  RAISE NOTICE 'Slot interval: % minutes', slot_interval;
  
  -- Test the loop
  WHILE slot_time <= end_time LOOP
    RAISE NOTICE 'Would create slot at: %', slot_time;
    
    -- Insert the slot
    BEGIN
      INSERT INTO timeslots (date, time, is_available)
      VALUES (test_date, slot_time, true);
      RAISE NOTICE 'Successfully inserted slot: %', slot_time;
    EXCEPTION
      WHEN unique_violation THEN
        RAISE NOTICE 'Slot already exists: %', slot_time;
      WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting slot %: %', slot_time, SQLERRM;
    END;
    
    slot_time := slot_time + (slot_interval || ' minutes')::INTERVAL;
  END LOOP;
  
END $$;

-- 6. Check what timeslots we have now
SELECT 'Current Timeslots:' as debug_step;
SELECT date, time, is_available FROM timeslots ORDER BY date, time;

-- 7. Check the count
SELECT 'Timeslot Count:' as debug_step;
SELECT COUNT(*) as total_timeslots FROM timeslots;