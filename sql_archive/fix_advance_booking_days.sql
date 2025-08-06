-- FIX ADVANCE BOOKING DAYS FUNCTIONALITY
-- This ensures timeslot generation respects the advance_booking_days setting

-- ============================================
-- STEP 1: Drop old hardcoded function
-- ============================================
DROP FUNCTION IF EXISTS generate_upcoming_timeslots();

-- ============================================
-- STEP 2: Create function that uses advance_booking_days
-- ============================================
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
  
  -- Get advance booking days setting from database
  SELECT COALESCE(setting_value::INTEGER, 7) INTO advance_days
  FROM restaurant_settings 
  WHERE setting_key = 'advance_booking_days';
  
  -- Default to 7 if not found
  IF advance_days IS NULL THEN
    advance_days := 7;
  END IF;
  
  RAISE NOTICE 'Generating timeslots for % days ahead', advance_days;
  
  -- Generate for the configured number of days
  FOR i IN 0..(advance_days - 1) LOOP
    day_slots := generate_timeslots_for_date(start_date + i);
    total_slots := total_slots + day_slots;
    RAISE NOTICE 'Generated % slots for %', day_slots, start_date + i;
  END LOOP;
  
  RAISE NOTICE 'Total slots generated: %', total_slots;
  RETURN total_slots;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 3: Test with current settings
-- ============================================
SELECT 'Current advance_booking_days setting:' as info;
SELECT setting_value FROM restaurant_settings WHERE setting_key = 'advance_booking_days';

-- ============================================
-- STEP 4: Clear old timeslots and regenerate
-- ============================================
DELETE FROM timeslots WHERE date >= CURRENT_DATE;

SELECT 'Regenerating timeslots with correct advance_booking_days...' as info;
SELECT generate_upcoming_timeslots() as slots_generated;

-- ============================================
-- STEP 5: Verify results
-- ============================================
SELECT 'Timeslots by date (should match advance_booking_days):' as info;
SELECT 
  date,
  COUNT(*) as slot_count,
  MIN(time) as first_slot,
  MAX(time) as last_slot
FROM timeslots
WHERE date >= CURRENT_DATE
GROUP BY date
ORDER BY date;

SELECT 'Total days with timeslots:' as info;
SELECT COUNT(DISTINCT date) as days_with_slots
FROM timeslots
WHERE date >= CURRENT_DATE;