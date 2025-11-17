-- Additional helper functions for TuKrasnal app
-- Execute after the main schema

-- Function to get nearby krasnale (within specified radius)
CREATE OR REPLACE FUNCTION get_nearby_krasnale(
    user_lat DECIMAL(10, 8),
    user_lng DECIMAL(11, 8),
    radius_km DECIMAL DEFAULT 5.0
)
RETURNS TABLE(
    id UUID,
    name VARCHAR,
    description TEXT,
    history TEXT,
    location_name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    image_url TEXT,
    model_3d_url TEXT,
    rarity VARCHAR,
    discovery_radius INTEGER,
    points_value INTEGER,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    distance_meters FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.id,
        k.name,
        k.description,
        k.history,
        k.location_name,
        k.latitude,
        k.longitude,
        k.image_url,
        k.model_3d_url,
        k.rarity,
        k.discovery_radius,
        k.points_value,
        k.is_active,
        k.created_at,
        -- Calculate distance using Haversine formula
        (6371000 * acos(
            cos(radians(user_lat)) * cos(radians(k.latitude)) * 
            cos(radians(k.longitude) - radians(user_lng)) + 
            sin(radians(user_lat)) * sin(radians(k.latitude))
        ))::FLOAT as distance_meters
    FROM krasnale k
    WHERE k.is_active = true
    AND (6371000 * acos(
        cos(radians(user_lat)) * cos(radians(k.latitude)) * 
        cos(radians(k.longitude) - radians(user_lng)) + 
        sin(radians(user_lat)) * sin(radians(k.latitude))
    )) <= (radius_km * 1000)
    ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;

-- Function to get discoverable krasnale (within discovery radius)
CREATE OR REPLACE FUNCTION get_discoverable_krasnale(
    user_lat DECIMAL(10, 8),
    user_lng DECIMAL(11, 8)
)
RETURNS TABLE(
    id UUID,
    name VARCHAR,
    description TEXT,
    history TEXT,
    location_name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    image_url TEXT,
    model_3d_url TEXT,
    rarity VARCHAR,
    discovery_radius INTEGER,
    points_value INTEGER,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    distance_meters FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.id,
        k.name,
        k.description,
        k.history,
        k.location_name,
        k.latitude,
        k.longitude,
        k.image_url,
        k.model_3d_url,
        k.rarity,
        k.discovery_radius,
        k.points_value,
        k.is_active,
        k.created_at,
        -- Calculate distance using Haversine formula
        (6371000 * acos(
            cos(radians(user_lat)) * cos(radians(k.latitude)) * 
            cos(radians(k.longitude) - radians(user_lng)) + 
            sin(radians(user_lat)) * sin(radians(k.latitude))
        ))::FLOAT as distance_meters
    FROM krasnale k
    WHERE k.is_active = true
    AND (6371000 * acos(
        cos(radians(user_lat)) * cos(radians(k.latitude)) * 
        cos(radians(k.longitude) - radians(user_lng)) + 
        sin(radians(user_lat)) * sin(radians(k.latitude))
    )) <= k.discovery_radius
    AND k.id NOT IN (
        -- Exclude already discovered krasnale
        SELECT krasnal_id FROM user_discoveries 
        WHERE user_id = auth.uid()
    )
    ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_nearby_krasnale(DECIMAL, DECIMAL, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discoverable_krasnale(DECIMAL, DECIMAL) TO authenticated;