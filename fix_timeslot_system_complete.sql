-- Complete Timeslot System Fix
-- This ensures all timeslots are correctly generated and filtered

-- 1. First check what we have
SELECT 'Current timeslots:' as info;
SELECT 
  date,
  time,
  CASE 
    WHEN date < CURRENT_DATE THEN 'Past Date'
    WHEN date = CURRENT_DATE AND time::time <= CURRENT_TIME THEN 'Past Time Today'
    WHEN date = CURRENT_DATE AND time::time > CURRENT_TIME THEN 'Future Time Today'
    ELSE 'Future Date'
  END as status
FROM timeslots 
ORDER BY date, time
LIMIT 20;

-- 2. Clean up any invalid data
-- Remove timeslots from the past
DELETE FROM timeslots WHERE date < CURRENT_DATE;

-- Remove past timeslots for today
DELETE FROM timeslots 
WHERE date = CURRENT_DATE 
AND time::time <= CURRENT_TIME;

-- Remove any timeslots with invalid years (like 2025 if we're in 2024)
DELETE FROM timeslots WHERE EXTRACT(YEAR FROM date) > EXTRACT(YEAR FROM CURRENT_DATE) + 1;

SELECT 'Cleaned up old/invalid timeslots' as info;

-- 3. Recreate the available_timeslots view with better filtering
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
  AND (
    -- For future dates, show all slots
    t.date > CURRENT_DATE
    OR 
    -- For today, only show slots at least 15 minutes in the future
    (t.date = CURRENT_DATE AND t.time::time > (CURRENT_TIME + INTERVAL '15 minutes'))
  )
  AND COALESCE(oh.is_open, true) = true
ORDER BY t.date, t.time;

GRANT SELECT ON available_timeslots TO anon, authenticated;

-- 4. Regenerate timeslots for the next 7 days with current settings
SELECT 'Regenerating timeslots...' as info;
SELECT generate_upcoming_timeslots() as slots_generated;

-- 5. Verify the results
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

-- 6. Show sample timeslots
SELECT 'Sample future timeslots:' as info;
SELECT 
  date,
  time,
  current_orders || '/' || max_orders as capacity
FROM timeslots
WHERE date >= CURRENT_DATE
  AND (date > CURRENT_DATE OR time::time > CURRENT_TIME)
ORDER BY date, time
LIMIT 15;

-- 7. Test the view
SELECT 'Available timeslots from view:' as info;
SELECT 
  date,
  time,
  has_capacity,
  restaurant_open
FROM available_timeslots
LIMIT 10;