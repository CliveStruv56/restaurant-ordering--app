-- Fix Categories Conflict
-- Run this BEFORE running other setup scripts if you get duplicate key errors

-- Option 1: Delete existing categories (WARNING: This will delete menu items too due to foreign key constraints)
-- DELETE FROM categories WHERE id = '550e8400-e29b-41d4-a716-446655440001';

-- Option 2: Use ON CONFLICT to avoid the error (safer approach)
-- Add this to any INSERT statements for categories:
-- INSERT INTO categories (id, name, description, sort_order) VALUES
--   ('550e8400-e29b-41d4-a716-446655440001', 'Appetizers', 'Start your meal with our delicious appetizers', 1)
-- ON CONFLICT (id) DO NOTHING;

-- Option 3: Check what categories already exist
SELECT id, name, description FROM categories ORDER BY sort_order;