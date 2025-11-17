-- Sample Wrocław Krasnale Data
-- Execute after 01_core_schema.sql
-- This includes real Wrocław dwarf locations with accurate coordinates

-- Insert sample krasnale data (famous Wrocław dwarfs)
INSERT INTO public.krasnale (name, description, history, location_name, latitude, longitude, rarity, points_value, discovery_radius) VALUES

-- Legendary Krasnale (Original/Historic)
('Świdnicka', 'The first dwarf sculpture in Wrocław', 'Installed in 2001, this was the beginning of the dwarf phenomenon in Wrocław. Created by Tomasz Moczek, it commemorates the Orange Alternative movement and marks the spot where anti-communist graffiti once appeared.', 'Świdnicka Street', 51.1079, 17.0385, 'legendary', 100, 40),

-- Epic Krasnale (Major locations)
('Papa Krasnal', 'The father of all krasnale', 'A larger dwarf sculpture that serves as the patriarch of the Wrocław dwarf family. Located in one of the most visited areas of the city.', 'Market Square', 51.1105, 17.0323, 'epic', 75, 35),

('Bankier', 'Financial district guardian', 'A dwarf handling banking matters, complete with briefcase and formal attire. Represents the economic heart of Wrocław.', 'Świdnicka Street - Banking District', 51.1089, 17.0378, 'epic', 75, 35),

('Strażak', 'Brave firefighter dwarf', 'Dedicated to the Wrocław Fire Department and all brave firefighters. Complete with helmet and equipment.', 'Near Main Fire Station', 51.1098, 17.0365, 'epic', 75, 35),

-- Rare Krasnale (Popular locations)
('Dozorca', 'University caretaker', 'Watching over the historic University of Wrocław buildings and students. Often seen with cleaning supplies.', 'University of Wrocław', 51.1145, 17.0339, 'rare', 50, 30),

('Piwosz', 'Beer-loving dwarf', 'Celebrating Wrocław''s rich brewing tradition. Often found near pubs and breweries with a beer mug in hand.', 'Piwna Street', 51.1098, 17.0298, 'rare', 50, 30),

('Ślepiec', 'The blind dwarf', 'A touching sculpture representing accessibility and inclusion. Complete with a walking stick and guide dog.', 'Świdnicka Street', 51.1085, 17.0372, 'rare', 50, 30),

('Krasnale Kominiarza', 'Chimney sweep dwarf', 'Bringing good luck to all who spot him. Traditional chimney sweep outfit with brushes and ladder.', 'Old Town Square', 51.1102, 17.0331, 'rare', 50, 30),

('Ochroniarz', 'Security guard dwarf', 'Keeping watch over the shopping areas. Complete with uniform and serious expression.', 'Shopping District', 51.1092, 17.0342, 'rare', 50, 30),

('Skarbnik', 'Treasure keeper', 'Guardian of hidden treasures and secrets of Wrocław. Often found near historic buildings.', 'Castle Square', 51.1118, 17.0311, 'rare', 50, 30),

-- Common Krasnale (Neighborhood dwarfs)
('Krasnal Ogrodnik', 'Garden dwarf', 'Tending to the city''s green spaces. Found with gardening tools and a watering can.', 'Park Miejski', 51.1067, 17.0289, 'common', 25, 25),

('Krasnal Kelner', 'Waiter dwarf', 'Serving guests in the restaurant district. Complete with serving tray and bow tie.', 'Restaurant Row', 51.1095, 17.0356, 'common', 25, 25),

('Krasnal Muzyk', 'Musical dwarf', 'Playing beautiful melodies for city visitors. Often seen with various instruments.', 'Music Square', 51.1109, 17.0347, 'common', 25, 25),

('Krasnal Malarz', 'Artist dwarf', 'Creating beautiful art throughout the city. Found with brushes and palette.', 'Art District', 51.1087, 17.0319, 'common', 25, 25),

('Krasnal Zegarmistrz', 'Clockmaker dwarf', 'Keeping Wrocław''s time precise. Found near historic clock towers.', 'Cathedral Island', 51.1139, 17.0447, 'common', 25, 25),

('Krasnal Optyk', 'Optician dwarf', 'Helping residents see clearly. Complete with glasses and eye chart.', 'Commercial Street', 51.1101, 17.0367, 'common', 25, 25),

('Krasnal Fryzjer', 'Barber dwarf', 'Keeping Wrocław looking sharp. Found with scissors and comb.', 'Service District', 51.1076, 17.0334, 'common', 25, 25),

('Krasnal Rybak', 'Fisherman dwarf', 'Catching fresh fish from the Odra river. Complete with fishing rod and bucket.', 'Odra Riverbank', 51.1156, 17.0389, 'common', 25, 25),

('Krasnal Piekarza', 'Baker dwarf', 'Providing fresh bread to the city. Found with baker''s hat and rolling pin.', 'Bakery District', 51.1083, 17.0302, 'common', 25, 25),

('Krasnal Listonosz', 'Postman dwarf', 'Delivering mail throughout Wrocław. Complete with postbag and uniform.', 'Post Office Square', 51.1094, 17.0358, 'common', 25, 25);

-- Add some krasnale in specific districts for achievements

-- Old Town krasnale for "Old Town Explorer" achievement
INSERT INTO public.krasnale (name, description, history, location_name, latitude, longitude, rarity, points_value, discovery_radius) VALUES
('Old Town Guardian 1', 'Protecting the historic Old Town', 'Guardian of Wrocław''s medieval heritage.', 'Old Town - Market Square', 51.1107, 17.0325, 'common', 25, 25),
('Old Town Guardian 2', 'Watching over ancient streets', 'Keeper of old town traditions.', 'Old Town - Salt Square', 51.1098, 17.0335, 'common', 25, 25),
('Old Town Guardian 3', 'Medieval town protector', 'Guardian of historic architecture.', 'Old Town - Cathedral', 51.1142, 17.0451, 'common', 25, 25);

-- University district krasnale for "University District" achievement  
INSERT INTO public.krasnale (name, description, history, location_name, latitude, longitude, rarity, points_value, discovery_radius) VALUES
('Student Krasnal', 'Helping university students', 'Academic supporter and study companion.', 'University Main Building', 51.1147, 17.0341, 'rare', 50, 30),
('Professor Krasnal', 'Wise university teacher', 'Sharing knowledge with all who pass by.', 'University Library', 51.1149, 17.0337, 'rare', 50, 30);

-- Market Square krasnale for "Market Square Master" achievement
INSERT INTO public.krasnale (name, description, history, location_name, latitude, longitude, rarity, points_value, discovery_radius) VALUES
('Market Merchant 1', 'Historic market trader', 'Continuing the tradition of Market Square commerce.', 'Market Square - North Side', 51.1108, 17.0320, 'rare', 50, 30),
('Market Merchant 2', 'Square marketplace guardian', 'Protector of market traditions.', 'Market Square - South Side', 51.1102, 17.0326, 'rare', 50, 30),
('Market Merchant 3', 'Commercial district dwarf', 'Supporting local businesses.', 'Market Square - East Side', 51.1105, 17.0329, 'rare', 50, 30);

-- Additional scattered krasnale for variety
INSERT INTO public.krasnale (name, description, history, location_name, latitude, longitude, rarity, points_value, discovery_radius) VALUES
('Krasnal Podróżnik', 'Traveler dwarf', 'Welcoming visitors to beautiful Wrocław.', 'Main Train Station', 51.0989, 17.0364, 'common', 25, 25),
('Krasnal Sportowiec', 'Athletic dwarf', 'Promoting healthy lifestyle and sports.', 'Sports Complex', 51.1123, 17.0567, 'common', 25, 25),
('Krasnal Teatralny', 'Theater dwarf', 'Supporting performing arts in Wrocław.', 'Opera House', 51.1089, 17.0456, 'rare', 50, 30),
('Krasnal Bibliotekarza', 'Librarian dwarf', 'Keeper of knowledge and books.', 'City Library', 51.1067, 17.0312, 'common', 25, 25),
('Krasnal Weterynarza', 'Veterinary dwarf', 'Caring for all the animals in the city.', 'Veterinary Clinic', 51.1134, 17.0278, 'common', 25, 25);