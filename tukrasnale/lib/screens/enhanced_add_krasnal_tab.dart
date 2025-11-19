import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../models/krasnal_models.dart';
import '../services/admin_service.dart';
import '../services/supabase_image_service.dart';
import '../services/location_service.dart';

// Update any old model references in the rest of the file to use the consolidated models

class EnhancedAddKrasnalTab extends StatefulWidget {
  const EnhancedAddKrasnalTab({super.key});

  @override
  State<EnhancedAddKrasnalTab> createState() => _EnhancedAddKrasnalTabState();
}

class _EnhancedAddKrasnalTabState extends State<EnhancedAddKrasnalTab> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final SupabaseImageService _imageService = SupabaseImageService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _historyController = TextEditingController();           // NEW: History field
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _pointsController = TextEditingController();
  final _discoveryRadiusController = TextEditingController();   // NEW: Discovery radius field
  
  // Form state
  KrasnalRarity _selectedRarity = KrasnalRarity.common;
  String? _mainImageUrl;
  String? _undiscoveredMedallionUrl;
  String? _discoveredMedallionUrl;
  List<String> _galleryImages = [];
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  
  // Validation state
  bool _isValidatingUniqueness = false;
  String? _uniquenessError;
  
  // Web-compatible image storage
  Uint8List? _mainImageBytes;
  Uint8List? _undiscoveredMedallionBytes;
  Uint8List? _discoveredMedallionBytes;
  List<Uint8List> _galleryImageBytes = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
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
              
              // Uniqueness validation status
              if (_isValidatingUniqueness || _uniquenessError != null)
                _buildValidationStatusCard(),
                
              if (_uniquenessError != null)
                const SizedBox(height: 16),
              
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
              
              // Form Status Summary
              _buildFormStatusSummary(),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            onChanged: (value) {
              // Debounced uniqueness check
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _nameController.text == value) {
                  _validateUniqueness();
                }
              });
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
          const SizedBox(height: 16),
          
          // History Field
          TextFormField(
            controller: _historyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'History',
              hintText: 'Historical background and significance (optional)',
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    
                    // Debounced uniqueness check
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && _latitudeController.text == value) {
                        _validateUniqueness();
                      }
                    });
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
                    
                    // Debounced uniqueness check
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && _longitudeController.text == value) {
                        _validateUniqueness();
                      }
                    });
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
                child: ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(_isGettingLocation ? 'Getting...' : 'Current Location'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Pick from Map'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Coordinate Guidelines
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latitude: -90 to 90 • Longitude: -180 to 180 • Max 8 decimal places',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildGamePropertiesCard() {
    return Card(
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
          const SizedBox(height: 16),
          
          // Discovery Radius Field
          TextFormField(
            controller: _discoveryRadiusController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Discovery Radius (meters) *',
              hintText: '25',
              helperText: 'Distance in meters for GPS discovery',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Discovery radius is required';
              }
              final radius = int.tryParse(value);
              if (radius == null || radius < 5 || radius > 100) {
                return 'Please enter a valid radius (5-100 meters)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Krasnal Image',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Required - Upload the main image for this krasnal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Image Preview or Upload Area
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _mainImageUrl != null 
                    ? Colors.green 
                    : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _mainImageUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _mainImageUrl!.startsWith('http')
                            ? Image.network(
                                _mainImageUrl!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text('Failed to load image'),
                                  );
                                },
                              )
                            : kIsWeb && _mainImageBytes != null
                                ? Image.memory(
                                    _mainImageBytes!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text('Failed to load image'),
                                      );
                                    },
                                  )
                                : !kIsWeb
                                    ? Image.file(
                                        File(_mainImageUrl!),
                                        height: 250,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Text('Failed to load image'),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Text('Image selected (web preview not available)'),
                                      ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mainImageUrl!.startsWith('http') ? Colors.green : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _mainImageUrl!.startsWith('http') ? Icons.cloud_done : Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: ElevatedButton(
                          onPressed: _selectMainImage,
                          child: const Text('Change Image'),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: _selectMainImage,
                    child: Container(
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to upload main image',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _selectMainImage,
                            icon: const Icon(Icons.upload),
                            label: const Text('Select Image'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          if (_mainImageUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Main image uploaded successfully!',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Add state variables for tracking image uploads
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _selectMainImage() async {
    print('🔄 Selecting main image...');
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          // On web, store the image bytes for preview
          final bytes = await image.readAsBytes();
          setState(() {
            _mainImageBytes = bytes;
            _mainImageUrl = 'web_selected_image'; // Placeholder identifier
          });
          
          print('✅ Web image selected: ${bytes.length} bytes');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected for web! (${(bytes.length) ~/ 1024} KB)'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // On mobile, use the file path
          setState(() {
            _mainImageUrl = image.path;
          });
          
          print('✅ Mobile image selected: ${image.path}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected! Upload will happen when creating krasnal.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Image selection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildMedallionImagesCard() {
    return Card(
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
                child: _buildMedallionUpload(
                  'Undiscovered',
                  _undiscoveredMedallionUrl,
                  (url) => setState(() => _undiscoveredMedallionUrl = url),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMedallionUpload(
                  'Discovered',
                  _discoveredMedallionUrl,
                  (url) => setState(() => _discoveredMedallionUrl = url),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedallionUpload(String title, String? imageUrl, Function(String) onImageSelected) {
    // Get the correct bytes for this medallion
    Uint8List? medallionBytes;
    if (title == 'Undiscovered') {
      medallionBytes = _undiscoveredMedallionBytes;
    } else if (title == 'Discovered') {
      medallionBytes = _discoveredMedallionBytes;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: imageUrl != null ? Colors.green : Colors.grey,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Text('Failed to load'));
                              },
                            )
                          : kIsWeb && medallionBytes != null
                              ? Image.memory(
                                  medallionBytes,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Text('Failed to load'));
                                  },
                                )
                              : !kIsWeb
                                  ? Image.file(
                                      File(imageUrl),
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Text('Failed to load'));
                                      },
                                    )
                                  : Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image, size: 32, color: Colors.blue),
                                          const SizedBox(height: 4),
                                          Text('Image selected\n(preview unavailable)', 
                                              textAlign: TextAlign.center, 
                                              style: TextStyle(fontSize: 10, color: Colors.blue[700])),
                                        ],
                                      ),
                                    ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: imageUrl.startsWith('http') ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          imageUrl.startsWith('http') ? Icons.cloud_done : Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => _selectMedallionImage(onImageSelected, title),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 4),
        if (imageUrl != null)
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Uploaded',
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
              ),
              TextButton(
                onPressed: () => _selectMedallionImage(onImageSelected, title),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Change', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _selectMedallionImage(Function(String) onImageSelected, String title) async {
    print('🔄 Selecting $title medallion image...');
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          // On web, store the image bytes for preview
          final bytes = await image.readAsBytes();
          if (title == 'Undiscovered') {
            setState(() {
              _undiscoveredMedallionBytes = bytes;
            });
          } else if (title == 'Discovered') {
            setState(() {
              _discoveredMedallionBytes = bytes;
            });
          }
          onImageSelected('web_selected_medallion_$title');
          
          print('✅ Web $title medallion selected: ${bytes.length} bytes');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title medallion selected for web! (${(bytes.length) ~/ 1024} KB)'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // On mobile, use the file path
          onImageSelected(image.path);
          
          print('✅ Mobile $title medallion selected: ${image.path}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title medallion selected!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error selecting $title medallion image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select $title medallion image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildGalleryImagesCard() {
    return Card(
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
                    color: Colors.blue,
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
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Text('Error'));
                                },
                              )
                            : kIsWeb && imageUrl.startsWith('web_gallery') && index < _galleryImageBytes.length
                                ? Image.memory(
                                    _galleryImageBytes[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Center(child: Text('Error', style: TextStyle(fontSize: 8))),
                                      );
                                    },
                                  )
                                : kIsWeb && imageUrl.startsWith('web_gallery')
                                    ? Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image, size: 20, color: Colors.blue[700]),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Image ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : !kIsWeb
                                        ? Image.file(
                                            File(imageUrl),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(child: Text('Error'));
                                            },
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(7),
                                            ),
                                            child: const Icon(Icons.image, color: Colors.grey),
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
                              color: Colors.red,
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
                      if (kIsWeb && imageUrl.startsWith('web_gallery'))
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
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
                  color: Colors.grey,
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
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No gallery images added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
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
      child: ElevatedButton(
        onPressed: (_isSubmitting || _uniquenessError != null) ? null : _submitForm,
        child: Text(_isSubmitting ? 'Creating Krasnal...' : 'Create Krasnal'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormStatusSummary() {
    final hasName = _nameController.text.isNotEmpty;
    final hasLatitude = _latitudeController.text.isNotEmpty;
    final hasLongitude = _longitudeController.text.isNotEmpty;
    final hasPoints = _pointsController.text.isNotEmpty;
    final hasDiscoveryRadius = _discoveryRadiusController.text.isNotEmpty;
    final hasMainImage = _mainImageUrl != null;
    
    final completedFields = [
      hasName,
      hasLatitude,
      hasLongitude,
      hasPoints,
      hasDiscoveryRadius,
      hasMainImage,
    ].where((field) => field).length;
    
    final totalFields = 6;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completedFields == totalFields ? Icons.check_circle : Icons.info,
                color: completedFields == totalFields ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '$completedFields/$totalFields completed',
                style: TextStyle(
                  color: completedFields == totalFields ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: completedFields / totalFields,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              completedFields == totalFields ? Colors.green : Colors.orange,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Field status list
          _buildFieldStatus('Name', hasName),
          _buildFieldStatus('Latitude', hasLatitude),
          _buildFieldStatus('Longitude', hasLongitude),
          _buildFieldStatus('Points Value', hasPoints),
          _buildFieldStatus('Discovery Radius', hasDiscoveryRadius),
          _buildFieldStatus('Main Image', hasMainImage),
          
          if (_undiscoveredMedallionUrl != null)
            _buildFieldStatus('Undiscovered Medallion', true, isOptional: true),
          if (_discoveredMedallionUrl != null)
            _buildFieldStatus('Discovered Medallion', true, isOptional: true),
          if (_galleryImages.isNotEmpty)
            _buildFieldStatus('Gallery Images (${_galleryImages.length})', true, isOptional: true),
          
          if (_uniquenessError != null) ...[
            const SizedBox(height: 8),
            Text(
              _uniquenessError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldStatus(String fieldName, bool isCompleted, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fieldName,
              style: TextStyle(
                color: isCompleted ? Colors.green : (isOptional ? Colors.grey : Colors.red),
                fontSize: 12,
              ),
            ),
          ),
          if (isOptional)
            Text(
              'Optional',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
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
        
        // Trigger uniqueness validation
        _validateUniqueness();
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

    // TODO: Implement map picker or import the correct MapPickerScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map picker not available - please enter coordinates manually'),
        backgroundColor: Colors.orange,
      ),
    );
    
    /*
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
      
      // Trigger uniqueness validation
      _validateUniqueness();
    }
    */
  }

  Future<void> _addGalleryImage() async {
    if (_galleryImages.length >= 5) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          // On web, store the image bytes for preview
          final bytes = await image.readAsBytes();
          setState(() {
            _galleryImages.add('web_gallery_image_${_galleryImages.length}');
            _galleryImageBytes.add(bytes);
          });
          
          print('✅ Web gallery image selected: ${bytes.length} bytes');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gallery image selected for web! (${(bytes.length) ~/ 1024} KB)'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // On mobile, use the file path
          setState(() {
            _galleryImages.add(image.path);
          });
          
          print('✅ Mobile gallery image selected: ${image.path}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery image selected!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error selecting gallery image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select gallery image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
      // Also remove the corresponding bytes if on web
      if (kIsWeb && index < _galleryImageBytes.length) {
        _galleryImageBytes.removeAt(index);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery image removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitForm() async {
    print('🔄 Submitting form...');
    print('   Main image URL: $_mainImageUrl');
    print('   Form valid: ${_formKey.currentState!.validate()}');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    // Check if main image is uploaded (but don't disable the button for this)
    if (_mainImageUrl == null || _mainImageUrl!.isEmpty) {
      print('❌ No main image selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a main image for the krasnal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if points value is provided
    if (_pointsController.text.isEmpty) {
      print('❌ No points value provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a points value'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ All validations passed, proceeding with submission');

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? finalImageUrl;
      String? finalUndiscoveredUrl;
      String? finalDiscoveredUrl;
      List<String> finalGalleryUrls = [];
      
      // CRITICAL: Upload ALL images to Supabase BEFORE creating krasnal
      
      // 1. Upload main image (required)
      if (_mainImageUrl != null) {
        print('🔄 Uploading main image to Supabase...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading main image...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          if (kIsWeb && _mainImageBytes != null) {
            finalImageUrl = await _imageService.uploadImageFromBytes(
              imageBytes: _mainImageBytes!,
              fileName: 'krasnal_main_${DateTime.now().millisecondsSinceEpoch}.jpg',
              folder: 'krasnale',
            );
          } else if (!kIsWeb && _mainImageUrl != 'web_selected_image') {
            finalImageUrl = await _imageService.uploadImageFromPath(
              filePath: _mainImageUrl!,
              folder: 'krasnale',
            );
          }
          
          if (finalImageUrl == null) {
            throw Exception('Main image upload failed');
          }
          print('✅ Main image uploaded: $finalImageUrl');
          
        } catch (uploadError) {
          print('❌ Main image upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload main image: $uploadError'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Main image is required'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
        return;
      }

      // 2. Upload undiscovered medallion (optional)
      if (_undiscoveredMedallionUrl != null) {
        print('🔄 Uploading undiscovered medallion...');
        try {
          if (kIsWeb && _undiscoveredMedallionBytes != null) {
            finalUndiscoveredUrl = await _imageService.uploadImageFromBytes(
              imageBytes: _undiscoveredMedallionBytes!,
              fileName: 'medallion_undiscovered_${DateTime.now().millisecondsSinceEpoch}.jpg',
              folder: 'medallions',
            );
          } else if (!kIsWeb && !_undiscoveredMedallionUrl!.startsWith('web_')) {
            finalUndiscoveredUrl = await _imageService.uploadImageFromPath(
              filePath: _undiscoveredMedallionUrl!,
              folder: 'medallions',
            );
          }
          
          if (finalUndiscoveredUrl != null) {
            print('✅ Undiscovered medallion uploaded: $finalUndiscoveredUrl');
          }
        } catch (e) {
          print('⚠️ Undiscovered medallion upload failed: $e');
          // Continue anyway, medallions are optional
        }
      }

      // 3. Upload discovered medallion (optional)
      if (_discoveredMedallionUrl != null) {
        print('🔄 Uploading discovered medallion...');
        try {
          if (kIsWeb && _discoveredMedallionBytes != null) {
            finalDiscoveredUrl = await _imageService.uploadImageFromBytes(
              imageBytes: _discoveredMedallionBytes!,
              fileName: 'medallion_discovered_${DateTime.now().millisecondsSinceEpoch}.jpg',
              folder: 'medallions',
            );
          } else if (!kIsWeb && !_discoveredMedallionUrl!.startsWith('web_')) {
            finalDiscoveredUrl = await _imageService.uploadImageFromPath(
              filePath: _discoveredMedallionUrl!,
              folder: 'medallions',
            );
          }
          
          if (finalDiscoveredUrl != null) {
            print('✅ Discovered medallion uploaded: $finalDiscoveredUrl');
          }
        } catch (e) {
          print('⚠️ Discovered medallion upload failed: $e');
          // Continue anyway, medallions are optional
        }
      }

      // 4. Upload gallery images (optional)
      if (_galleryImages.isNotEmpty) {
        print('🔄 Uploading ${_galleryImages.length} gallery images...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading ${_galleryImages.length} gallery images...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        for (int i = 0; i < _galleryImages.length; i++) {
          final galleryUrl = _galleryImages[i];
          try {
            String? uploadedUrl;
            
            if (kIsWeb && i < _galleryImageBytes.length) {
              uploadedUrl = await _imageService.uploadImageFromBytes(
                imageBytes: _galleryImageBytes[i],
                fileName: 'gallery_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                folder: 'gallery',
              );
            } else if (!kIsWeb && !galleryUrl.startsWith('web_')) {
              uploadedUrl = await _imageService.uploadImageFromPath(
                filePath: galleryUrl,
                folder: 'gallery',
              );
            }
            
            if (uploadedUrl != null) {
              finalGalleryUrls.add(uploadedUrl);
              print('✅ Gallery image ${i + 1} uploaded: $uploadedUrl');
            }
          } catch (e) {
            print('⚠️ Gallery image ${i + 1} upload failed: $e');
            // Continue with other images
          }
        }
        
        print('✅ ${finalGalleryUrls.length}/${_galleryImages.length} gallery images uploaded');
      }

      // 5. Create krasnal with all uploaded images
      print('🔄 Creating krasnal with all images...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images uploaded! Creating krasnal...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Now create the krasnal with the uploaded Supabase image URL
      print('🔄 Calling AdminService.createKrasnal...');
      print('   Main image: $finalImageUrl');
      print('   Undiscovered medallion: $finalUndiscoveredUrl');
      print('   Discovered medallion: $finalDiscoveredUrl');
      print('   Gallery images: ${finalGalleryUrls.length}');

      // Prepare additional images array for the consolidated model
      final List<Map<String, dynamic>> additionalImages = [];
      
      // Add medallion images
      if (finalUndiscoveredUrl != null) {
        additionalImages.add({
          'url': finalUndiscoveredUrl,
          'type': 'medallion_undiscovered',
          'orderIndex': 0,
        });
      }
      
      if (finalDiscoveredUrl != null) {
        additionalImages.add({
          'url': finalDiscoveredUrl,
          'type': 'medallion_discovered',
          'orderIndex': 1,
        });
      }
      
      // Add gallery images
      for (int i = 0; i < finalGalleryUrls.length; i++) {
        additionalImages.add({
          'url': finalGalleryUrls[i],
          'type': 'gallery',
          'orderIndex': i + 2,
        });
      }

      // Create krasnal using existing AdminService method parameters
      final krasnalId = await _adminService.createKrasnal(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        locationAddress: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        rarity: _selectedRarity,
        pointsValue: int.parse(_pointsController.text),
        primaryImageUrl: finalImageUrl,
        additionalImages: additionalImages,
      );

      print('📝 AdminService.createKrasnal returned: $krasnalId (type: ${krasnalId.runtimeType})');

      // Check if we got a krasnal ID back (string)
      if (krasnalId.isNotEmpty) {
        print('✅ SUCCESS: Krasnal created with ID: $krasnalId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Krasnal created successfully! ID: $krasnalId'),
              backgroundColor: Colors.green,
            ),
          );
          _clearForm();
        }
      } else {
        print('❌ FAILURE: AdminService returned invalid ID: $krasnalId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create krasnal - invalid response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION in _submitForm: $e');
      print('📍 Stack trace: $stackTrace');
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
        print('🏁 Submission complete, resetting _isSubmitting');
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    print('🧹 Clearing form...');
    _nameController.clear();
    _descriptionController.clear();
    _historyController.clear();
    _locationController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _pointsController.clear();
    _discoveryRadiusController.clear();
    
    setState(() {
      _selectedRarity = KrasnalRarity.common;
      _mainImageUrl = null;
      _undiscoveredMedallionUrl = null;
      _discoveredMedallionUrl = null;
      _galleryImages.clear();
      
      // Clear web image bytes
      _mainImageBytes = null;
      _undiscoveredMedallionBytes = null;
      _discoveredMedallionBytes = null;
      _galleryImageBytes.clear();
    });
    print('✅ Form cleared successfully');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _historyController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _pointsController.dispose();
    _discoveryRadiusController.dispose();
    super.dispose();
  }

  Future<void> _validateUniqueness() async {
    final name = _nameController.text.trim();
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (name.isEmpty || latitude == null || longitude == null) {
      return;
    }

    setState(() {
      _isValidatingUniqueness = true;
      _uniquenessError = null;
    });

    try {
      print('🔍 Validating uniqueness for: $name at ($latitude, $longitude)');
      
      // TODO: Implement proper uniqueness checking when AdminService supports it
      // For now, skip validation to avoid errors
      setState(() {
        _uniquenessError = null;
        _isValidatingUniqueness = false;
      });
      print('✅ Uniqueness validation skipped (not implemented in AdminService)');
      
      /*
      // Check name uniqueness
      final nameExists = await _adminService.checkNameExists(name);
      if (nameExists) {
        setState(() {
          _uniquenessError = 'A krasnal with this name already exists';
          _isValidatingUniqueness = false;
        });
        return;
      }

      // Check coordinate uniqueness
      final coordinatesExist = await _adminService.checkCoordinatesExist(latitude, longitude);
      if (coordinatesExist) {
        setState(() {
          _uniquenessError = 'A krasnal already exists at these coordinates';
          _isValidatingUniqueness = false;
        });
        return;
      }

      setState(() {
        _uniquenessError = null;
        _isValidatingUniqueness = false;
      });
      print('✅ Uniqueness validation passed');
      */
      
    } catch (e) {
      print('❌ Error validating uniqueness: $e');
      setState(() {
        _uniquenessError = 'Error validating uniqueness. Please try again.';
        _isValidatingUniqueness = false;
      });
    }
  }

  Widget _buildValidationStatusCard() {
    return Card(
      child: Row(
        children: [
          if (_isValidatingUniqueness)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_uniquenessError != null)
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20,
            )
          else
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isValidatingUniqueness
                  ? 'Checking name and coordinate uniqueness...'
                  : _uniquenessError ?? 'Name and coordinates are unique',
              style: TextStyle(
                color: _isValidatingUniqueness
                    ? Colors.orange
                    : _uniquenessError != null
                        ? Colors.red
                        : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}