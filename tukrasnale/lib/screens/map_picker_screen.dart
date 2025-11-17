import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  double? _selectedLatitude;
  double? _selectedLongitude;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude ?? 51.1079; // Default to Wrocław
    _selectedLongitude = widget.initialLongitude ?? 17.0385;
    _updateControllers();
  }

  void _updateControllers() {
    if (_selectedLatitude != null) {
      _latController.text = LocationService.formatCoordinate(_selectedLatitude!);
    }
    if (_selectedLongitude != null) {
      _lngController.text = LocationService.formatCoordinate(_selectedLongitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(
        title: 'Pick Location',
        showLogo: true,
        actions: [
          TextButton(
            onPressed: _selectedLatitude != null && _selectedLongitude != null
                ? () => Navigator.pop(context, {
                    'latitude': _selectedLatitude,
                    'longitude': _selectedLongitude,
                  })
                : null,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Container(
        color: TuKrasnaleColors.background,
        child: Column(
          children: [
            // Map placeholder (will be replaced with actual map)
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TuKrasnaleColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TuKrasnaleColors.outline),
                ),
                child: Stack(
                  children: [
                    // Map placeholder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 64,
                            color: TuKrasnaleColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Interactive Map',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: TuKrasnaleColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap on the map to select location',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: TuKrasnaleColors.textLight,
                            ),
                          ),
                          if (_selectedLatitude != null && _selectedLongitude != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: TuKrasnaleColors.brickRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: TuKrasnaleColors.brickRed),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: TuKrasnaleColors.brickRed,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Selected Location',
                                    style: TextStyle(
                                      color: TuKrasnaleColors.brickRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${LocationService.formatCoordinate(_selectedLatitude!)}, ${LocationService.formatCoordinate(_selectedLongitude!)}',
                                    style: TextStyle(
                                      color: TuKrasnaleColors.brickRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Current location button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _getCurrentLocation,
                        backgroundColor: TuKrasnaleColors.skyBlue,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Manual coordinate input
            Container(
              padding: const EdgeInsets.all(16),
              child: TuKrasnaleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Coordinate Input',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              hintText: '51.1079',
                              suffixText: '°',
                            ),
                            onChanged: _onLatitudeChanged,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              hintText: '17.0385',
                              suffixText: '°',
                            ),
                            onChanged: _onLongitudeChanged,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: TuKrasnaleColors.textLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Latitude: -90 to 90, Longitude: -180 to 180 (max 8 decimal places)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TuKrasnaleColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLatitudeChanged(String value) {
    final parsed = LocationService.parseCoordinate(value, true);
    setState(() {
      _selectedLatitude = parsed;
    });
  }

  void _onLongitudeChanged(String value) {
    final parsed = LocationService.parseCoordinate(value, false);
    setState(() {
      _selectedLongitude = parsed;
    });
  }

  Future<void> _getCurrentLocation() async {
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting current location...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final locationResult = await LocationService().getCurrentLocation();
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (locationResult.success) {
        setState(() {
          _selectedLatitude = locationResult.latitude;
          _selectedLongitude = locationResult.longitude;
        });
        _updateControllers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationResult.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => LocationService().openLocationSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }
}