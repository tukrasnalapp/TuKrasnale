import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';
import '../models/krasnal_models.dart';
import '../models/report_models.dart';
import '../services/admin_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/image_upload_widget.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_location), text: 'Add Krasnal'),
            Tab(icon: Icon(Icons.list), text: 'Manage Krasnale'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AddKrasnalTab(),
          _ManageKrasnaleTab(),
          _ReportsTab(),
        ],
      ),
    );
  }
}

class _AddKrasnalTab extends StatefulWidget {
  @override
  State<_AddKrasnalTab> createState() => _AddKrasnalTabState();
}

class _AddKrasnalTabState extends State<_AddKrasnalTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  
  KrasnalRarity _selectedRarity = KrasnalRarity.common;
  String? _imageUrl;
  String? _undiscoveredMedallionUrl;
  String? _discoveredMedallionUrl;
  List<String> _galleryImages = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Krasnal Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Location name field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Rynek, Park Słowackiego',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Coordinates Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinates',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Latitude is required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid latitude';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Longitude is required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid longitude';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickLocationFromMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Pick from Map'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Game Properties Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Properties',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Rarity dropdown
                    DropdownButtonFormField<KrasnalRarity>(
                      value: _selectedRarity,
                      decoration: const InputDecoration(
                        labelText: 'Rarity',
                        border: OutlineInputBorder(),
                      ),
                      items: KrasnalRarity.values.map((rarity) {
                        return DropdownMenuItem(
                          value: rarity,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getRarityColor(rarity),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(rarity.name.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRarity = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Points value
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Points value is required';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Invalid points value';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Image Upload
                    ImageUploadWidget(
                      initialImageUrl: _imageUrl,
                      uploadType: ImageUploadType.krasnaleMain,
                      onImageSelected: (url) => setState(() => _imageUrl = url),
                      title: 'Main Image',
                    ),
                    const SizedBox(height: 16),
                    
                    // Undiscovered Medallion Upload
                    ImageUploadWidget(
                      initialImageUrl: _undiscoveredMedallionUrl,
                      uploadType: ImageUploadType.krasnaleUndiscoveredMedallion,
                      onImageSelected: (url) => setState(() => _undiscoveredMedallionUrl = url),
                      title: 'Undiscovered Medallion',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    
                    // Discovered Medallion Upload  
                    ImageUploadWidget(
                      initialImageUrl: _discoveredMedallionUrl,
                      uploadType: ImageUploadType.krasnaleDiscoveredMedallion,
                      onImageSelected: (url) => setState(() => _discoveredMedallionUrl = url),
                      title: 'Discovered Medallion',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    
                    // Gallery Images Upload
                    MultipleImageUploadWidget(
                      initialImageUrls: _galleryImages,
                      uploadType: ImageUploadType.krasnaleGallery,
                      onImagesChanged: (urls) => setState(() => _galleryImages = urls),
                      title: 'Gallery Images',
                      maxImages: 5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitKrasnal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Create Krasnal'),
              ),
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
        return Colors.blue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
  }

  void _pickLocationFromMap() {
    // TODO: Implement map picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker coming soon!')),
    );
  }

  void _submitKrasnal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // TODO: Implement actual submission
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Krasnal created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating krasnal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _latController.clear();
    _lngController.clear();
    _pointsController.text = '10';
    setState(() {
      _selectedRarity = KrasnalRarity.common;
      _imageUrl = null;
      _undiscoveredMedallionUrl = null;
      _discoveredMedallionUrl = null;
      _galleryImages.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}

// Placeholder for Manage Krasnale tab
class _ManageKrasnaleTab extends StatefulWidget {
  @override
  State<_ManageKrasnaleTab> createState() => _ManageKrasnaleTabState();
}

class _ManageKrasnaleTabState extends State<_ManageKrasnaleTab> {
  final AdminService _adminService = AdminService();
  List<KrasnalModel> _krasnale = [];
  bool _isLoading = false;
  String _searchQuery = '';
  KrasnalRarity? _filterRarity;

  @override
  void initState() {
    super.initState();
    _loadKrasnale();
  }

  Future<void> _loadKrasnale() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final krasnale = await _adminService.getAllKrasnale();
      if (mounted) {
        setState(() {
          _krasnale = krasnale;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading krasnale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<KrasnalModel> get _filteredKrasnale {
    var filtered = _krasnale;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((k) {
        final searchLower = _searchQuery.toLowerCase();
        return k.name.toLowerCase().contains(searchLower) ||
               (k.locationName?.toLowerCase().contains(searchLower) ?? false) ||
               (k.description?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Apply rarity filter
    if (_filterRarity != null) {
      filtered = filtered.where((k) => k.rarity == _filterRarity).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search krasnale...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Filter and Actions Row
              Row(
                children: [
                  // Rarity Filter
                  Expanded(
                    child: DropdownButtonFormField<KrasnalRarity?>(
                      value: _filterRarity,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Rarity',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<KrasnalRarity?>(
                          value: null,
                          child: Text('All Rarities'),
                        ),
                        ...KrasnalRarity.values.map((rarity) {
                          return DropdownMenuItem<KrasnalRarity?>(
                            value: rarity,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getRarityColor(rarity),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(rarity.name.toUpperCase()),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterRarity = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: _loadKrasnale,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Stats Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard('Total', _krasnale.length.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('Showing', _filteredKrasnale.length.toString(), Colors.green),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Krasnale List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredKrasnale.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredKrasnale.length,
                      itemBuilder: (context, index) {
                        final krasnal = _filteredKrasnale[index];
                        return _buildKrasnalCard(krasnal);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterRarity != null
                ? 'No krasnale match your filters'
                : 'No krasnale found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty || _filterRarity != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterRarity = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildKrasnalCard(KrasnalModel krasnal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Rarity Indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getRarityColor(krasnal.rarity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Name
                Expanded(
                  child: Text(
                    krasnal.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Points Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${krasnal.pointsValue} pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            if (krasnal.locationName != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    krasnal.locationName!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Coordinates
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${krasnal.latitude.toStringAsFixed(4)}, ${krasnal.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            // Description
            if (krasnal.description != null) ...[
              const SizedBox(height: 8),
              Text(
                krasnal.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _editKrasnal(krasnal),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewKrasnalDetails(krasnal),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _deleteKrasnal(krasnal),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
        return Colors.blue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
  }

  void _editKrasnal(KrasnalModel krasnal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${krasnal.name}'),
        content: const Text('Edit functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewKrasnalDetails(KrasnalModel krasnal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(krasnal.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (krasnal.description != null) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(krasnal.description!),
                const SizedBox(height: 12),
              ],
              const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(krasnal.locationName ?? 'Unknown'),
              const SizedBox(height: 8),
              const Text('Coordinates:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${krasnal.latitude}, ${krasnal.longitude}'),
              const SizedBox(height: 8),
              const Text('Rarity:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(krasnal.rarity.name.toUpperCase()),
              const SizedBox(height: 8),
              const Text('Points:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${krasnal.pointsValue}'),
              const SizedBox(height: 8),
              const Text('Created:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${krasnal.createdAt.day}/${krasnal.createdAt.month}/${krasnal.createdAt.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteKrasnal(KrasnalModel krasnal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Krasnal'),
        content: Text('Are you sure you want to delete "${krasnal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDelete(krasnal);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(KrasnalModel krasnal) async {
    try {
      await _adminService.deleteKrasnal(krasnal.id);
      await _loadKrasnale(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${krasnal.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting krasnal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Reports Management Tab
class _ReportsTab extends StatefulWidget {
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final AdminService _adminService = AdminService();
  List<KrasnaleReport> _reports = [];
  bool _isLoading = false;
  ReportStatus? _filterStatus;
  ReportType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _adminService.getAllReports();
      if (mounted) {
        setState(() {
          _reports = reports;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<KrasnaleReport> get _filteredReports {
    var filtered = _reports;

    if (_filterStatus != null) {
      filtered = filtered.where((r) => r.status == _filterStatus).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((r) => r.reportType == _filterType).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reports.where((r) => r.status == ReportStatus.pending).length;
    final inReviewCount = _reports.where((r) => r.status == ReportStatus.inReview).length;

    return Column(
      children: [
        // Stats and Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Row
              Row(
                children: [
                  _buildReportStatCard('Pending', pendingCount.toString(), Colors.orange),
                  const SizedBox(width: 8),
                  _buildReportStatCard('In Review', inReviewCount.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _buildReportStatCard('Total', _reports.length.toString(), Colors.grey),
                ],
              ),
              const SizedBox(height: 16),

              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ReportStatus?>(
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<ReportStatus?>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...ReportStatus.values.map((status) {
                          return DropdownMenuItem<ReportStatus?>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(_getStatusIcon(status), size: 16),
                                const SizedBox(width: 8),
                                Text(_getStatusText(status)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<ReportType?>(
                      value: _filterType,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<ReportType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...ReportType.values.map((type) {
                          return DropdownMenuItem<ReportType?>(
                            value: type,
                            child: Text(_getReportTypeTitle(type)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredReports.isEmpty
                  ? _buildReportsEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildReportStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus != null || _filterType != null
                ? 'No reports match your filters'
                : 'No reports yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(KrasnaleReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getStatusIcon(report.status),
                  color: _getStatusColor(report.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(report.status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Type and Date
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getReportTypeTitle(report.reportType),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description Preview
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),

            // Admin Notes (if any)
            if (report.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin: ${report.adminNotes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _viewReportDetails(report),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                if (report.status == ReportStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _updateReportStatus(report, ReportStatus.inReview),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                const SizedBox(width: 8),
                if (report.status != ReportStatus.resolved)
                  ElevatedButton.icon(
                    onPressed: () => _resolveReport(report),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                const SizedBox(width: 8),
                if (report.status != ReportStatus.rejected)
                  ElevatedButton.icon(
                    onPressed: () => _rejectReport(report),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.missing:
        return 'Missing Krasnal';
      case ReportType.wrongLocation:
        return 'Wrong Location';
      case ReportType.wrongInfo:
        return 'Wrong Information';
      case ReportType.damaged:
        return 'Damaged';
      case ReportType.newSuggestion:
        return 'New Suggestion';
      case ReportType.other:
        return 'Other';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inReview:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.inReview:
        return Icons.visibility;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  void _viewReportDetails(KrasnaleReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getReportTypeTitle(report.reportType)),
              const SizedBox(height: 12),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getStatusText(report.status)),
              const SizedBox(height: 12),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report.description),
              if (report.locationLat != null && report.locationLng != null) ...[
                const SizedBox(height: 12),
                const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${report.locationLat}, ${report.locationLng}'),
              ],
              if (report.adminNotes != null) ...[
                const SizedBox(height: 12),
                const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(report.adminNotes!),
              ],
              const SizedBox(height: 12),
              const Text('Submitted:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateReportStatus(KrasnaleReport report, ReportStatus status) async {
    try {
      await _adminService.updateReportStatus(report.id, status);
      await _loadReports(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resolveReport(KrasnaleReport report) {
    _showAdminNotesDialog(report, ReportStatus.resolved, 'Resolve Report');
  }

  void _rejectReport(KrasnaleReport report) {
    _showAdminNotesDialog(report, ReportStatus.rejected, 'Reject Report');
  }

  void _showAdminNotesDialog(KrasnaleReport report, ReportStatus newStatus, String title) {
    final notesController = TextEditingController(text: report.adminNotes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add admin notes for "${report.title}":'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateReportStatus(
                  report.id,
                  newStatus,
                  adminNotes: notesController.text,
                );
                await _loadReports(); // Refresh
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report ${_getStatusText(newStatus).toLowerCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating report: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(newStatus == ReportStatus.resolved ? 'Resolve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}