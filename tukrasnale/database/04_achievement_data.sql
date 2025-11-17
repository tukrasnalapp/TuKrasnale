-- Predefined Achievement Data
-- Execute after 03_achievement_tables.sql
-- This populates the achievements table with game achievements

-- Insert predefined achievements
INSERT INTO public.achievements (name, description, type, rarity, requirement_type, requirement_value, points_reward) VALUES

-- Discovery Achievements
('First Steps', 'Discover your first krasnal', 'discovery', 'bronze', 'krasnale_count', 1, 50),
('Getting Started', 'Discover 5 krasnale', 'discovery', 'bronze', 'krasnale_count', 5, 100),
('Explorer', 'Discover 10 krasnale', 'discovery', 'silver', 'krasnale_count', 10, 250),
('Krasnal Hunter', 'Discover 25 krasnale', 'discovery', 'gold', 'krasnale_count', 25, 500),
('Master Explorer', 'Discover 50 krasnale', 'discovery', 'platinum', 'krasnale_count', 50, 1000),
('Ultimate Collector', 'Discover 100 krasnale', 'discovery', 'platinum', 'krasnale_count', 100, 2000),

-- Collection Achievements  
('Rare Collector', 'Discover your first rare krasnal', 'collection', 'silver', 'rare_krasnale_count', 1, 200),
('Epic Hunter', 'Discover your first epic krasnal', 'collection', 'gold', 'epic_krasnale_count', 1, 300),
('Legendary Seeker', 'Discover your first legendary krasnal', 'collection', 'platinum', 'legendary_krasnale_count', 1, 500),
('Rarity Master', 'Discover at least one krasnal of each rarity', 'collection', 'platinum', 'all_rarities', 1, 750),
('Rare Collection', 'Discover 10 rare krasnale', 'collection', 'gold', 'rare_krasnale_count', 10, 800),
('Epic Collection', 'Discover 5 epic krasnale', 'collection', 'platinum', 'epic_krasnale_count', 5, 1200),

-- Points Achievements
('Point Collector', 'Earn 1,000 points', 'collection', 'bronze', 'points_total', 1000, 100),
('Point Master', 'Earn 5,000 points', 'collection', 'silver', 'points_total', 5000, 300),
('Point Legend', 'Earn 10,000 points', 'collection', 'gold', 'points_total', 10000, 500),
('Point God', 'Earn 25,000 points', 'collection', 'platinum', 'points_total', 25000, 1000),

-- Special Location Achievements
('Old Town Explorer', 'Discover 5 krasnale in Wrocław Old Town', 'exploration', 'silver', 'old_town_krasnale', 5, 200),
('University District', 'Discover all krasnale near University of Wrocław', 'exploration', 'gold', 'university_krasnale', 3, 300),
('Market Square Master', 'Discover all krasnale around Market Square', 'exploration', 'gold', 'market_square_krasnale', 4, 400),
('Cathedral Island', 'Discover krasnale on Ostrów Tumski', 'exploration', 'silver', 'cathedral_island_krasnale', 2, 250),
('Riverbank Walker', 'Discover krasnale along the Odra River', 'exploration', 'silver', 'riverbank_krasnale', 3, 200),

-- Time-based Achievements
('Daily Explorer', 'Discover krasnale on 7 different days', 'exploration', 'bronze', 'discovery_days', 7, 150),
('Weekly Warrior', 'Discover krasnale on 30 different days', 'exploration', 'silver', 'discovery_days', 30, 400),
('Monthly Master', 'Discover krasnale on 60 different days', 'exploration', 'gold', 'discovery_days', 60, 700),
('Dedicated Seeker', 'Discover krasnale on 100 different days', 'exploration', 'gold', 'discovery_days', 100, 1000),
('Year-Round Explorer', 'Discover krasnale on 365 different days', 'exploration', 'platinum', 'discovery_days', 365, 3000),

-- Speed and Efficiency Achievements
('Quick Discoverer', 'Discover 5 krasnale in one day', 'exploration', 'bronze', 'single_day_discoveries', 5, 200),
('Speed Runner', 'Discover 10 krasnale in one day', 'exploration', 'silver', 'single_day_discoveries', 10, 400),
('Marathon Explorer', 'Discover 20 krasnale in one day', 'exploration', 'gold', 'single_day_discoveries', 20, 800),

-- Distance and Travel Achievements
('Local Explorer', 'Discover krasnale within 1km radius', 'exploration', 'bronze', 'local_area_discoveries', 10, 150),
('City Walker', 'Discover krasnale across the entire city', 'exploration', 'silver', 'city_wide_discoveries', 25, 300),
('Distance Master', 'Travel 100km total discovering krasnale', 'exploration', 'gold', 'total_distance_km', 100, 500),

-- Social Achievements (for future implementation)
('Social Butterfly', 'Share 10 krasnale with friends', 'social', 'bronze', 'shares_count', 10, 200),
('Community Helper', 'Report 5 missing or new krasnale', 'social', 'silver', 'reports_count', 5, 300),
('Friend Magnet', 'Have 10 friends in the app', 'social', 'silver', 'friends_count', 10, 250),
('Influencer', 'Share 50 krasnale with friends', 'social', 'gold', 'shares_count', 50, 600),
('Community Leader', 'Report 20 missing or new krasnale', 'social', 'gold', 'reports_count', 20, 800),

-- Special Hidden Achievements
('Night Owl', 'Discover a krasnal between midnight and 6 AM', 'special', 'gold', 'night_discovery', 1, 400),
('Early Bird', 'Discover a krasnal between 5 AM and 7 AM', 'special', 'silver', 'early_discovery', 1, 300),
('Weather Warrior', 'Discover krasnale in rain', 'special', 'silver', 'rain_discovery', 1, 350),
('New Year Explorer', 'Discover a krasnal on New Year''s Day', 'special', 'gold', 'newyear_discovery', 1, 500),
('Birthday Special', 'Discover a krasnal on your birthday', 'special', 'platinum', 'birthday_discovery', 1, 1000),

-- Completion Achievements  
('Perfectionist', 'Discover all available krasnale in Wrocław', 'special', 'platinum', 'complete_collection', 1, 5000),
('Achievement Hunter', 'Unlock 50% of all achievements', 'special', 'gold', 'achievement_percentage', 50, 1000),
('Achievement Master', 'Unlock 90% of all achievements', 'special', 'platinum', 'achievement_percentage', 90, 2500);

-- Mark some achievements as hidden until unlocked
UPDATE public.achievements 
SET is_hidden = true 
WHERE name IN (
    'Night Owl', 
    'Weather Warrior', 
    'Birthday Special', 
    'Perfectionist',
    'Achievement Master'
);