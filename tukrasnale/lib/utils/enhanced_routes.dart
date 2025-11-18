import 'package:flutter/material.dart';
import '../screens/enhanced_admin_screen.dart';
import '../screens/krasnal_detail_screen.dart';
import '../screens/edit_krasnal_screen.dart';
import '../models/krasnal_models.dart';

class EnhancedAppRoutes {
  static const String enhancedAdmin = '/enhanced-admin';
  static const String krasnalDetail = '/krasnal-detail';
  static const String editKrasnal = '/edit-krasnal';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case enhancedAdmin:
        return MaterialPageRoute(
          builder: (context) => const EnhancedAdminScreen(),
        );
      
      case krasnalDetail:
        final krasnal = settings.arguments as KrasnalModel;
        return MaterialPageRoute(
          builder: (context) => KrasnalDetailScreen(krasnal: krasnal),
        );
      
      case editKrasnal:
        final krasnal = settings.arguments as KrasnalModel;
        return MaterialPageRoute(
          builder: (context) => EditKrasnalScreen(krasnal: krasnal),
        );
      
      default:
        return null;
    }
  }

  // Helper methods for navigation
  static void pushEnhancedAdmin(BuildContext context) {
    Navigator.pushNamed(context, enhancedAdmin);
  }

  static void pushKrasnalDetail(BuildContext context, KrasnalModel krasnal) {
    Navigator.pushNamed(context, krasnalDetail, arguments: krasnal);
  }

  static void pushEditKrasnal(BuildContext context, KrasnalModel krasnal) {
    Navigator.pushNamed(context, editKrasnal, arguments: krasnal);
  }
}

// Floating Action Button to quickly access enhanced admin
class EnhancedAdminFAB extends StatelessWidget {
  const EnhancedAdminFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => EnhancedAppRoutes.pushEnhancedAdmin(context),
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Enhanced Admin'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }
}