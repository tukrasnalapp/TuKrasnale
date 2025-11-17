-- Create user_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own profile (for registration)
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles up
            WHERE up.user_id = auth.uid() 
            AND up.role = 'admin'
        )
    );

-- Create index for role lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- Create krasnale_reports table for user issue reports
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

-- Add RLS policies for reports
ALTER TABLE krasnale_reports ENABLE ROW LEVEL SECURITY;

-- Users can insert their own reports and view them
CREATE POLICY "Users can insert their own reports" ON krasnale_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own reports" ON krasnale_reports
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can view and manage all reports
CREATE POLICY "Admins can manage all reports" ON krasnale_reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Update krasnale table to support multiple images
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS undiscovered_medallion_url TEXT;
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS discovered_medallion_url TEXT;
ALTER TABLE krasnale ADD COLUMN IF NOT EXISTS gallery_images TEXT[]; -- Array of image URLs

-- Add admin policy for krasnale management
CREATE POLICY "Admins can manage krasnale" ON krasnale
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );