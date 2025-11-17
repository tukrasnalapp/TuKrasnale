-- Quick fix for krasnale insert issues
-- Run this in your Supabase SQL editor to diagnose and fix the problem

-- 1. Check if krasnale table exists and its structure
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'krasnale' 
ORDER BY ordinal_position;

-- 2. Check current RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'krasnale';

-- 3. Check existing policies
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'krasnale';

-- 4. TEMPORARY FIX: Disable RLS on krasnale table for testing
-- (You can re-enable it later with proper policies)
ALTER TABLE krasnale DISABLE ROW LEVEL SECURITY;

-- 5. Check if you have an admin user profile
-- Replace 'your-user-id' with your actual user ID
SELECT user_id, username, role 
FROM user_profiles 
WHERE role = 'admin';

-- 6. If no admin exists, create one (replace with your user ID and email)
-- Get your user ID first:
SELECT id, email FROM auth.users;

-- Then create admin profile (replace 'YOUR_USER_ID' with actual ID):
INSERT INTO user_profiles (user_id, username, full_name, role, created_at, updated_at)
VALUES (
  'YOUR_USER_ID',  -- Replace with your actual user ID
  'admin',
  'Administrator',
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (user_id) DO UPDATE SET 
  role = 'admin',
  updated_at = NOW();

-- 7. Test insert (should work now):
INSERT INTO krasnale (
  name, 
  description, 
  latitude, 
  longitude, 
  location_name, 
  rarity, 
  points_value,
  is_active,
  created_at,
  updated_at
) VALUES (
  'Debug Test Krasnal', 
  'Test krasnal to verify insert permissions', 
  51.1079, 
  17.0385, 
  'Debug Location',
  'common',
  10,
  true,
  NOW(),
  NOW()
) RETURNING id, name, created_at;