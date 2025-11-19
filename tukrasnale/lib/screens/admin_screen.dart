import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_bar_theme.dart';
import '../screens/enhanced_add_krasnal_tab.dart';
import '../screens/enhanced_manage_krasnale_tab.dart';

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
      appBar: TuKrasnalAppBar.createMain(
        title: 'Tu Krasnale - Admin',
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: TuKrasnalColors.brickRed,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
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
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                EnhancedAddKrasnalTab(),
                EnhancedManageKrasnaleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}