// 🎨 CONSISTENT APP BAR STYLING - IMPLEMENTATION GUIDE
//
// This file shows how to apply the brick red header styling 
// consistently across all screens in the Tu Krasnale app

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_bar_theme.dart';

// EXAMPLE 1: Main Admin Screen
class ExampleAdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuKrasnalAppBar.createMain(
        title: 'Tu Krasnale - Admin',
        actions: [
          IconButton(
            onPressed: () {
              // Settings or other global actions
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      // ...existing body...
    );
  }
}

// EXAMPLE 2: Detail Screen (Edit/View)
class ExampleDetailScreen extends StatelessWidget {
  final String krasnalName;
  
  const ExampleDetailScreen({required this.krasnalName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuKrasnalAppBar.create(
        title: krasnalName,
        actions: [
          IconButton(
            onPressed: () {
              // Edit action
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () {
              // Delete action
            },
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      // ...existing body...
    );
  }
}

// EXAMPLE 3: Add/Create Screen
class ExampleAddScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuKrasnalAppBar.create(
        title: 'Add New Krasnal',
        actions: [
          IconButton(
            onPressed: () {
              // Save/Submit action
            },
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      // ...existing body...
    );
  }
}

// EXAMPLE 4: Map/Location Picker
class ExampleMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuKrasnalAppBar.create(
        title: 'Select Location',
        actions: [
          IconButton(
            onPressed: () {
              // Confirm location
            },
            icon: const Icon(Icons.check),
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      // ...existing body...
    );
  }
}

// EXAMPLE 5: List/Management Screen
class ExampleManageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TuKrasnalAppBar.create(
        title: 'Manage Krasnale',
        actions: [
          IconButton(
            onPressed: () {
              // Filter or search
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              // Add new
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add New',
          ),
        ],
      ),
      // ...existing body...
    );
  }
}

// SCREENS TO UPDATE:
// ✅ 1. AdminScreen - Use TuKrasnalAppBar.createMain()
// ✅ 2. KrasnalDetailScreen - Use TuKrasnalAppBar.create() 
// ✅ 3. EditKrasnalScreen - Use TuKrasnalAppBar.create()
// ✅ 4. EnhancedAddKrasnalTab - Use TuKrasnalAppBar.create() (if in Scaffold)
// ✅ 5. ManageKrasnaleTab - Use TuKrasnalAppBar.create() (if in Scaffold)
// ✅ 6. MapPickerScreen - Use TuKrasnalAppBar.create()
// ✅ 7. Any other screens with AppBar

// QUICK REPLACEMENT PATTERN:
/*
// Replace this:
appBar: AppBar(
  title: Text('Title'),
  backgroundColor: TuKrasnalColors.brickRed,
  iconTheme: const IconThemeData(color: Colors.white),
  // ...actions
),

// With this:
appBar: TuKrasnalAppBar.create(
  title: 'Title',
  actions: [
    // ...same actions
  ],
),
*/