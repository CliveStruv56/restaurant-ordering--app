-- Create Available Timeslots View
-- This view is required for the timeslot management functionality

-- Drop the view if it exists
DROP VIEW IF EXISTS available_timeslots;

-- Create the available_timeslots view
CREATE VIEW available_timeslots AS
SELECT 
  t.*,
  (t.current_orders < COALESCE(
    (SELECT setting_value::INTEGER FROM restaurant_settings WHERE setting_key = 'max_orders_per_slot'),
    10
  )) AS has_capacity,
  oh.is_open AS restaurant_open
FROM timeslots t
JOIN opening_hours oh ON oh.day_of_week = EXTRACT(DOW FROM t.date)
WHERE t.is_available = true
  AND t.date >= CURRENT_DATE
  AND oh.is_open = true
ORDER BY t.date, t.time;

-- Test the view
SELECT 'Available Timeslots View Test:' as step;
SELECT COUNT(*) as available_timeslots_count FROM available_timeslots;

-- Show sample data
SELECT 'Sample Available Timeslots:' as step;
SELECT date, time, current_orders, max_orders, has_capacity 
FROM available_timeslots 
ORDER BY date, time 
LIMIT 10;