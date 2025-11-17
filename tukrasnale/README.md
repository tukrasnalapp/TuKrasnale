# TuKrasnal Flutter App

A Flutter application with Supabase backend integration.

## Features

- **Authentication**: Sign up, sign in, and sign out functionality
- **Supabase Integration**: Ready-to-use backend with PostgreSQL
- **State Management**: Provider pattern for app state
- **Responsive UI**: Clean and modern Material Design 3 interface
- **Environment Configuration**: Secure credential management

## Getting Started

### Prerequisites

- Flutter SDK (3.4.4 or later)
- Dart SDK
- A Supabase account and project

### Setup Instructions

1. **Clone and Navigate**
   ```bash
   cd tukrasnale
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Supabase Setup**
   - Create a new project at [supabase.com](https://supabase.com)
   - Get your project URL and anon key from Settings > API
   - Update the `.env` file with your credentials:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Database Schema (Optional)**
   Run these SQL commands in your Supabase SQL editor to create example tables:
   ```sql
   -- Example user profiles table
   CREATE TABLE user_profiles (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
     name TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Example app data table
   CREATE TABLE app_data (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     title TEXT NOT NULL,
     description TEXT,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Enable Row Level Security
   ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;

   -- Create policies
   CREATE POLICY "Users can view own profile" ON user_profiles
     FOR SELECT USING (auth.uid() = user_id);

   CREATE POLICY "Users can update own profile" ON user_profiles
     FOR UPDATE USING (auth.uid() = user_id);

   CREATE POLICY "Users can view own data" ON app_data
     FOR ALL USING (auth.uid() = user_id);
   ```

5. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── app_models.dart      # Data models
├── providers/
│   └── auth_provider.dart   # Authentication state management
├── screens/
│   ├── login_screen.dart    # Sign in/up screen
│   └── home_screen.dart     # Main app screen
└── services/
    └── supabase_service.dart # Backend service layer
```

## Key Components

### SupabaseService
Handles all backend operations including:
- Authentication (sign up, sign in, sign out)
- Database operations (CRUD)
- Real-time subscriptions

### AuthProvider
Manages authentication state using the Provider pattern:
- User session management
- Loading states
- Error handling

### Screens
- **LoginScreen**: User authentication interface
- **HomeScreen**: Main application interface with feature placeholders

## Next Steps

This skeleton provides a solid foundation. Consider adding:

1. **User Profiles**: Extend user data management
2. **Real-time Features**: Use Supabase real-time subscriptions
3. **File Storage**: Implement Supabase Storage for media
4. **Push Notifications**: Add notification support
5. **Offline Support**: Implement local data caching
6. **Testing**: Add unit and widget tests

## Environment Variables

The app uses a `.env` file for configuration. Never commit this file with real credentials.

Example `.env` structure:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## Contributing

1. Follow Flutter best practices
2. Use the established project structure
3. Update documentation for new features
4. Test changes thoroughly

## License

This project is private and proprietary.
