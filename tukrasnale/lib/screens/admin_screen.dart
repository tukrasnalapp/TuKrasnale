import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/enhanced_add_krasnal_tab.dart';
import '../screens/manage_krasnale_tab.dart'; // This now points to the enhanced version

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
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
        title: const Text('Admin Panel'),
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
          ManageKrasnaleTab(), // This is now the enhanced version with images and edit/view
        ],
      ),
    );
  }
}