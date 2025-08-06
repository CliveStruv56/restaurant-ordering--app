-- Test Timeslot Generation with Different Intervals
-- Run this to test if the functions properly use the settings

-- 1. Show current interval setting
SELECT 'Current interval setting:' as step;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key = 'timeslot_interval_minutes';

-- 2. Clear existing timeslots
DELETE FROM timeslots WHERE date >= CURRENT_DATE;

-- 3. Set interval to 30 minutes for testing
UPDATE restaurant_settings 
SET setting_value = '30', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

-- 4. Generate timeslots for today
SELECT 'Generating with 30-minute interval:' as step;
SELECT generate_timeslots_for_date(CURRENT_DATE) as slots_created;

-- 5. Show the generated timeslots
SELECT 'Timeslots with 30-minute interval:' as step;
SELECT time FROM timeslots 
WHERE date = CURRENT_DATE 
ORDER BY time 
LIMIT 10;

-- 6. Clear and test with 60 minutes
DELETE FROM timeslots WHERE date >= CURRENT_DATE;

UPDATE restaurant_settings 
SET setting_value = '60', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

SELECT 'Generating with 60-minute interval:' as step;
SELECT generate_timeslots_for_date(CURRENT_DATE) as slots_created;

SELECT 'Timeslots with 60-minute interval:' as step;
SELECT time FROM timeslots 
WHERE date = CURRENT_DATE 
ORDER BY time;

-- 7. Reset to desired value (45 minutes)
UPDATE restaurant_settings 
SET setting_value = '45', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

-- 8. Clear and regenerate with 45 minutes
DELETE FROM timeslots WHERE date >= CURRENT_DATE;
SELECT 'Final generation with 45-minute interval:' as step;
SELECT generate_upcoming_timeslots() as total_slots_created;

-- 9. Verify final results
SELECT 'Final timeslots (first 10):' as step;
SELECT date, time FROM timeslots 
WHERE date >= CURRENT_DATE 
ORDER BY date, time 
LIMIT 10;