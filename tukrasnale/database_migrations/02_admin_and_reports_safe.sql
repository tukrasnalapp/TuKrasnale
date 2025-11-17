-- Step-by-step migration for existing databases
-- Run this if you already have some tables created

-- Step 1: Create user_profiles table (safe to run if exists)
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Add role column if table existed without it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='role') THEN
        ALTER TABLE user_profiles ADD COLUMN role TEXT DEFAULT 'user';
    END IF;
END $$;

-- Step 3: Enable RLS (safe to run multiple times)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop existing policies to avoid conflicts (safe if they don't exist)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;

-- Step 5: Create policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles up
            WHERE up.user_id = auth.uid() 
            AND up.role = 'admin'
        )
    );

-- Step 6: Create index
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- Step 7: Create krasnale_reports table
CREATE TABLE IF NOT EXISTS krasnale_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  krasnal_id UUID REFERENCES krasnale(id),
  report_type TEXT NOT NULL CHECK (report_type IN ('missing', 'wrong_location', 'wrong_info', 'damaged', 'new_suggestion', 'other')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  photo_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'resolved', 'rejected')),
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 8: Enable RLS for reports
ALTER TABLE krasnale_reports ENABLE ROW LEVEL SECURITY;

-- Step 9: Drop existing report policies (safe if they don't exist)
DROP POLICY IF EXISTS "Users can insert their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON krasnale_reports;
DROP POLICY IF EXISTS "Admins can manage all reports" ON krasnale_reports;

-- Step 10: Create report policies
CREATE POLICY "Users can insert their own reports" ON krasnale_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own reports" ON krasnale_reports
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all reports" ON krasnale_reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Step 11: Update krasnale table (safe to run multiple times)
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS undiscovered_medallion_url TEXT;
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS discovered_medallion_url TEXT;
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS gallery_images TEXT[];

-- Step 12: Drop existing krasnale policy (safe if it doesn't exist)
DROP POLICY IF EXISTS "Admins can manage krasnale" ON krasnale;

-- Step 13: Create krasnale admin policy
CREATE POLICY "Admins can manage krasnale" ON krasnale
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );