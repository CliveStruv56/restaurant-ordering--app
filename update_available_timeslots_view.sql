-- Update Available Timeslots View to Filter Past Times
-- This ensures we only show future timeslots

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
    -- Show all timeslots for future dates
    t.date > CURRENT_DATE
    OR 
    -- For today, only show future timeslots
    (t.date = CURRENT_DATE AND t.time > CURRENT_TIME)
  )
  AND COALESCE(oh.is_open, true) = true
ORDER BY t.date, t.time;

-- Grant permissions on the view
GRANT SELECT ON available_timeslots TO anon, authenticated;

-- Test the view
SELECT 'Testing available_timeslots view with time filtering:' as info;
SELECT 
  date,
  time,
  CASE 
    WHEN date = CURRENT_DATE AND time <= CURRENT_TIME THEN 'Past (hidden)'
    WHEN date = CURRENT_DATE AND time > CURRENT_TIME THEN 'Today Future'
    ELSE 'Future Date'
  END as status
FROM timeslots 
WHERE date >= CURRENT_DATE
ORDER BY date, time
LIMIT 20;