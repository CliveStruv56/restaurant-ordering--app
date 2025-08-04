-- Test Interval Change Process
-- Run this to test if interval changes are working correctly

-- Step 1: Show current interval setting
SELECT 'Step 1 - Current interval setting:' as test_step;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key = 'timeslot_interval_minutes';

-- Step 2: Clear all timeslots
DELETE FROM timeslots WHERE date >= CURRENT_DATE;
SELECT 'Step 2 - Cleared all future timeslots' as test_step;

-- Step 3: Set interval to 20 minutes
UPDATE restaurant_settings 
SET setting_value = '20', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

SELECT 'Step 3 - Updated interval to 20 minutes:' as test_step;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key = 'timeslot_interval_minutes';

-- Step 4: Generate timeslots for today only
SELECT 'Step 4 - Generating timeslots for today with 20-minute interval:' as test_step;
SELECT generate_timeslots_for_date(CURRENT_DATE) as slots_created;

-- Step 5: Check the intervals
SELECT 'Step 5 - Verifying 20-minute intervals:' as test_step;
SELECT time FROM timeslots 
WHERE date = CURRENT_DATE 
ORDER BY time 
LIMIT 10;

-- Step 6: Clear and change to 60 minutes
DELETE FROM timeslots WHERE date >= CURRENT_DATE;

UPDATE restaurant_settings 
SET setting_value = '60', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

SELECT 'Step 6 - Updated interval to 60 minutes:' as test_step;
SELECT setting_key, setting_value 
FROM restaurant_settings 
WHERE setting_key = 'timeslot_interval_minutes';

-- Step 7: Generate with 60-minute interval
SELECT 'Step 7 - Generating timeslots with 60-minute interval:' as test_step;
SELECT generate_timeslots_for_date(CURRENT_DATE) as slots_created;

-- Step 8: Verify 60-minute intervals
SELECT 'Step 8 - Verifying 60-minute intervals:' as test_step;
SELECT time FROM timeslots 
WHERE date = CURRENT_DATE 
ORDER BY time;

-- Step 9: Reset to desired value (e.g., 45 minutes)
UPDATE restaurant_settings 
SET setting_value = '45', updated_at = NOW()
WHERE setting_key = 'timeslot_interval_minutes';

SELECT 'Step 9 - Reset to 45 minutes' as test_step;