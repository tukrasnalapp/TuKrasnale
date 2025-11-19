import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Consistent AppBar styling for Tu Krasnale app
/// Provides different AppBar styles for various screen types
class TuKrasnalAppBar {
  /// Standard AppBar for most screens
  /// Uses the primary dark brown color with white text/icons
  static AppBar create({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: backgroundColor ?? TuKrasnalColors.darkBrown,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      centerTitle: true,
    );
  }
  
  /// Main AppBar for primary screens (admin dashboard, main screens)
  /// Uses larger text and more prominent elevation
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
      backgroundColor: TuKrasnalColors.darkBrown,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      centerTitle: true,
    );
  }

  /// Secondary AppBar using brick red color
  /// For special screens or admin-specific functions
  static AppBar createSecondary({
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
          fontSize: 18,
        ),
      ),
      backgroundColor: TuKrasnalColors.brickRed,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      centerTitle: true,
    );
  }

  /// Transparent AppBar for overlay screens (maps, full-screen views)
  static AppBar createTransparent({
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
          fontSize: 18,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black54,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 0,
    );
  }
}