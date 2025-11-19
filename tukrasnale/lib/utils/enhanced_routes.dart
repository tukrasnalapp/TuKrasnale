import 'package:flutter/material.dart';
import '../screens/admin_screen.dart';
import '../screens/krasnal_detail_screen.dart';
import '../screens/edit_krasnal_screen.dart';
import '../models/krasnal_models.dart';

class EnhancedAppRoutes {
  static const String adminPanel = '/admin-panel';
  static const String krasnalDetail = '/krasnal-detail';
  static const String editKrasnal = '/edit-krasnal';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminPanel:
        return MaterialPageRoute(
          builder: (context) => const AdminScreen(),
        );
      
      case krasnalDetail:
        final krasnal = settings.arguments as Krasnal;
        return MaterialPageRoute(
          builder: (context) => KrasnalDetailScreen(krasnal: krasnal),
        );
      
      case editKrasnal:
        final krasnal = settings.arguments as Krasnal;
        return MaterialPageRoute(
          builder: (context) => EditKrasnalScreen(krasnal: krasnal),
        );
      
      default:
        return null;
    }
  }

  // Helper methods for navigation
  static void pushAdminPanel(BuildContext context) {
    Navigator.pushNamed(context, adminPanel);
  }

  static void pushKrasnalDetail(BuildContext context, Krasnal krasnal) {
    Navigator.pushNamed(context, krasnalDetail, arguments: krasnal);
  }

  static void pushEditKrasnal(BuildContext context, Krasnal krasnal) {
    Navigator.pushNamed(context, editKrasnal, arguments: krasnal);
  }
}

// Floating Action Button to quickly access admin panel
class EnhancedAdminFAB extends StatelessWidget {
  const EnhancedAdminFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => EnhancedAppRoutes.pushAdminPanel(context),
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Admin Panel'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }
}