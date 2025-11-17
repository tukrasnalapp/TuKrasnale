-- Achievement System Functions
-- Execute after 03_achievement_tables.sql and 04_achievement_data.sql
-- This creates the logic for automatically awarding achievements

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
         WHERE ud.user_id = user_uuid AND k.rarity = 'common') as common_count,
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
         WHERE user_id = user_uuid) as discovery_days,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid 
         AND k.location_name ILIKE '%Old Town%') as old_town_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid 
         AND k.location_name ILIKE '%University%') as university_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid 
         AND k.location_name ILIKE '%Market Square%') as market_square_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid 
         AND k.location_name ILIKE '%Cathedral%') as cathedral_count,
        (SELECT COUNT(*) FROM user_discoveries ud 
         JOIN krasnale k ON ud.krasnal_id = k.id 
         WHERE ud.user_id = user_uuid 
         AND k.location_name ILIKE '%River%') as riverbank_count,
        (SELECT MAX(daily_count) FROM (
            SELECT COUNT(*) as daily_count 
            FROM user_discoveries 
            WHERE user_id = user_uuid 
            GROUP BY DATE(discovered_at)
        ) daily_stats) as max_single_day,
        (SELECT COUNT(DISTINCT achievement_id) FROM user_achievements 
         WHERE user_id = user_uuid) as unlocked_achievements_count,
        (SELECT COUNT(*) FROM achievements WHERE is_active = true) as total_achievements_count
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
            user_stats.discovery_days >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'old_town_krasnale' AND 
            user_stats.old_town_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'university_krasnale' AND 
            user_stats.university_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'market_square_krasnale' AND 
            user_stats.market_square_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'cathedral_island_krasnale' AND 
            user_stats.cathedral_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'riverbank_krasnale' AND 
            user_stats.riverbank_count >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'single_day_discoveries' AND 
            user_stats.max_single_day >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'all_rarities' AND 
            user_stats.common_count > 0 AND user_stats.rare_count > 0 AND 
            user_stats.epic_count > 0 AND user_stats.legendary_count > 0) OR
           (achievement_record.requirement_type = 'achievement_percentage' AND 
            (user_stats.unlocked_achievements_count * 100.0 / user_stats.total_achievements_count) >= achievement_record.requirement_value) OR
           (achievement_record.requirement_type = 'complete_collection' AND 
            user_stats.krasnale_discovered >= (SELECT COUNT(*) FROM krasnale WHERE is_active = true)) THEN
            
            -- Award the achievement
            INSERT INTO user_achievements (user_id, achievement_id)
            VALUES (user_uuid, achievement_record.id)
            ON CONFLICT DO NOTHING;
            
            -- Update user total score with achievement points
            UPDATE users 
            SET total_score = total_score + achievement_record.points_reward,
                updated_at = now()
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
    achievement_type TEXT,
    requirement_type TEXT,
    requirement_value INTEGER,
    current_value INTEGER,
    progress_percentage DECIMAL,
    is_completed BOOLEAN,
    points_reward INTEGER,
    rarity TEXT,
    is_hidden BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH user_stats AS (
        SELECT 
            u.krasnale_discovered,
            u.total_score,
            (SELECT COUNT(*) FROM user_discoveries ud 
             JOIN krasnale k ON ud.krasnal_id = k.id 
             WHERE ud.user_id = user_uuid AND k.rarity = 'common') as common_count,
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
             WHERE user_id = user_uuid) as discovery_days,
            (SELECT COUNT(*) FROM user_discoveries ud 
             JOIN krasnale k ON ud.krasnal_id = k.id 
             WHERE ud.user_id = user_uuid 
             AND k.location_name ILIKE '%Old Town%') as old_town_count,
            (SELECT COUNT(*) FROM user_discoveries ud 
             JOIN krasnale k ON ud.krasnal_id = k.id 
             WHERE ud.user_id = user_uuid 
             AND k.location_name ILIKE '%University%') as university_count,
            (SELECT COUNT(*) FROM user_discoveries ud 
             JOIN krasnale k ON ud.krasnal_id = k.id 
             WHERE ud.user_id = user_uuid 
             AND k.location_name ILIKE '%Market Square%') as market_square_count,
            (SELECT MAX(daily_count) FROM (
                SELECT COUNT(*) as daily_count 
                FROM user_discoveries 
                WHERE user_id = user_uuid 
                GROUP BY DATE(discovered_at)
            ) daily_stats) as max_single_day,
            (SELECT COUNT(DISTINCT achievement_id) FROM user_achievements 
             WHERE user_id = user_uuid) as unlocked_achievements_count,
            (SELECT COUNT(*) FROM achievements WHERE is_active = true) as total_achievements_count
        FROM users u
        WHERE u.id = user_uuid
    )
    SELECT 
        a.id,
        a.name,
        a.description,
        a.type,
        a.requirement_type,
        a.requirement_value,
        CASE 
            WHEN a.requirement_type = 'krasnale_count' THEN us.krasnale_discovered
            WHEN a.requirement_type = 'points_total' THEN us.total_score
            WHEN a.requirement_type = 'rare_krasnale_count' THEN us.rare_count
            WHEN a.requirement_type = 'epic_krasnale_count' THEN us.epic_count
            WHEN a.requirement_type = 'legendary_krasnale_count' THEN us.legendary_count
            WHEN a.requirement_type = 'discovery_days' THEN us.discovery_days
            WHEN a.requirement_type = 'old_town_krasnale' THEN us.old_town_count
            WHEN a.requirement_type = 'university_krasnale' THEN us.university_count
            WHEN a.requirement_type = 'market_square_krasnale' THEN us.market_square_count
            WHEN a.requirement_type = 'single_day_discoveries' THEN COALESCE(us.max_single_day, 0)
            WHEN a.requirement_type = 'all_rarities' THEN 
                CASE WHEN us.common_count > 0 AND us.rare_count > 0 AND us.epic_count > 0 AND us.legendary_count > 0 
                     THEN 1 ELSE 0 END
            WHEN a.requirement_type = 'achievement_percentage' THEN 
                (us.unlocked_achievements_count * 100 / GREATEST(us.total_achievements_count, 1))
            ELSE 0
        END as current_value,
        CASE 
            WHEN a.requirement_type = 'krasnale_count' THEN 
                LEAST(us.krasnale_discovered::DECIMAL / a.requirement_value, 1.0)
            WHEN a.requirement_type = 'points_total' THEN 
                LEAST(us.total_score::DECIMAL / a.requirement_value, 1.0)
            WHEN a.requirement_type = 'rare_krasnale_count' THEN 
                LEAST(us.rare_count::DECIMAL / a.requirement_value, 1.0)
            WHEN a.requirement_type = 'discovery_days' THEN 
                LEAST(us.discovery_days::DECIMAL / a.requirement_value, 1.0)
            WHEN a.requirement_type = 'all_rarities' THEN 
                CASE WHEN us.common_count > 0 AND us.rare_count > 0 AND us.epic_count > 0 AND us.legendary_count > 0 
                     THEN 1.0 ELSE 0.0 END
            ELSE LEAST(
                CASE 
                    WHEN a.requirement_type = 'old_town_krasnale' THEN us.old_town_count
                    WHEN a.requirement_type = 'university_krasnale' THEN us.university_count
                    WHEN a.requirement_type = 'market_square_krasnale' THEN us.market_square_count
                    WHEN a.requirement_type = 'single_day_discoveries' THEN COALESCE(us.max_single_day, 0)
                    ELSE 0
                END::DECIMAL / GREATEST(a.requirement_value, 1), 1.0
            )
        END as progress_percentage,
        EXISTS(SELECT 1 FROM user_achievements ua WHERE ua.user_id = user_uuid AND ua.achievement_id = a.id) as is_completed,
        a.points_reward,
        a.rarity,
        a.is_hidden
    FROM achievements a
    CROSS JOIN user_stats us
    WHERE a.is_active = true
    AND (NOT a.is_hidden OR EXISTS(SELECT 1 FROM user_achievements ua WHERE ua.user_id = user_uuid AND ua.achievement_id = a.id))
    ORDER BY is_completed ASC, a.points_reward DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get user achievement statistics
CREATE OR REPLACE FUNCTION get_user_achievement_stats(user_uuid UUID)
RETURNS TABLE(
    total_achievements INTEGER,
    unlocked_achievements INTEGER,
    achievement_points INTEGER,
    completion_percentage DECIMAL,
    bronze_count INTEGER,
    silver_count INTEGER,
    gold_count INTEGER,
    platinum_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM achievements WHERE is_active = true) as total_achievements,
        (SELECT COUNT(*)::INTEGER FROM user_achievements WHERE user_id = user_uuid) as unlocked_achievements,
        (SELECT COALESCE(SUM(a.points_reward), 0)::INTEGER 
         FROM user_achievements ua 
         JOIN achievements a ON ua.achievement_id = a.id 
         WHERE ua.user_id = user_uuid) as achievement_points,
        (SELECT CASE 
            WHEN COUNT(*) > 0 THEN 
                (SELECT COUNT(*)::DECIMAL FROM user_achievements WHERE user_id = user_uuid) / COUNT(*) * 100
            ELSE 0 
         END 
         FROM achievements WHERE is_active = true) as completion_percentage,
        (SELECT COUNT(*)::INTEGER 
         FROM user_achievements ua 
         JOIN achievements a ON ua.achievement_id = a.id 
         WHERE ua.user_id = user_uuid AND a.rarity = 'bronze') as bronze_count,
        (SELECT COUNT(*)::INTEGER 
         FROM user_achievements ua 
         JOIN achievements a ON ua.achievement_id = a.id 
         WHERE ua.user_id = user_uuid AND a.rarity = 'silver') as silver_count,
        (SELECT COUNT(*)::INTEGER 
         FROM user_achievements ua 
         JOIN achievements a ON ua.achievement_id = a.id 
         WHERE ua.user_id = user_uuid AND a.rarity = 'gold') as gold_count,
        (SELECT COUNT(*)::INTEGER 
         FROM user_achievements ua 
         JOIN achievements a ON ua.achievement_id = a.id 
         WHERE ua.user_id = user_uuid AND a.rarity = 'platinum') as platinum_count;
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
GRANT EXECUTE ON FUNCTION get_user_achievement_stats(UUID) TO authenticated;