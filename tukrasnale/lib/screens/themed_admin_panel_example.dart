import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/image_upload_widget.dart';
import '../models/krasnal_models.dart';
import '../services/image_upload_service.dart';

class ThemedAdminPanelExample extends StatefulWidget {
  const ThemedAdminPanelExample({super.key});

  @override
  State<ThemedAdminPanelExample> createState() => _ThemedAdminPanelExampleState();
}

class _ThemedAdminPanelExampleState extends State<ThemedAdminPanelExample> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _pointsController = TextEditingController();
  
  KrasnalRarity _selectedRarity = KrasnalRarity.common;
  String? _imageUrl;
  bool _isSubmitting = false;

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
            // Themed Tab Bar
            Container(
              color: TuKrasnaleColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: TuKrasnaleColors.brickRed,
                unselectedLabelColor: TuKrasnaleColors.textSecondary,
                indicatorColor: TuKrasnaleColors.brickRed,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Add Krasnal', icon: Icon(Icons.add_location)),
                  Tab(text: 'Manage', icon: Icon(Icons.manage_accounts)),
                  Tab(text: 'Reports', icon: Icon(Icons.report_problem)),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: Container(
                color: TuKrasnaleColors.background,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddKrasnalTab(),
                    _buildManageTab(),
                    _buildReportsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddKrasnalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Add New Krasnal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the details to add a new krasnal to the database.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Basic Information Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Krasnal Name *',
                    hintText: 'Enter the name of the krasnal',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the krasnal',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Location Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g., Near Market Square',
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitudeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Latitude *',
                          hintText: '51.1079',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _longitudeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Longitude *',
                          hintText: '17.0385',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TuKrasnaleButton(
                  text: 'Pick from Map',
                  onPressed: () {
                    // Map picker functionality
                  },
                  icon: Icons.map,
                  isSecondary: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Game Properties Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Properties',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Rarity Dropdown
                DropdownButtonFormField<KrasnalRarity>(
                  value: _selectedRarity,
                  decoration: const InputDecoration(
                    labelText: 'Rarity',
                  ),
                  items: KrasnalRarity.values.map((rarity) {
                    return DropdownMenuItem<KrasnalRarity>(
                      value: rarity,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getRarityColor(rarity),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(rarity.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (KrasnalRarity? newRarity) {
                    setState(() {
                      _selectedRarity = newRarity!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Points Field
                TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points Value *',
                    hintText: '10',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image Upload Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main Image',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                ImageUploadWidget(
                  initialImageUrl: _imageUrl,
                  uploadType: ImageUploadType.krasnaleMain,
                  onImageSelected: (url) => setState(() => _imageUrl = url),
                  title: 'Krasnal Photo',
                  required: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: TuKrasnaleButton(
              text: _isSubmitting ? 'Creating...' : 'Create Krasnal',
              onPressed: _isSubmitting ? null : _submitForm,
              icon: Icons.add_location_alt,
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    return Container(
      color: TuKrasnaleColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_accounts,
              size: 64,
              color: TuKrasnaleColors.darkBrown,
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
            const SizedBox(height: 24),
            TuKrasnaleButton(
              text: 'Load Krasnale List',
              onPressed: () {
                // Load functionality
              },
              icon: Icons.list,
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Container(
      color: TuKrasnaleColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem,
              size: 64,
              color: TuKrasnaleColors.brickRed,
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
            const SizedBox(height: 24),
            TuKrasnaleButton(
              text: 'View Reports',
              onPressed: () {
                // Reports functionality
              },
              icon: Icons.inbox,
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(KrasnalRarity rarity) {
    switch (rarity) {
      case KrasnalRarity.common:
        return Colors.grey;
      case KrasnalRarity.rare:
        return TuKrasnaleColors.skyBlue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
  }

  void _submitForm() {
    setState(() {
      _isSubmitting = true;
    });
    
    // Simulate form submission
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Krasnal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _nameController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        _pointsController.clear();
        setState(() {
          _imageUrl = null;
          _selectedRarity = KrasnalRarity.common;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}