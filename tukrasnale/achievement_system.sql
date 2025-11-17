-- Achievement System Database Schema for TuKrasnal
-- This extends the Phase 1 schema with achievement functionality

-- Achievements table - defines all available achievements
CREATE TABLE public.achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('discovery', 'collection', 'social', 'exploration', 'special')),
    rarity VARCHAR(20) DEFAULT 'bronze' CHECK (rarity IN ('bronze', 'silver', 'gold', 'platinum')),
    requirement_type VARCHAR(50) NOT NULL, -- 'krasnale_count', 'points_total', 'rare_krasnale', 'consecutive_days', etc.
    requirement_value INTEGER NOT NULL,
    points_reward INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT false, -- Hidden until unlocked
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- User achievements - tracks which achievements users have unlocked
CREATE TABLE public.user_achievements (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    progress_value INTEGER DEFAULT 0, -- Current progress towards achievement
    PRIMARY KEY (user_id, achievement_id)
);

-- Achievement progress tracking - for multi-step achievements
CREATE TABLE public.achievement_progress (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
    current_value INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    metadata JSONB, -- Additional data for complex achievements
    PRIMARY KEY (user_id, achievement_id)
);

-- Enable Row Level Security
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Achievements
CREATE POLICY "Anyone can view active achievements" 
ON public.achievements FOR SELECT 
USING (is_active = true AND (NOT is_hidden OR id IN (
    SELECT achievement_id FROM public.user_achievements WHERE user_id = auth.uid()
)));

CREATE POLICY "Users can view own achievements" 
ON public.user_achievements FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" 
ON public.user_achievements FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own achievement progress" 
ON public.achievement_progress FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own achievement progress" 
ON public.achievement_progress FOR ALL 
USING (auth.uid() = user_id);

-- Insert predefined achievements
INSERT INTO public.achievements (name, description, type, rarity, requirement_type, requirement_value, points_reward) VALUES
-- Discovery Achievements
('First Steps', 'Discover your first krasnal', 'discovery', 'bronze', 'krasnale_count', 1, 50),
('Getting Started', 'Discover 5 krasnale', 'discovery', 'bronze', 'krasnale_count', 5, 100),
('Explorer', 'Discover 10 krasnale', 'discovery', 'silver', 'krasnale_count', 10, 250),
('Krasnal Hunter', 'Discover 25 krasnale', 'discovery', 'gold', 'krasnale_count', 25, 500),
('Master Explorer', 'Discover 50 krasnale', 'discovery', 'platinum', 'krasnale_count', 50, 1000),

-- Collection Achievements  
('Rare Collector', 'Discover your first rare krasnal', 'collection', 'silver', 'rare_krasnale_count', 1, 200),
('Epic Hunter', 'Discover your first epic krasnal', 'collection', 'gold', 'epic_krasnale_count', 1, 300),
('Legendary Seeker', 'Discover your first legendary krasnal', 'collection', 'platinum', 'legendary_krasnale_count', 1, 500),
('Rarity Master', 'Discover at least one krasnal of each rarity', 'collection', 'platinum', 'all_rarities', 1, 750),

-- Points Achievements
('Point Collector', 'Earn 1000 points', 'collection', 'bronze', 'points_total', 1000, 100),
('Point Master', 'Earn 5000 points', 'collection', 'silver', 'points_total', 5000, 300),
('Point Legend', 'Earn 10000 points', 'collection', 'gold', 'points_total', 10000, 500),

-- Special Location Achievements
('Old Town Explorer', 'Discover 5 krasnale in Wrocław Old Town', 'exploration', 'silver', 'old_town_krasnale', 5, 200),
('University District', 'Discover all krasnale near University of Wrocław', 'exploration', 'gold', 'university_krasnale', 3, 300),
('Market Square Master', 'Discover all krasnale around Market Square', 'exploration', 'gold', 'market_square_krasnale', 4, 400),

-- Time-based Achievements
('Daily Explorer', 'Discover krasnale on 7 different days', 'exploration', 'bronze', 'discovery_days', 7, 150),
('Weekly Warrior', 'Discover krasnale on 30 different days', 'exploration', 'silver', 'discovery_days', 30, 400),
('Dedicated Seeker', 'Discover krasnale on 100 different days', 'exploration', 'gold', 'discovery_days', 100, 1000),

-- Social Achievements (for future implementation)
('Social Butterfly', 'Share 10 krasnale with friends', 'social', 'bronze', 'shares_count', 10, 200),
('Community Helper', 'Report 5 missing or new krasnale', 'social', 'silver', 'reports_count', 5, 300);

-- Function to check and award achievements
CREATE OR REPLACE FUNCTION check_and_award_achievements(user_uuid UUID)
RETURNS TABLE(achievement_id UUID, achievement_name TEXT) AS $$
DECLARE
    achievement_record RECORD;
    user_stats RECORD;
    new_achievement RECORD;
BEGIN
    -- Get user current stats
    SELECT 
        krasnale_discovered,
        total_score,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid AND k.rarity = 'rare') as rare_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid AND k.rarity = 'epic') as epic_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid AND k.rarity = 'legendary') as legendary_count,
        (SELECT COUNT(DISTINCT DATE(discovered_at)) FROM user_discoveries 
         WHERE user_id = user_uuid) as discovery_days
    INTO user_stats
    FROM users WHERE id = user_uuid;

    -- Check each achievement
    FOR achievement_record IN 
        SELECT a.* FROM achievements a 
        WHERE a.is_active = true 
        AND a.id NOT IN (
            SELECT achievement_id FROM user_achievements 
            WHERE user_id = user_uuid
        )
    LOOP
        -- Check if achievement requirements are met
        IF (achievement_record.requirement_type = 'krasnale_count' AND 
            user_stats.krasnale_discovered >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'points_total' AND 
            user_stats.total_score >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'rare_krasnale_count' AND 
            user_stats.rare_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'epic_krasnale_count' AND 
            user_stats.epic_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'legendary_krasnale_count' AND 
            user_stats.legendary_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'discovery_days' AND 
            user_stats.discovery_days >= achievement_record.requirement_value) THEN
            
            -- Award the achievement
            INSERT INTO user_achievements (user_id, achievement_id)
            VALUES (user_uuid, achievement_record.id)
            ON CONFLICT DO NOTHING;
            
            -- Update user total score with achievement points
            UPDATE users 
            SET total_score = total_score + achievement_record.points_reward
            WHERE id = user_uuid;
            
            -- Return the newly awarded achievement
            achievement_id := achievement_record.id;
            achievement_name := achievement_record.name;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to get achievement progress for a user
CREATE OR REPLACE FUNCTION get_achievement_progress(user_uuid UUID)
RETURNS TABLE(
    achievement_id UUID,
    achievement_name TEXT,
    achievement_description TEXT,
    requirement_type TEXT,
    requirement_value INTEGER,
    current_value INTEGER,
    progress_percentage DECIMAL,
    is_completed BOOLEAN,
    points_reward INTEGER,
    rarity TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.description,
        a.requirement_type,
        a.requirement_value,
        CASE 
            WHEN a.requirement_type = 'krasnale_count' THEN u.krasnale_discovered
            WHEN a.requirement_type = 'points_total' THEN u.total_score
            WHEN a.requirement_type = 'rare_krasnale_count' THEN (
                SELECT COUNT(*)::INTEGER FROM user_discoveries ud 
                JOIN krasnale k ON ud.krasnal_id = k.id 
                WHERE ud.user_id = user_uuid AND k.rarity = 'rare'
            )
            WHEN a.requirement_type = 'epic_krasnale_count' THEN (
                SELECT COUNT(*)::INTEGER FROM user_discoveries ud 
                JOIN krasnale k ON ud.krasnal_id = k.id 
                WHERE ud.user_id = user_uuid AND k.rarity = 'epic'
            )
            WHEN a.requirement_type = 'legendary_krasnale_count' THEN (
                SELECT COUNT(*)::INTEGER FROM user_discoveries ud 
                JOIN krasnale k ON ud.krasnal_id = k.id 
                WHERE ud.user_id = user_uuid AND k.rarity = 'legendary'
            )
            WHEN a.requirement_type = 'discovery_days' THEN (
                SELECT COUNT(DISTINCT DATE(discovered_at))::INTEGER FROM user_discoveries 
                WHERE user_id = user_uuid
            )
            ELSE 0
        END as current_value,
        CASE 
            WHEN a.requirement_type = 'krasnale_count' THEN 
                LEAST(u.krasnale_discovered::DECIMAL / a.requirement_value, 1.0)
            WHEN a.requirement_type = 'points_total' THEN 
                LEAST(u.total_score::DECIMAL / a.requirement_value, 1.0)
            ELSE 0.0
        END as progress_percentage,
        EXISTS(SELECT 1 FROM user_achievements ua WHERE ua.user_id = user_uuid AND ua.achievement_id = a.id) as is_completed,
        a.points_reward,
        a.rarity
    FROM achievements a
    CROSS JOIN users u
    WHERE u.id = user_uuid 
    AND a.is_active = true
    AND (NOT a.is_hidden OR EXISTS(SELECT 1 FROM user_achievements ua WHERE ua.user_id = user_uuid AND ua.achievement_id = a.id))
    ORDER BY is_completed ASC, a.points_reward DESC;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically check achievements when user stats change
CREATE OR REPLACE FUNCTION trigger_check_achievements()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for new achievements after discovery
    PERFORM check_and_award_achievements(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_discoveries table
CREATE TRIGGER achievement_check_trigger
    AFTER INSERT ON public.user_discoveries
    FOR EACH ROW
    EXECUTE FUNCTION trigger_check_achievements();

-- Grant necessary permissions
GRANT SELECT ON public.achievements TO anon, authenticated;
GRANT SELECT ON public.user_achievements TO anon, authenticated;
GRANT SELECT ON public.achievement_progress TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_and_award_achievements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_achievement_progress(UUID) TO authenticated;