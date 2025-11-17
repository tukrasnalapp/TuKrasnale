-- Quick fix: Temporarily disable RLS for development
-- Run this if you're still getting recursion errors

-- Disable RLS on user_profiles (temporarily)
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Disable RLS on krasnale (temporarily) 
ALTER TABLE krasnale DISABLE ROW LEVEL SECURITY;

-- Keep RLS on reports but with simpler policies
ALTER TABLE krasnale_reports ENABLE ROW LEVEL SECURITY;

-- Drop all existing report policies
DROP POLICY IF EXISTS "Users can insert their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Admins can manage all reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Admin users can manage all reports" ON krasnale_reports;

-- Simple report policies
CREATE POLICY "Users can manage their own reports" ON krasnale_reports
    FOR ALL USING (auth.uid() = user_id);

-- Note: This is for development only. 
-- In production, you'll want to re-enable RLS with proper policies.