import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../services/admin_service.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_panel_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isCheckingAdminStatus = true;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isCheckingAdminStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdminStatus = false;
        });
      }
    }
  }

  List<Widget> get _screens {
    final baseScreens = [
      const MapScreen(),
      const ProfileScreen(),
      const LeaderboardScreen(),
      const ReportsScreen(),
    ];

    // Add admin panel if user is admin
    if (_isAdmin) {
      baseScreens.insert(3, const AdminPanelScreen()); // Insert before reports
    }

    return baseScreens;
  }

  List<BottomNavigationBarItem> get _navItems {
    final baseItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Map',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.leaderboard),
        label: 'Leaderboard',
      ),
    ];

    // Add admin panel if user is admin
    if (_isAdmin) {
      baseItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    // Add reports tab
    baseItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.report),
        label: 'Reports',
      ),
    );

    return baseItems;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdminStatus) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}