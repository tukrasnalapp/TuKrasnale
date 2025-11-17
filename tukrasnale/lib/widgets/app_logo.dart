import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo from Supabase storage
        Image.network(
          'https://tpygmwuqcdhycvtqmhzd.supabase.co/storage/v1/object/public/app/logo.png',
          width: width ?? 40,
          height: height ?? 40,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width ?? 40,
              height: height ?? 40,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Fallback to text logo if image fails to load
            return Container(
              width: width ?? 40,
              height: height ?? 40,
              decoration: const BoxDecoration(
                color: Color(0xFF4A2E1F), // Dark brown
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'TK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        ),
        
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'TuKrasnale',
            style: TextStyle(
              fontSize: (height ?? 40) * 0.6,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
        ],
      ],
    );
  }
}

class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? leading;

  const ThemedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(width: 32, height: 32),
                const SizedBox(width: 12),
                Text(title),
              ],
            )
          : Text(title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}