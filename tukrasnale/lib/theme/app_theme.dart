// 🎨 TU KRASNALE APP THEME
// 
// This file contains the complete Material 3 theme for the Tu Krasnale app.
// Color palette inspired by traditional Polish dwarf statues and Kraków's aesthetic.
//
// Usage:
// - Apply theme in main.dart: theme: TuKrasnalTheme.lightTheme
// - Use colors: TuKrasnalColors.brickRed, TuKrasnalColors.darkBrown, etc.
// - Use custom widgets: TuKrasnalButton, TuKrasnalCard
// - Use AppBar factory: TuKrasnalAppBar.create() (import app_bar_theme.dart)

import 'package:flutter/material.dart';

class TuKrasnalColors {
  // Primary Color Palette
  static const Color background = Color(0xFFF5E6D3);      // Soft Beige
  static const Color darkBrown = Color(0xFF4A2E1F);       // Logo & Header
  static const Color brickRed = Color(0xFFD94F3D);        // Primary Button
  static const Color skyBlue = Color(0xFF8FC9C9);         // Accent Element
  static const Color forestGreen = Color(0xFF6A7B4F);     // Accent Element
  
  // Secondary Colors
  static const Color beige = Color(0xFFF5E6D3);           // Secondary Button Background
  static const Color lightBeige = Color(0xFFF9F1E7);      // Lighter variant
  static const Color darkBrownLight = Color(0xFF6B4433);  // Lighter brown variant
  
  // Functional Colors
  static const Color success = forestGreen;
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = skyBlue;
  
  // Text Colors
  static const Color textPrimary = darkBrown;
  static const Color textSecondary = Color(0xFF6B4433);
  static const Color textLight = Color(0xFF8D6E63);
  static const Color textOnDark = Colors.white;
  
  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = lightBeige;
  static const Color outline = Color(0xFFD7CCC8);
}

class TuKrasnalTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: TuKrasnalColors.darkBrown,
        primary: TuKrasnalColors.darkBrown,
        secondary: TuKrasnalColors.brickRed,
        tertiary: TuKrasnalColors.skyBlue,
        surface: TuKrasnalColors.surface,
        background: TuKrasnalColors.background,
        error: TuKrasnalColors.error,
        onPrimary: TuKrasnalColors.textOnDark,
        onSecondary: TuKrasnalColors.textOnDark,
        onSurface: TuKrasnalColors.textPrimary,
        onBackground: TuKrasnalColors.textPrimary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: TuKrasnalColors.background,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: TuKrasnalColors.darkBrown,
        foregroundColor: TuKrasnalColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: TuKrasnalColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: TuKrasnalColors.textOnDark,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: TuKrasnalColors.surface,
        selectedItemColor: TuKrasnalColors.brickRed,
        unselectedItemColor: TuKrasnalColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TuKrasnalColors.brickRed,
          foregroundColor: TuKrasnalColors.textOnDark,
          elevation: 2,
          shadowColor: TuKrasnalColors.darkBrown.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme (Secondary Button)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: TuKrasnalColors.beige,
          foregroundColor: TuKrasnalColors.darkBrown,
          side: const BorderSide(
            color: TuKrasnalColors.darkBrown,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TuKrasnalColors.brickRed,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: TuKrasnalColors.surface,
        elevation: 2,
        shadowColor: TuKrasnalColors.darkBrown.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TuKrasnalColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnalColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnalColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnalColors.brickRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnalColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: TuKrasnalColors.textSecondary),
        hintStyle: const TextStyle(color: TuKrasnalColors.textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TuKrasnalColors.brickRed,
        foregroundColor: TuKrasnalColors.textOnDark,
        elevation: 6,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: TuKrasnalColors.surface,
        elevation: 8,
        shadowColor: TuKrasnalColors.darkBrown.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: TuKrasnalColors.textSecondary,
          fontSize: 16,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: TuKrasnalColors.lightBeige,
        selectedColor: TuKrasnalColors.skyBlue,
        labelStyle: const TextStyle(color: TuKrasnalColors.textPrimary),
        side: const BorderSide(color: TuKrasnalColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TuKrasnalColors.brickRed,
        linearTrackColor: TuKrasnalColors.lightBeige,
        circularTrackColor: TuKrasnalColors.lightBeige,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: TuKrasnalColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: TuKrasnalColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: TuKrasnalColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: TuKrasnalColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: TuKrasnalColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Custom Widgets with Theme
class TuKrasnalButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isSecondary;
  final IconData? icon;

  const TuKrasnalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(text),
              style: style,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(text),
            );
    } else {
      return icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(text),
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(text),
            );
    }
  }
}

class TuKrasnalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const TuKrasnalCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}