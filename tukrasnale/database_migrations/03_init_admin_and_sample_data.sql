-- Initialize admin user (run this after creating your first account)
-- Replace 'your-user-email@example.com' with your actual email

-- Update your user profile to admin role
UPDATE user_profiles 
SET role = 'admin' 
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'your-user-email@example.com'
);

-- Create storage buckets for images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('krasnale-images', 'krasnale-images', true);

INSERT INTO storage.buckets (id, name, public) 
VALUES ('report-photos', 'report-photos', true);

-- Set up storage policies for krasnale images
CREATE POLICY "Public Access for krasnale images" ON storage.objects
FOR SELECT USING (bucket_id = 'krasnale-images');

CREATE POLICY "Admins can upload krasnale images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'krasnale-images' AND
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Admins can update krasnale images" ON storage.objects
FOR UPDATE WITH CHECK (
  bucket_id = 'krasnale-images' AND
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

CREATE POLICY "Admins can delete krasnale images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'krasnale-images' AND
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

-- Set up storage policies for report photos
CREATE POLICY "Public Access for report photos" ON storage.objects
FOR SELECT USING (bucket_id = 'report-photos');

CREATE POLICY "Users can upload report photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'report-photos' AND
  auth.uid() IS NOT NULL
);

-- Sample krasnale data (optional)
INSERT INTO krasnale (
  name, 
  description, 
  latitude, 
  longitude, 
  location_name, 
  rarity, 
  points_value,
  undiscovered_medallion_url,
  discovered_medallion_url
) VALUES 
(
  'Krasnal Śpioch', 
  'Śpiący krasnal przy fontannie na Rynku', 
  51.1079, 
  17.0385, 
  'Rynek - Fontanna',
  'common',
  10,
  'https://example.com/sleepy-undiscovered.jpg',
  'https://example.com/sleepy-discovered.jpg'
),
(
  'Krasnal Żłobek', 
  'Krasnal opiekujący się dziećmi', 
  51.1089, 
  17.0395, 
  'Plac Solny',
  'rare',
  25,
  'https://example.com/nursery-undiscovered.jpg',
  'https://example.com/nursery-discovered.jpg'
),
(
  'Krasnal Włóczykij', 
  'Podróżujący krasnal z plecakiem', 
  51.1069, 
  17.0375, 
  'Ulica Świdnicka',
  'epic',
  50,
  'https://example.com/wanderer-undiscovered.jpg',
  'https://example.com/wanderer-discovered.jpg'
);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_krasnale_updated_at BEFORE UPDATE ON krasnale
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON krasnale_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();