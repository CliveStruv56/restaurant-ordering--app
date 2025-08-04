-- Simple Cleanup Script
-- Run this FIRST to clean up any existing data and start fresh

-- Drop existing functions and triggers first
DROP TRIGGER IF EXISTS orders_timeslot_update ON public.orders;
DROP FUNCTION IF EXISTS update_timeslot_order_count();
DROP FUNCTION IF EXISTS generate_upcoming_timeslots();
DROP FUNCTION IF EXISTS generate_timeslots_for_date(DATE);

-- Drop existing view
DROP VIEW IF EXISTS available_timeslots;

-- Clear existing data only (don't drop tables)
TRUNCATE TABLE timeslots CASCADE;
TRUNCATE TABLE opening_hours CASCADE; 
TRUNCATE TABLE restaurant_settings CASCADE;

-- Now run the main setup script after this