-- Comprehensive RLS fix - handles all existing policies safely
-- This migration will completely reset RLS policies to fix recursion

-- Method 1: Disable RLS temporarily on all tables to clear everything
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE krasnale_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE krasnale DISABLE ROW LEVEL SECURITY;

-- Method 2: Drop all existing policies manually (comprehensive list)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Public profile read access" ON user_profiles;

DROP POLICY IF EXISTS "Users can insert their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Users can manage their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Admins can manage all reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Admin users can manage all reports" ON krasnale_reports;

DROP POLICY IF EXISTS "Admins can manage krasnale" ON krasnale;
DROP POLICY IF EXISTS "Admin users can manage krasnale" ON krasnale;

-- Method 3: Re-enable RLS and create simple policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE krasnale_reports ENABLE ROW LEVEL SECURITY;
-- Keep krasnale without RLS for now

-- Simple user profile policies (no recursion)
CREATE POLICY "user_profile_own_access" ON user_profiles
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "user_profile_public_read" ON user_profiles
    FOR SELECT USING (true);

-- Simple report policies (no admin checks)
CREATE POLICY "user_reports_own_access" ON krasnale_reports
    FOR ALL USING (auth.uid() = user_id);

-- Note: krasnale table has no RLS for now - will be handled in app layer