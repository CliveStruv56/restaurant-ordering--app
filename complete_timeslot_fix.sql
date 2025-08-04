-- Complete Timeslot System Fix
-- Run this script to fix all timeslot issues

-- 1. Create the missing available_timeslots view
DROP VIEW IF EXISTS available_timeslots;

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

-- 2. Clear all existing future timeslots
DELETE FROM timeslots WHERE date >= CURRENT_DATE;

-- 3. Ensure restaurant settings exist with current values
INSERT INTO restaurant_settings (setting_key, setting_value, description) VALUES
  ('timeslot_interval_minutes', '45', 'Time interval between slots in minutes'),
  ('buffer_start_minutes', '30', 'Buffer time at start of day in minutes'),
  ('buffer_end_minutes', '30', 'Buffer time at end of day in minutes'),
  ('max_orders_per_slot', '10', 'Maximum orders allowed per timeslot'),
  ('advance_booking_days', '7', 'How many days in advance customers can book'),
  ('restaurant_name', 'Restaurant Name', 'Name of the restaurant'),
  ('restaurant_phone', '+44 123 456 7890', 'Restaurant contact phone'),
  ('restaurant_email', 'info@restaurant.com', 'Restaurant contact email')
ON CONFLICT (setting_key) DO UPDATE SET
  setting_value = EXCLUDED.setting_value,
  updated_at = NOW();

-- 4. Ensure opening hours exist
INSERT INTO opening_hours (day_of_week, is_open, open_time, close_time) VALUES
  (0, true, '10:00', '21:00'), -- Sunday
  (1, true, '09:00', '22:00'), -- Monday
  (2, true, '09:00', '22:00'), -- Tuesday
  (3, true, '09:00', '22:00'), -- Wednesday
  (4, true, '09:00', '22:00'), -- Thursday
  (5, true, '09:00', '23:00'), -- Friday
  (6, true, '10:00', '23:00')  -- Saturday
ON CONFLICT (day_of_week) DO UPDATE SET
  is_open = EXCLUDED.is_open,
  open_time = EXCLUDED.open_time,
  close_time = EXCLUDED.close_time,
  updated_at = NOW();

-- 5. Generate new timeslots with correct intervals
SELECT generate_upcoming_timeslots() as timeslots_generated;

-- 6. Show the results
SELECT 'Current Settings:' as step;
SELECT setting_key, setting_value FROM restaurant_settings 
WHERE setting_key IN ('timeslot_interval_minutes', 'buffer_start_minutes', 'buffer_end_minutes')
ORDER BY setting_key;

SELECT 'Sample Timeslots:' as step;
SELECT 
  DATE(date) as date,
  time,
  LAG(time) OVER (PARTITION BY date ORDER BY time) as previous_time,
  time - LAG(time) OVER (PARTITION BY date ORDER BY time) as interval_from_previous
FROM timeslots 
WHERE date >= CURRENT_DATE
ORDER BY date, time 
LIMIT 15;

SELECT 'Timeslot Count by Date:' as step;
SELECT DATE(date) as date, COUNT(*) as timeslot_count 
FROM timeslots 
WHERE date >= CURRENT_DATE
GROUP BY DATE(date) 
ORDER BY date;

SELECT 'Available Timeslots View Test:' as step;
SELECT COUNT(*) as available_count FROM available_timeslots;