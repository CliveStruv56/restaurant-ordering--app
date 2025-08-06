-- Fix Maintenance Function
-- This creates the missing maintenance functions

-- ============================================
-- STEP 1: Create the maintenance function
-- ============================================
DROP FUNCTION IF EXISTS trigger_timeslot_maintenance();
DROP FUNCTION IF EXISTS run_timeslot_maintenance();
DROP FUNCTION IF EXISTS maintain_timeslots();

-- Create the main maintenance function
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
    SELECT COALESCE(setting_value::INTEGER, 7) INTO advance_days
    FROM restaurant_settings WHERE setting_key = 'advance_booking_days';
  EXCEPTION WHEN OTHERS THEN
    advance_days := 7;
  END;
  
  RAISE NOTICE 'Starting maintenance for % days', advance_days;
  
  -- Delete old timeslots (before today)
  DELETE FROM timeslots WHERE date < CURRENT_DATE;
  GET DIAGNOSTICS slots_deleted = ROW_COUNT;
  
  RAISE NOTICE 'Deleted % old timeslots', slots_deleted;
  
  -- Delete timeslots beyond advance booking window
  DELETE FROM timeslots WHERE date > CURRENT_DATE + (advance_days || ' days')::INTERVAL;
  
  -- Generate timeslots for missing days
  FOR i IN 0..(advance_days - 1) LOOP
    target_date := CURRENT_DATE + i;
    
    -- Check if timeslots already exist for this date
    IF NOT EXISTS (SELECT 1 FROM timeslots WHERE date = target_date LIMIT 1) THEN
      -- Generate timeslots for this date
      SELECT generate_timeslots_for_date(target_date) INTO day_slots;
      slots_created := slots_created + day_slots;
      days_processed := days_processed + 1;
      RAISE NOTICE 'Generated % slots for %', day_slots, target_date;
    ELSE
      RAISE NOTICE 'Timeslots already exist for %', target_date;
    END IF;
  END LOOP;
  
  -- Build result JSON
  result := json_build_object(
    'execution_time', NOW(),
    'slots_deleted', slots_deleted,
    'slots_created', slots_created,
    'days_processed', days_processed,
    'advance_days', advance_days,
    'success', true
  );
  
  RAISE NOTICE 'Maintenance complete: created %, deleted %', slots_created, slots_deleted;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create the log table if it doesn't exist
CREATE TABLE IF NOT EXISTS timeslot_maintenance_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  execution_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  result JSON,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the run and log function
CREATE OR REPLACE FUNCTION run_timeslot_maintenance()
RETURNS JSON AS $$
DECLARE
  maintenance_result JSON;
BEGIN
  -- Run maintenance
  SELECT maintain_timeslots() INTO maintenance_result;
  
  -- Log the result
  INSERT INTO timeslot_maintenance_log (result)
  VALUES (maintenance_result);
  
  -- Clean up old logs (keep only last 30 days)
  DELETE FROM timeslot_maintenance_log 
  WHERE created_at < NOW() - INTERVAL '30 days';
  
  RETURN maintenance_result;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger function (this is what the app calls)
CREATE OR REPLACE FUNCTION trigger_timeslot_maintenance()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  RAISE NOTICE 'Triggering timeslot maintenance...';
  
  -- Run the maintenance and return result
  SELECT run_timeslot_maintenance() INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 2: Test the functions
-- ============================================

-- Test the maintenance function
SELECT 'Testing maintenance function...' as info;
SELECT trigger_timeslot_maintenance() as test_result;

-- Show current timeslots
SELECT 'Current timeslots by date:' as info;
SELECT 
  date,
  COUNT(*) as slot_count,
  MIN(time) as first_slot,
  MAX(time) as last_slot
FROM timeslots
WHERE date >= CURRENT_DATE
GROUP BY date
ORDER BY date;

-- Show maintenance log
SELECT 'Latest maintenance log:' as info;
SELECT 
  execution_time,
  result->>'slots_created' as created,
  result->>'slots_deleted' as deleted,
  result->>'days_processed' as days_processed
FROM timeslot_maintenance_log
ORDER BY execution_time DESC
LIMIT 3;