-- Achievement System Database Schema
-- Execute after 01_core_schema.sql
-- This creates the achievement system tables and functions

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