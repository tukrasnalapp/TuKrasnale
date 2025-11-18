import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/image_upload_with_preview.dart';
import '../widgets/image_picker_bottom_sheet.dart';
import '../models/krasnal_models.dart';
import '../services/location_service.dart';
import '../services/admin_service.dart';
import '../services/image_upload_service.dart';
import '../screens/map_picker_screen.dart';

class EnhancedAddKrasnalTab extends StatefulWidget {
  const EnhancedAddKrasnalTab({super.key});

  @override
  State<EnhancedAddKrasnalTab> createState() => _EnhancedAddKrasnalTabState();
}

class _EnhancedAddKrasnalTabState extends State<EnhancedAddKrasnalTab> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _pointsController = TextEditingController();
  
  // Form state
  KrasnalRarity _selectedRarity = KrasnalRarity.common;
  String? _mainImageUrl;
  String? _undiscoveredMedallionUrl;
  String? _discoveredMedallionUrl;
  List<String> _galleryImages = [];
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TuKrasnalColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              
              // Location Card
              _buildLocationCard(),
              const SizedBox(height: 16),
              
              // Game Properties Card
              _buildGamePropertiesCard(),
              const SizedBox(height: 16),
              
              // Main Image Card
              _buildMainImageCard(),
              const SizedBox(height: 16),
              
              // Medallion Images Card
              _buildMedallionImagesCard(),
              const SizedBox(height: 16),
              
              // Gallery Images Card
              _buildGalleryImagesCard(),
              const SizedBox(height: 24),
              
              // Submit Button
              _buildSubmitButton(),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Krasnal Name *',
              hintText: 'Enter the name of the krasnal',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the krasnal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Location Name
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              hintText: 'e.g., Near Market Square',
            ),
          ),
          const SizedBox(height: 16),
          
          // Coordinate Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude *',
                    hintText: '51.1079',
                    suffixText: '°',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*$')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Latitude is required';
                    }
                    final parsed = LocationService.parseCoordinate(value.trim(), true);
                    if (parsed == null) {
                      return 'Invalid latitude (-90 to 90, max 8 decimals)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Auto-format coordinate
                    final parsed = LocationService.parseCoordinate(value, true);
                    if (parsed != null && value.contains('.')) {
                      final formatted = LocationService.formatCoordinate(parsed);
                      if (formatted != value) {
                        // Only update if significantly different to avoid cursor jumping
                        _latitudeController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    hintText: '17.0385',
                    suffixText: '°',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*$')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Longitude is required';
                    }
                    final parsed = LocationService.parseCoordinate(value.trim(), false);
                    if (parsed == null) {
                      return 'Invalid longitude (-180 to 180, max 8 decimals)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Auto-format coordinate
                    final parsed = LocationService.parseCoordinate(value, false);
                    if (parsed != null && value.contains('.')) {
                      final formatted = LocationService.formatCoordinate(parsed);
                      if (formatted != value) {
                        _longitudeController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Location Action Buttons
          Row(
            children: [
              Expanded(
                child: TuKrasnalButton(
                  text: _isGettingLocation ? 'Getting...' : 'Current Location',
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: Icons.my_location,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TuKrasnalButton(
                  text: 'Pick from Map',
                  onPressed: _pickFromMap,
                  icon: Icons.map,
                  isSecondary: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Coordinate Guidelines
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TuKrasnalColors.skyBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TuKrasnalColors.skyBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: TuKrasnalColors.skyBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latitude: -90 to 90 • Longitude: -180 to 180 • Max 8 decimal places',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TuKrasnalColors.skyBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePropertiesCard() {
    return TuKrasnalCard(
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
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points Value *',
              hintText: '10',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Points value is required';
              }
              final points = int.tryParse(value);
              if (points == null || points < 1) {
                return 'Please enter a valid points value (minimum 1)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageCard() {
    return TuKrasnalCard(
      child: ImageUploadWithPreview(
        initialImageUrl: _mainImageUrl,
        uploadType: ImageUploadType.krasnaleMain,
        onImageSelected: (url) => setState(() => _mainImageUrl = url),
        title: 'Main Krasnal Image',
        required: true,
        height: 250,
      ),
    );
  }

  Widget _buildMedallionImagesCard() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medallion Images',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload medallion images for undiscovered and discovered states.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ImageUploadWithPreview(
                  initialImageUrl: _undiscoveredMedallionUrl,
                  uploadType: ImageUploadType.krasnaleMain,
                  onImageSelected: (url) => setState(() => _undiscoveredMedallionUrl = url),
                  title: 'Undiscovered',
                  height: 120,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ImageUploadWithPreview(
                  initialImageUrl: _discoveredMedallionUrl,
                  uploadType: ImageUploadType.krasnaleMain,
                  onImageSelected: (url) => setState(() => _discoveredMedallionUrl = url),
                  title: 'Discovered',
                  height: 120,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImagesCard() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gallery Images',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Add up to 5 additional images (${_galleryImages.length}/5)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (_galleryImages.length < 5)
                IconButton(
                  onPressed: _addGalleryImage,
                  icon: Icon(
                    Icons.add_photo_alternate,
                    color: TuKrasnalColors.brickRed,
                  ),
                ),
            ],
          ),
          
          if (_galleryImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _galleryImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TuKrasnalColors.outline),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeGalleryImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: TuKrasnalColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: TuKrasnalColors.outline,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 32,
                      color: TuKrasnalColors.textLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No gallery images added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TuKrasnalColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: TuKrasnalButton(
        text: _isSubmitting ? 'Creating Krasnal...' : 'Create Krasnal',
        onPressed: (_isSubmitting || _mainImageUrl == null) ? null : _submitForm,
        icon: Icons.add_location_alt,
      ),
    );
  }

  Color _getRarityColor(KrasnalRarity rarity) {
    switch (rarity) {
      case KrasnalRarity.common:
        return TuKrasnalColors.textLight;
      case KrasnalRarity.rare:
        return TuKrasnalColors.skyBlue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locationResult = await LocationService().getCurrentLocation();
      
      if (locationResult != null && locationResult.success && mounted) {
        setState(() {
          _latitudeController.text = LocationService.formatCoordinate(locationResult.latitude);
          _longitudeController.text = LocationService.formatCoordinate(locationResult.longitude);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationResult?.error ?? 'Unknown location error'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => LocationService().openLocationSettings(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _pickFromMap() async {
    double? currentLat;
    double? currentLng;
    
    // Parse current coordinates if available
    if (_latitudeController.text.isNotEmpty) {
      currentLat = LocationService.parseCoordinate(_latitudeController.text, true);
    }
    if (_longitudeController.text.isNotEmpty) {
      currentLng = LocationService.parseCoordinate(_longitudeController.text, false);
    }

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: currentLat,
          initialLongitude: currentLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitudeController.text = LocationService.formatCoordinate(result['latitude']!);
        _longitudeController.text = LocationService.formatCoordinate(result['longitude']!);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location selected from map!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addGalleryImage() async {
    if (_galleryImages.length >= 5) return;

    final result = await ImagePickerBottomSheet.show(
      context,
      ImageUploadType.krasnaleMain,
    );

    if (result != null && result.success && result.url != null && mounted) {
      setState(() {
        _galleryImages.add(result.url!);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery image added!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery image removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mainImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a main image for the krasnal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _adminService.createKrasnal(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        locationName: _locationController.text.trim(),
        rarity: _selectedRarity,
        pointsValue: int.parse(_pointsController.text),
        imageUrl: _mainImageUrl!,
      );

      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Krasnal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create krasnal. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _pointsController.clear();
    
    setState(() {
      _selectedRarity = KrasnalRarity.common;
      _mainImageUrl = null;
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
    _latitudeController.dispose();
    _longitudeController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}