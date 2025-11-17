-- Phase 1 Database Schema: Core Discovery System
-- Features: GPS discovery, card collection, basic user profiles
-- Execute this first to create the foundation tables

-- Users table (essential user data only)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    krasnale_discovered INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Krasnale (Dwarf sculptures) - core data
CREATE TABLE public.krasnale (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    history TEXT,
    location_name VARCHAR(200),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    image_url TEXT,
    model_3d_url TEXT,
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    discovery_radius INTEGER DEFAULT 30, -- meters for GPS detection
    points_value INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- User discoveries (tracking which krasnale users have found)
CREATE TABLE public.user_discoveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    krasnal_id UUID REFERENCES public.krasnale(id) ON DELETE CASCADE,
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    discovery_location_lat DECIMAL(10, 8),
    discovery_location_lng DECIMAL(11, 8),
    UNIQUE(user_id, krasnal_id)
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.krasnale ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_discoveries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Phase 1
-- Users can view all public user profiles
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.users FOR SELECT 
USING (true);

-- Users can update only their own profile
CREATE POLICY "Users can update own profile" 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

-- Anyone can view active krasnale (public data)
CREATE POLICY "Active krasnale are publicly viewable" 
ON public.krasnale FOR SELECT 
USING (is_active = true);

-- Users can view their own discoveries
CREATE POLICY "Users can view own discoveries" 
ON public.user_discoveries FOR SELECT 
USING (auth.uid() = user_id);

-- Users can insert their own discoveries
CREATE POLICY "Users can insert own discoveries" 
ON public.user_discoveries FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Functions for game mechanics
-- Function to update user stats when discovering a krasnal
CREATE OR REPLACE FUNCTION update_user_discovery_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user's discovery count and score
    UPDATE public.users 
    SET 
        krasnale_discovered = krasnale_discovered + 1,
        total_score = total_score + (
            SELECT points_value 
            FROM public.krasnale 
            WHERE id = NEW.krasnal_id
        ),
        updated_at = now()
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update stats
CREATE TRIGGER update_discovery_stats
    AFTER INSERT ON public.user_discoveries
    FOR EACH ROW
    EXECUTE FUNCTION update_user_discovery_stats();

-- View for leaderboard (simple version for Phase 1)
CREATE VIEW public.leaderboard AS
SELECT 
    username,
    display_name,
    krasnale_discovered,
    total_score,
    RANK() OVER (ORDER BY total_score DESC) as rank
FROM public.users
WHERE krasnale_discovered > 0
ORDER BY total_score DESC;

-- Grant permissions for the view
GRANT SELECT ON public.leaderboard TO anon, authenticated;

-- Function to check if user can discover a krasnal (distance-based)
CREATE OR REPLACE FUNCTION can_discover_krasnal(
    user_lat DECIMAL(10, 8),
    user_lng DECIMAL(11, 8),
    krasnal_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    krasnal_lat DECIMAL(10, 8);
    krasnal_lng DECIMAL(11, 8);
    discovery_radius INTEGER;
    distance_meters FLOAT;
BEGIN
    -- Get krasnal location and radius
    SELECT latitude, longitude, discovery_radius 
    INTO krasnal_lat, krasnal_lng, discovery_radius
    FROM public.krasnale 
    WHERE id = krasnal_uuid AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Calculate distance using Haversine formula (simplified)
    distance_meters := 6371000 * acos(
        cos(radians(user_lat)) * cos(radians(krasnal_lat)) * 
        cos(radians(krasnal_lng) - radians(user_lng)) + 
        sin(radians(user_lat)) * sin(radians(krasnal_lat))
    );
    
    RETURN distance_meters <= discovery_radius;
END;
$$ LANGUAGE plpgsql;