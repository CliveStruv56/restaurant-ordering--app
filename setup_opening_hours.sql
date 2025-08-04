-- Setup Opening Hours and Restaurant Settings
-- Run this to ensure you have the required data for timeslot generation

-- 1. Check current opening hours
SELECT 'Current Opening Hours:' as step;
SELECT day_of_week, is_open, open_time, close_time FROM opening_hours ORDER BY day_of_week;

-- 2. Insert default opening hours if they don't exist
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

-- 3. Check current restaurant settings
SELECT 'Current Restaurant Settings:' as step;
SELECT setting_key, setting_value FROM restaurant_settings ORDER BY setting_key;

-- 4. Insert default restaurant settings if they don't exist
INSERT INTO restaurant_settings (setting_key, setting_value, description) VALUES
  ('timeslot_interval_minutes', '15', 'Time interval between slots in minutes'),
  ('buffer_start_minutes', '30', 'Buffer time at start of day in minutes'),
  ('buffer_end_minutes', '30', 'Buffer time at end of day in minutes'),
  ('max_orders_per_slot', '10', 'Maximum orders allowed per timeslot'),
  ('advance_booking_days', '7', 'How many days in advance customers can book'),
  ('restaurant_name', 'Restaurant Name', 'Name of the restaurant'),
  ('restaurant_phone', '+44 123 456 7890', 'Restaurant contact phone'),
  ('restaurant_email', 'info@restaurant.com', 'Restaurant contact email')
ON CONFLICT (setting_key) DO NOTHING;

-- 5. Verify the data is now available
SELECT 'Final Opening Hours:' as step;
SELECT 
  day_of_week,
  CASE day_of_week 
    WHEN 0 THEN 'Sunday'
    WHEN 1 THEN 'Monday'
    WHEN 2 THEN 'Tuesday'
    WHEN 3 THEN 'Wednesday'
    WHEN 4 THEN 'Thursday'
    WHEN 5 THEN 'Friday'
    WHEN 6 THEN 'Saturday'
  END as day_name,
  is_open, 
  open_time, 
  close_time 
FROM opening_hours 
ORDER BY day_of_week;

SELECT 'Final Restaurant Settings:' as step;
SELECT setting_key, setting_value FROM restaurant_settings ORDER BY setting_key;

-- 6. Test timeslot generation for today
SELECT 'Testing Timeslot Generation:' as step;
SELECT generate_timeslots_for_date(CURRENT_DATE) as slots_created_today;

-- 7. Show created timeslots
SELECT 'Created Timeslots:' as step;
SELECT date, time, is_available 
FROM timeslots 
WHERE date >= CURRENT_DATE 
ORDER BY date, time 
LIMIT 20;