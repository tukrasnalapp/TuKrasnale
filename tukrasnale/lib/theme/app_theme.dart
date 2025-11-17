import 'package:flutter/material.dart';

class TuKrasnaleColors {
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

class TuKrasnaleTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: TuKrasnaleColors.darkBrown,
        primary: TuKrasnaleColors.darkBrown,
        secondary: TuKrasnaleColors.brickRed,
        tertiary: TuKrasnaleColors.skyBlue,
        surface: TuKrasnaleColors.surface,
        background: TuKrasnaleColors.background,
        error: TuKrasnaleColors.error,
        onPrimary: TuKrasnaleColors.textOnDark,
        onSecondary: TuKrasnaleColors.textOnDark,
        onSurface: TuKrasnaleColors.textPrimary,
        onBackground: TuKrasnaleColors.textPrimary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: TuKrasnaleColors.background,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: TuKrasnaleColors.darkBrown,
        foregroundColor: TuKrasnaleColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: TuKrasnaleColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: TuKrasnaleColors.textOnDark,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: TuKrasnaleColors.surface,
        selectedItemColor: TuKrasnaleColors.brickRed,
        unselectedItemColor: TuKrasnaleColors.textLight,
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
          backgroundColor: TuKrasnaleColors.brickRed,
          foregroundColor: TuKrasnaleColors.textOnDark,
          elevation: 2,
          shadowColor: TuKrasnaleColors.darkBrown.withOpacity(0.3),
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
          backgroundColor: TuKrasnaleColors.beige,
          foregroundColor: TuKrasnaleColors.darkBrown,
          side: const BorderSide(
            color: TuKrasnaleColors.darkBrown,
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
          foregroundColor: TuKrasnaleColors.brickRed,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: TuKrasnaleColors.surface,
        elevation: 2,
        shadowColor: TuKrasnaleColors.darkBrown.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TuKrasnaleColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnaleColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnaleColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnaleColors.brickRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TuKrasnaleColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: TuKrasnaleColors.textSecondary),
        hintStyle: const TextStyle(color: TuKrasnaleColors.textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TuKrasnaleColors.brickRed,
        foregroundColor: TuKrasnaleColors.textOnDark,
        elevation: 6,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: TuKrasnaleColors.surface,
        elevation: 8,
        shadowColor: TuKrasnaleColors.darkBrown.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: TuKrasnaleColors.textSecondary,
          fontSize: 16,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: TuKrasnaleColors.lightBeige,
        selectedColor: TuKrasnaleColors.skyBlue,
        labelStyle: const TextStyle(color: TuKrasnaleColors.textPrimary),
        side: const BorderSide(color: TuKrasnaleColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TuKrasnaleColors.brickRed,
        linearTrackColor: TuKrasnaleColors.lightBeige,
        circularTrackColor: TuKrasnaleColors.lightBeige,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: TuKrasnaleColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: TuKrasnaleColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: TuKrasnaleColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: TuKrasnaleColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: TuKrasnaleColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Custom Widgets with Theme
class TuKrasnaleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isSecondary;
  final IconData? icon;

  const TuKrasnaleButton({
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

class TuKrasnaleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const TuKrasnaleCard({
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