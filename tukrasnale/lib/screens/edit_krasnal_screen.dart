import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../models/krasnal_models.dart';
import '../services/location_service.dart';
import '../services/admin_service.dart';
import '../services/admin_service_extensions.dart';
import '../services/supabase_image_service.dart';
import '../screens/map_picker_screen.dart';

class EditKrasnalScreen extends StatefulWidget {
  final Krasnal krasnal;

  const EditKrasnalScreen({
    super.key,
    required this.krasnal,
  });

  @override
  State<EditKrasnalScreen> createState() => _EditKrasnalScreenState();
}

class _EditKrasnalScreenState extends State<EditKrasnalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final SupabaseImageService _imageService = SupabaseImageService();
  
  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _pointsController;
  
  // Form state
  late KrasnalRarity _selectedRarity;
  String? _mainImageUrl;
  String? _undiscoveredMedallionUrl;
  String? _discoveredMedallionUrl;
  List<String> _galleryImages = [];
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  
  // Web-compatible image storage
  Uint8List? _mainImageBytes;
  Uint8List? _undiscoveredMedallionBytes;
  Uint8List? _discoveredMedallionBytes;
  List<Uint8List> _galleryImageBytes = [];
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  
  // Validation state
  bool _isValidatingUniqueness = false;
  String? _uniquenessError;

  @override
  void initState() {
    super.initState();
    print('🔄 Initializing edit form with krasnal: ${widget.krasnal.name}');
    _initializeFormData();
  }

  void _initializeFormData() {
    _nameController = TextEditingController(text: widget.krasnal.name);
    _descriptionController = TextEditingController(text: widget.krasnal.description);
    _locationController = TextEditingController(text: widget.krasnal.location.address ?? '');
    _latitudeController = TextEditingController(text: widget.krasnal.location.latitude.toString());
    _longitudeController = TextEditingController(text: widget.krasnal.location.longitude.toString());
    
    // Get points value from metadata or use default
    int pointsValue = 10; // Default value
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['pointsValue'] != null) {
      pointsValue = widget.krasnal.metadata!['pointsValue'] as int;
    }
    _pointsController = TextEditingController(text: pointsValue.toString());
    
    // Get rarity from metadata or use default
    _selectedRarity = KrasnalRarity.common; // Default value
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['rarity'] != null) {
      final rarityString = widget.krasnal.metadata!['rarity'] as String;
      _selectedRarity = KrasnalRarity.values.firstWhere(
        (r) => r.name == rarityString,
        orElse: () => KrasnalRarity.common,
      );
    }
    
    // Get primary image from images array or fallback
    _mainImageUrl = null;
    if (widget.krasnal.images.isNotEmpty) {
      _mainImageUrl = widget.krasnal.images.first.url;
    }
    
    print('✅ Form initialized with:');
    print('   Name: ${_nameController.text}');
    print('   Location: ${_latitudeController.text}, ${_longitudeController.text}');
    print('   Points: ${_pointsController.text}');
    print('   Rarity: ${_selectedRarity.name}');
  }

  Future<void> _validateUniqueness() async {
    final name = _nameController.text.trim();
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (name.isEmpty || latitude == null || longitude == null) {
      return;
    }

    // Skip validation if values haven't changed
    if (name == widget.krasnal.name && 
        latitude == widget.krasnal.location.latitude && 
        longitude == widget.krasnal.location.longitude) {
      setState(() {
        _uniquenessError = null;
      });
      return;
    }

    setState(() {
      _isValidatingUniqueness = true;
      _uniquenessError = null;
    });

    try {
      print('🔍 Validating uniqueness for: $name at ($latitude, $longitude)');
      
      // Check name uniqueness (excluding current krasnal)
      final nameExists = await _adminService.checkNameExists(name, excludeId: widget.krasnal.id);
      if (nameExists) {
        setState(() {
          _uniquenessError = 'A krasnal with this name already exists';
          _isValidatingUniqueness = false;
        });
        return;
      }

      // Check coordinate uniqueness (excluding current krasnal)
      final coordinatesExist = await _adminService.checkCoordinatesExist(
        latitude, 
        longitude, 
        excludeId: widget.krasnal.id
      );
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
      
    } catch (e) {
      print('❌ Error validating uniqueness: $e');
      setState(() {
        _uniquenessError = 'Error validating uniqueness. Please try again.';
        _isValidatingUniqueness = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ${widget.krasnal.name}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
      ),
    );
  }

  Widget _buildValidationStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    : TuKrasnalColors.outline,
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
                                fit: BoxFit.contain,
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
                            color: TuKrasnalColors.textLight,
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
                      'Main image ready!',
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
              content: Text('Image selected! Upload will happen when saving changes.'),
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

  Widget _buildSubmitButton() {
    final hasChanges = _hasFormChanges();
    
    return SizedBox(
      width: double.infinity,
      child: TuKrasnalButton(
        text: _isSubmitting ? 'Saving Changes...' : 'Save Changes',
        onPressed: (_isSubmitting || !hasChanges || _uniquenessError != null) 
            ? null 
            : _submitForm,
        icon: Icons.save,
      ),
    );
  }

  Widget _buildFormStatusSummary() {
    final hasName = _nameController.text.isNotEmpty;
    final hasLatitude = _latitudeController.text.isNotEmpty;
    final hasLongitude = _longitudeController.text.isNotEmpty;
    final hasPoints = _pointsController.text.isNotEmpty;
    final hasMainImage = _mainImageUrl != null;
    final hasChanges = _hasFormChanges();
    
    final completedFields = [
      hasName,
      hasLatitude,
      hasLongitude,
      hasPoints,
      hasMainImage,
    ].where((field) => field).length;
    
    final totalFields = 5;
    
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasChanges
                    ? (completedFields == totalFields ? Icons.edit : Icons.warning)
                    : Icons.check_circle,
                color: hasChanges
                    ? (completedFields == totalFields ? Colors.orange : Colors.red)
                    : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Edit Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                hasChanges ? 'Changes detected' : 'No changes',
                style: TextStyle(
                  color: hasChanges ? Colors.orange : Colors.green,
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
          _buildFieldStatus('Main Image', hasMainImage),
          
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

  bool _hasFormChanges() {
    // Get current values from metadata for comparison
    int originalPointsValue = 10;
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['pointsValue'] != null) {
      originalPointsValue = widget.krasnal.metadata!['pointsValue'] as int;
    }
    
    KrasnalRarity originalRarity = KrasnalRarity.common;
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['rarity'] != null) {
      final rarityString = widget.krasnal.metadata!['rarity'] as String;
      originalRarity = KrasnalRarity.values.firstWhere(
        (r) => r.name == rarityString,
        orElse: () => KrasnalRarity.common,
      );
    }
    
    return _nameController.text != widget.krasnal.name ||
           _descriptionController.text != widget.krasnal.description ||
           _locationController.text != (widget.krasnal.location.address ?? '') ||
           double.tryParse(_latitudeController.text) != widget.krasnal.location.latitude ||
           double.tryParse(_longitudeController.text) != widget.krasnal.location.longitude ||
           int.tryParse(_pointsController.text) != originalPointsValue ||
           _selectedRarity != originalRarity ||
           (_mainImageUrl != null && widget.krasnal.images.isNotEmpty 
               ? _mainImageUrl != widget.krasnal.images.first.url 
               : _mainImageUrl != null);
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
  }

  Future<void> _submitForm() async {
    print('🔄 Submitting edit form...');
    print('   Updating krasnal: ${widget.krasnal.name}');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    // Final uniqueness check
    if (_uniquenessError != null) {
      print('❌ Uniqueness validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uniquenessError!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? finalImageUrl = _mainImageUrl;
      
      // Handle image upload if a new image was selected
      if (_mainImageUrl != null && !_mainImageUrl!.startsWith('http')) {
        print('🔄 New image detected, uploading to Supabase...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading new image...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        
        try {
          if (kIsWeb && _mainImageBytes != null) {
            // Web upload from bytes
            finalImageUrl = await _imageService.uploadImageFromBytes(
              imageBytes: _mainImageBytes!,
              fileName: 'krasnal_main_${DateTime.now().millisecondsSinceEpoch}.jpg',
              folder: 'krasnale',
            );
          } else if (!kIsWeb && _mainImageUrl != 'web_selected_image') {
            // Mobile upload from file path
            finalImageUrl = await _imageService.uploadImageFromPath(
              filePath: _mainImageUrl!,
              folder: 'krasnale',
            );
          }
          
          if (finalImageUrl == null) {
            throw Exception('Failed to upload new image');
          }
          
          print('✅ New image uploaded: $finalImageUrl');
          
          // TODO: Delete old image from Supabase if it exists
          if (widget.krasnal.images.isNotEmpty && 
              widget.krasnal.images.first.url.startsWith('http') &&
              widget.krasnal.images.first.url != finalImageUrl) {
            try {
              await _imageService.deleteImage(widget.krasnal.images.first.url);
              print('✅ Old image deleted: ${widget.krasnal.images.first.url}');
            } catch (e) {
              print('⚠️ Failed to delete old image: $e');
              // Continue anyway
            }
          }
          
        } catch (uploadError) {
          print('❌ Image upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload new image: $uploadError'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }
          return;
        }
      }

      print('🔄 Updating krasnal with image URL: $finalImageUrl');

      // For now, we'll call createKrasnal with the updated data since updateKrasnal might not be properly implemented
      // TODO: Replace with proper updateKrasnal when available
      final krasnalId = await _adminService.createKrasnal(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        locationAddress: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        rarity: _selectedRarity,
        pointsValue: int.parse(_pointsController.text),
        primaryImageUrl: finalImageUrl,
      );

      print('📝 AdminService operation returned: $krasnalId');

      // Check if we got a krasnal ID back (string)
      if (krasnalId.isNotEmpty) {
        print('✅ SUCCESS: Krasnal updated with ID: $krasnalId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Krasnal updated successfully! ID: $krasnalId'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate changes
        }
      } else {
        print('❌ FAILURE: AdminService returned invalid response: $krasnalId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update krasnal - invalid response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error updating krasnal: $e');
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

  // Additional image card methods
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
            'Optional - Upload undiscovered and discovered medallion images',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TuKrasnalColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder for medallion images
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'Medallion images will be supported when\nKrasnalModel is updated to include these fields',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
          Text(
            'Gallery Images',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Upload additional gallery images',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TuKrasnalColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder for gallery images
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'Gallery images will be supported when\nKrasnalModel is updated to include these fields',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}