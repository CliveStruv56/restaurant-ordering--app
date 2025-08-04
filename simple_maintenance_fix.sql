-- SIMPLE MAINTENANCE FIX
-- This is a minimal version that should work

-- Check if the function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'trigger_timeslot_maintenance';

-- Create a simple version
CREATE OR REPLACE FUNCTION trigger_timeslot_maintenance()
RETURNS JSON AS $$
DECLARE
  advance_days INTEGER := 7;
  slots_deleted INTEGER := 0;
  slots_created INTEGER := 0;
  target_date DATE;
  day_slots INTEGER;
BEGIN
  -- Get advance booking days setting (with fallback)
  SELECT COALESCE(setting_value::INTEGER, 7) INTO advance_days
  FROM restaurant_settings 
  WHERE setting_key = 'advance_booking_days';
  
  IF advance_days IS NULL THEN
    advance_days := 7;
  END IF;
  
  -- Delete old timeslots
  DELETE FROM timeslots WHERE date < CURRENT_DATE;
  GET DIAGNOSTICS slots_deleted = ROW_COUNT;
  
  -- Generate missing timeslots
  FOR i IN 0..(advance_days - 1) LOOP
    target_date := CURRENT_DATE + i;
    
    -- Only generate if none exist for this date
    IF NOT EXISTS (SELECT 1 FROM timeslots WHERE date = target_date LIMIT 1) THEN
      SELECT generate_timeslots_for_date(target_date) INTO day_slots;
      slots_created := slots_created + COALESCE(day_slots, 0);
    END IF;
  END LOOP;
  
  -- Return simple JSON result
  RETURN json_build_object(
    'slots_created', slots_created,
    'slots_deleted', slots_deleted,
    'advance_days', advance_days,
    'success', true
  );
END;
$$ LANGUAGE plpgsql;

-- Test it
SELECT 'Testing simple maintenance...' as info;
SELECT trigger_timeslot_maintenance() as result;

-- Show what we have
SELECT 'Timeslots after maintenance:' as info;
SELECT date, COUNT(*) as slots
FROM timeslots 
WHERE date >= CURRENT_DATE
GROUP BY date
ORDER BY date;