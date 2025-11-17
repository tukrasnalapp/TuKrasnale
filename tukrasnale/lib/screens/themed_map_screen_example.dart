import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../theme/app_theme.dart';

class ThemedMapScreen extends StatefulWidget {
  const ThemedMapScreen({super.key});

  @override
  State<ThemedMapScreen> createState() => _ThemedMapScreenState();
}

class _ThemedMapScreenState extends State<ThemedMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(
        title: 'Krasnale Map',
        showLogo: true,
      ),
      body: Container(
        color: TuKrasnaleColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 64,
                color: TuKrasnaleColors.darkBrown,
              ),
              const SizedBox(height: 16),
              Text(
                'Interactive Map',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Discover krasnale around you',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TuKrasnaleButton(
                text: 'Find Nearby Krasnale',
                onPressed: () {
                  // Map functionality will be implemented
                },
                icon: Icons.location_searching,
              ),
            ],
          ),
        ),
      ),
    );
  }
}