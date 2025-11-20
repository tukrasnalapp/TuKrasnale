import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/discovery_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
  }
  
  // Initialize Supabase with credentials from .env
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'https://tpygmwuqcdhycvtqmhzd.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRweWdtd3VxY2RoeWN2dHFtaHpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwODg0MTcsImV4cCI6MjA3ODY2NDQxN30.e3sTjZahimSTDZowk5DYkUseHRwciP_buIVDXBYBD4o',
    );
    print('✅ Supabase initialized successfully with URL: ${dotenv.env['SUPABASE_URL']}');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    // Continue anyway - app will handle connection issues gracefully
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
      ],
      child: MaterialApp(
        title: 'TuKrasnal',
        theme: TuKrasnalTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if Supabase is properly initialized
        try {
          // Test if Supabase client is available
          Supabase.instance.client;
          
          // If we have a client and user is authenticated, show main screen
          if (authProvider.isAuthenticated) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        } catch (e) {
          // If Supabase is not initialized, show error screen
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection\nand restart the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}