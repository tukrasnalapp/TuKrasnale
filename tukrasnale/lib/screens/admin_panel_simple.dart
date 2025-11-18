import 'package:flutter/material.dart';
import '../screens/enhanced_add_krasnal_tab.dart';
import '../widgets/app_logo.dart';
import '../theme/app_theme.dart';

class AdminPanelSimple extends StatefulWidget {
  const AdminPanelSimple({super.key});

  @override
  State<AdminPanelSimple> createState() => _AdminPanelSimpleState();
}

class _AdminPanelSimpleState extends State<AdminPanelSimple> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const ThemedAppBar(
          title: 'Admin Panel',
          showLogo: true,
        ),
        body: Column(
          children: [
            Container(
              color: TuKrasnalColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: TuKrasnalColors.brickRed,
                unselectedLabelColor: TuKrasnalColors.textSecondary,
                indicatorColor: TuKrasnalColors.brickRed,
                tabs: const [
                  Tab(text: 'Add Krasnal', icon: Icon(Icons.add_location)),
                  Tab(text: 'Manage', icon: Icon(Icons.manage_accounts)),
                  Tab(text: 'Reports', icon: Icon(Icons.report_problem)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const EnhancedAddKrasnalTab(),
                  _buildManageTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTab() {
    return Container(
      color: TuKrasnalColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_accounts,
              size: 64,
              color: TuKrasnalColors.darkBrown,
            ),
            const SizedBox(height: 16),
            Text(
              'Manage Krasnale',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'View and edit existing krasnale',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Container(
      color: TuKrasnalColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem,
              size: 64,
              color: TuKrasnalColors.brickRed,
            ),
            const SizedBox(height: 16),
            Text(
              'User Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Review and manage user-submitted reports',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}