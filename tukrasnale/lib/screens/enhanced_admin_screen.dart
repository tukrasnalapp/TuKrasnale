import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/enhanced_add_krasnal_tab.dart';
import '../screens/manage_krasnale_tab.dart'; // Our new enhanced version

class EnhancedAdminScreen extends StatefulWidget {
  const EnhancedAdminScreen({super.key});

  @override
  State<EnhancedAdminScreen> createState() => _EnhancedAdminScreenState();
}

class _EnhancedAdminScreenState extends State<EnhancedAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel (ENHANCED)'),
        backgroundColor: TuKrasnalColors.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.add_location_alt),
              text: 'Add Krasnal',
            ),
            Tab(
              icon: Icon(Icons.manage_search),
              text: 'Manage Krasnale',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EnhancedAddKrasnalTab(),
          ManageKrasnaleTab(), // This is our new enhanced version with images
        ],
      ),
    );
  }
}