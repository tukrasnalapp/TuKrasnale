import 'package:flutter/material.dart';
import 'app_theme.dart';

// Consistent AppBar styling for Tu Krasnale app
class TuKrasnalAppBar {
  static AppBar create({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: TuKrasnalColors.brickRed,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
    );
  }
  
  // For main screens with custom styling
  static AppBar createMain({
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: TuKrasnalColors.brickRed,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }
}