-- Phase 2+ Extension Tables
-- Execute after core schema is working
-- These tables support advanced features like routes, social features, and community content

-- Routes (suggested exploration paths)
CREATE TABLE public.routes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    estimated_duration INTEGER, -- minutes
    total_krasnale INTEGER DEFAULT 0,
    route_points JSONB, -- Array of lat/lng coordinates for the route path
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_official BOOLEAN DEFAULT false, -- Official routes vs user-created
    is_active BOOLEAN DEFAULT true
);

-- Route krasnale (which krasnale are part of which routes)
CREATE TABLE public.route_krasnale (
    route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
    krasnal_id UUID REFERENCES public.krasnale(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL, -- Order in the route
    optional BOOLEAN DEFAULT false, -- Whether this krasnal is required for route completion
    PRIMARY KEY (route_id, krasnal_id)
);

-- User route progress
CREATE TABLE public.user_route_progress (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    krasnale_found INTEGER DEFAULT 0,
    total_krasnale INTEGER NOT NULL,
    current_step INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completion_time INTEGER, -- minutes to complete
    PRIMARY KEY (user_id, route_id)
);

-- Community reports (missing/new/incorrect krasnale)
CREATE TABLE public.community_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES public.users(id),
    report_type VARCHAR(20) NOT NULL CHECK (report_type IN ('missing', 'new', 'incorrect', 'damaged')),
    krasnal_id UUID REFERENCES public.krasnale(id), -- null for new krasnale reports
    suggested_name VARCHAR(100), -- for new krasnale suggestions
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    description TEXT NOT NULL,
    image_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'in_progress')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Comments and reviews on krasnale
CREATE TABLE public.krasnal_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    krasnal_id UUID REFERENCES public.krasnale(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    helpful_votes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_flagged BOOLEAN DEFAULT false
);

-- Comment votes (helpful/not helpful)
CREATE TABLE public.comment_votes (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.krasnal_comments(id) ON DELETE CASCADE,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (user_id, comment_id)
);

-- Social sharing events (NFC, QR codes, etc.)
CREATE TABLE public.share_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES public.users(id),
    receiver_id UUID REFERENCES public.users(id),
    krasnal_id UUID REFERENCES public.krasnale(id),
    share_method VARCHAR(20) CHECK (share_method IN ('nfc', 'qr', 'link', 'shake')),
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE,
    is_successful BOOLEAN DEFAULT false
);

-- User friendships
CREATE TABLE public.friendships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, friend_id),
    CHECK(user_id != friend_id)
);

-- User favorites (favorite krasnale)
CREATE TABLE public.user_favorites (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    krasnal_id UUID REFERENCES public.krasnale(id) ON DELETE CASCADE,
    favorited_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (user_id, krasnal_id)
);

-- Challenges/quests
CREATE TABLE public.challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    challenge_type VARCHAR(30) NOT NULL CHECK (challenge_type IN ('discovery', 'time_limited', 'location', 'social', 'collection')),
    requirements JSONB NOT NULL, -- Flexible requirements structure
    rewards JSONB, -- Points, badges, etc.
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    is_repeatable BOOLEAN DEFAULT false,
    difficulty VARCHAR(20) DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard', 'extreme')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- User challenge progress
CREATE TABLE public.user_challenge_progress (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    current_progress JSONB DEFAULT '{}', -- Flexible progress tracking
    is_completed BOOLEAN DEFAULT false,
    PRIMARY KEY (user_id, challenge_id)
);

-- Notifications
CREATE TABLE public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN ('achievement', 'friend_request', 'share_received', 'challenge', 'system')),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Additional notification data
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Enable Row Level Security for all tables
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_krasnale ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_route_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.krasnal_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenge_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Routes
CREATE POLICY "Anyone can view active routes" ON public.routes FOR SELECT USING (is_active = true);
CREATE POLICY "Users can create routes" ON public.routes FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update own routes" ON public.routes FOR UPDATE USING (auth.uid() = created_by);

-- Route krasnale
CREATE POLICY "Anyone can view route krasnale" ON public.route_krasnale FOR SELECT USING (true);

-- User route progress
CREATE POLICY "Users can view own route progress" ON public.user_route_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own route progress" ON public.user_route_progress FOR ALL USING (auth.uid() = user_id);

-- Community reports
CREATE POLICY "Users can create reports" ON public.community_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Users can view all approved reports" ON public.community_reports FOR SELECT USING (status = 'approved' OR auth.uid() = reporter_id);
CREATE POLICY "Users can update own reports" ON public.community_reports FOR UPDATE USING (auth.uid() = reporter_id AND status = 'pending');

-- Comments
CREATE POLICY "Anyone can view comments" ON public.krasnal_comments FOR SELECT USING (NOT is_flagged);
CREATE POLICY "Users can create comments" ON public.krasnal_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON public.krasnal_comments FOR UPDATE USING (auth.uid() = user_id);

-- Comment votes
CREATE POLICY "Users can manage own votes" ON public.comment_votes FOR ALL USING (auth.uid() = user_id);

-- Share events
CREATE POLICY "Users can view own shares" ON public.share_events FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can create shares" ON public.share_events FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Friendships
CREATE POLICY "Users can view own friendships" ON public.friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can manage own friendships" ON public.friendships FOR ALL USING (auth.uid() = user_id);

-- User favorites
CREATE POLICY "Users can manage own favorites" ON public.user_favorites FOR ALL USING (auth.uid() = user_id);

-- Challenges
CREATE POLICY "Anyone can view active challenges" ON public.challenges FOR SELECT USING (is_active = true);

-- User challenge progress
CREATE POLICY "Users can manage own challenge progress" ON public.user_challenge_progress FOR ALL USING (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_routes_active ON public.routes(is_active) WHERE is_active = true;
CREATE INDEX idx_user_route_progress_user ON public.user_route_progress(user_id);
CREATE INDEX idx_community_reports_status ON public.community_reports(status);
CREATE INDEX idx_community_reports_type ON public.community_reports(report_type);
CREATE INDEX idx_krasnal_comments_krasnal ON public.krasnal_comments(krasnal_id);
CREATE INDEX idx_krasnal_comments_user ON public.krasnal_comments(user_id);
CREATE INDEX idx_share_events_sender ON public.share_events(sender_id);
CREATE INDEX idx_share_events_receiver ON public.share_events(receiver_id);
CREATE INDEX idx_friendships_user ON public.friendships(user_id);
CREATE INDEX idx_friendships_friend ON public.friendships(friend_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE NOT is_read;
CREATE INDEX idx_challenges_active ON public.challenges(is_active) WHERE is_active = true;