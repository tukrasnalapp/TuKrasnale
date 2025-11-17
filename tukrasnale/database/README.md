# TuKrasnal Database Deployment Guide

This guide explains how to deploy the database schema incrementally using the organized SQL files.

## 📁 **File Structure**

```
database/
├── 01_core_schema.sql          # Core tables (users, krasnale, discoveries)
├── 02_sample_krasnale_data.sql # Real Wrocław krasnale data
├── 03_achievement_tables.sql   # Achievement system tables
├── 04_achievement_data.sql     # Predefined achievements
├── 05_achievement_functions.sql # Achievement logic & functions
├── 06_phase2_extensions.sql    # Advanced features (routes, social, etc.)
└── README.md                   # This file
```

## 🚀 **Deployment Order**

### **Phase 1: Core System (Required)**

Execute these files in order for basic functionality:

1. **01_core_schema.sql** - Creates foundation tables
   ```bash
   # Copy content to Supabase SQL Editor and run
   ```

2. **02_sample_krasnale_data.sql** - Adds real Wrocław krasnale
   ```bash
   # Adds 30+ real krasnale with accurate coordinates
   ```

### **Phase 1.5: Achievement System (Recommended)**

3. **03_achievement_tables.sql** - Creates achievement tables
   ```bash
   # Achievement infrastructure
   ```

4. **04_achievement_data.sql** - Adds 40+ predefined achievements
   ```bash
   # Bronze, silver, gold, and platinum achievements
   ```

5. **05_achievement_functions.sql** - Achievement logic
   ```bash
   # Automatic achievement awarding and progress tracking
   ```

### **Phase 2: Advanced Features (Future)**

6. **06_phase2_extensions.sql** - Social and advanced features
   ```bash
   # Routes, challenges, social features, community content
   # Only deploy when ready to implement these features
   ```

## 📋 **Deployment Steps**

### **Option A: Supabase Dashboard (Recommended)**

1. **Open Supabase Dashboard**
   - Go to [supabase.com](https://supabase.com)
   - Open your TuKrasnal project
   - Click "SQL Editor" in sidebar

2. **Execute Files in Order**
   ```sql
   -- Execute 01_core_schema.sql first
   -- Then 02_sample_krasnale_data.sql
   -- Continue with achievement files if desired
   ```

3. **Verify Tables Created**
   - Go to "Table Editor"
   - Check that tables appear: `users`, `krasnale`, `user_discoveries`
   - Verify krasnale data is populated

### **Option B: Supabase CLI**

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Initialize Project**
   ```bash
   supabase init
   supabase link --project-ref your-project-ref
   ```

3. **Create Migrations**
   ```bash
   supabase migration new core_schema
   supabase migration new sample_data
   supabase migration new achievements
   ```

4. **Apply Migrations**
   ```bash
   supabase db push
   ```

## 🔍 **Verification Queries**

After deployment, run these queries to verify everything works:

### **Check Tables Created**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### **Check Sample Data**
```sql
SELECT COUNT(*) as total_krasnale FROM public.krasnale;
SELECT rarity, COUNT(*) as count FROM public.krasnale GROUP BY rarity;
```

### **Check Achievement System**
```sql
SELECT COUNT(*) as total_achievements FROM public.achievements;
SELECT type, COUNT(*) as count FROM public.achievements GROUP BY type;
```

### **Test Achievement Functions**
```sql
-- Test achievement progress function (replace with real user ID)
SELECT * FROM get_achievement_progress('00000000-0000-0000-0000-000000000000'::UUID);
```

## 🛠️ **Customization**

### **Adding More Krasnale**
Edit `02_sample_krasnale_data.sql`:
```sql
INSERT INTO public.krasnale (name, description, location_name, latitude, longitude, rarity, points_value) VALUES
('Your Krasnal', 'Description', 'Location', 51.1234, 17.0567, 'common', 25);
```

### **Creating Custom Achievements**
Edit `04_achievement_data.sql`:
```sql
INSERT INTO public.achievements (name, description, type, rarity, requirement_type, requirement_value, points_reward) VALUES
('Custom Achievement', 'Your description', 'discovery', 'bronze', 'krasnale_count', 3, 75);
```

### **Modifying Rarity/Points**
```sql
UPDATE public.krasnale 
SET rarity = 'rare', points_value = 50 
WHERE name = 'Specific Krasnal';
```

## ⚠️ **Important Notes**

### **Order Matters**
- Always deploy core schema first
- Achievement system depends on core tables
- Phase 2 extensions depend on everything else

### **Row Level Security**
- All tables have RLS enabled
- Users can only access their own data
- Public data (krasnale, achievements) is visible to all

### **Performance**
- Indexes are included for optimal performance
- Functions are optimized for frequent calls
- Triggers automatically update user stats

### **Data Safety**
- Foreign key constraints prevent data corruption
- Cascading deletes clean up related data
- Check constraints ensure data validity

## 🔧 **Troubleshooting**

### **Common Issues**

1. **"Table already exists" error**
   ```sql
   DROP TABLE IF EXISTS public.table_name CASCADE;
   ```

2. **"Function already exists" error**
   ```sql
   DROP FUNCTION IF EXISTS function_name(parameters);
   ```

3. **RLS policy conflicts**
   ```sql
   DROP POLICY IF EXISTS "policy_name" ON public.table_name;
   ```

4. **Permission errors**
   ```sql
   GRANT ALL ON public.table_name TO authenticated;
   ```

### **Reset Database**
To start fresh (⚠️ DESTROYS ALL DATA):
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

## 📊 **Database Schema Overview**

### **Core Tables (Phase 1)**
- `users` - User profiles and stats
- `krasnale` - Dwarf sculpture data
- `user_discoveries` - Discovery tracking

### **Achievement Tables**
- `achievements` - Achievement definitions
- `user_achievements` - Unlocked achievements
- `achievement_progress` - Progress tracking

### **Extension Tables (Phase 2)**
- `routes` - Guided exploration paths
- `challenges` - Time-limited quests
- `community_reports` - User-generated content
- `friendships` - Social connections
- `notifications` - In-app messaging

## 🎯 **Next Steps**

1. **Deploy Phase 1** - Core functionality
2. **Test with Flutter app** - Verify integration
3. **Add Achievement System** - Gamification
4. **Plan Phase 2 features** - Social and advanced features

For Flutter integration, use the data models in `lib/models/krasnal_models.dart` that match these database tables.