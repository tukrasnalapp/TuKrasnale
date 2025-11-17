import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/discovery_provider.dart';
import '../services/location_service.dart';
import '../models/krasnal_models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _scanAnimationController;
  bool _isScanning = false;

  // Wrocław city center coordinates
  static const LatLng _wroclawCenter = LatLng(51.1079, 17.0385);

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeMap();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final discoveryProvider = context.read<DiscoveryProvider>();
    
    // Load all krasnale
    await discoveryProvider.loadAllKrasnale();
    
    // Try to get user location and center map
    await _centerOnUserLocation();
  }

  Future<void> _centerOnUserLocation() async {
    final status = await LocationService.instance.checkAndRequestPermissions();
    
    if (status == LocationServiceStatus.granted) {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null && mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0, // Zoom level
        );
        
        // Update discovery provider with position
        final discoveryProvider = context.read<DiscoveryProvider>();
        await discoveryProvider.updateUserPosition();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krasnale Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter krasnale',
          ),
        ],
      ),
      body: Consumer<DiscoveryProvider>(
        builder: (context, discoveryProvider, child) {
          if (discoveryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              // Flutter Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _wroclawCenter,
                  initialZoom: 13.0,
                  minZoom: 10.0,
                  maxZoom: 16.0, // Reduced for better performance
                ),
                children: [
                  // OpenStreetMap tiles - optimized
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tukrasnale.app',
                    maxNativeZoom: 16,
                    maxZoom: 16,
                  ),
                  
                  // Krasnal markers
                  MarkerLayer(
                    markers: _buildKrasnalMarkers(discoveryProvider),
                  ),
                  
                  // User position marker
                  if (discoveryProvider.userPosition != null)
                    MarkerLayer(
                      markers: [
                        _buildUserMarker(discoveryProvider.userPosition!),
                      ],
                    ),
                ],
              ),

              // Discovery scan button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Discoverable krasnale info
                    if (discoveryProvider.discoverableKrasnale.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${discoveryProvider.discoverableKrasnale.length} krasnale nearby!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Scan button
                    AnimatedBuilder(
                      animation: _scanAnimationController,
                      builder: (context, child) {
                        return ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanForKrasnale,
                          icon: RotationTransition(
                            turns: _scanAnimationController,
                            child: const Icon(Icons.search),
                          ),
                          label: Text(
                            _isScanning 
                                ? 'Scanning...' 
                                : 'Scan for Krasnale',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _isScanning 
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Error message
              if (discoveryProvider.errorMessage != null)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Card(
                    color: Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              discoveryProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: discoveryProvider.clearError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildKrasnalMarkers(DiscoveryProvider discoveryProvider) {
    return discoveryProvider.allKrasnale.map((krasnal) {
      bool isDiscovered = discoveryProvider.isDiscovered(krasnal.id);
      bool isNearby = discoveryProvider.discoverableKrasnale
          .any((nearby) => nearby.id == krasnal.id);

      return Marker(
        point: LatLng(krasnal.latitude, krasnal.longitude),
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => _showKrasnalDetails(krasnal, isDiscovered),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getKrasnalMarkerColor(krasnal, isDiscovered, isNearby),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              isDiscovered ? Icons.star : Icons.help_outline,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  Marker _buildUserMarker(Position position) {
    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 15,
        ),
      ),
    );
  }

  Color _getKrasnalMarkerColor(KrasnalModel krasnal, bool isDiscovered, bool isNearby) {
    if (isDiscovered) {
      return Colors.green;
    } else if (isNearby) {
      return Colors.orange;
    } else {
      switch (krasnal.rarity) {
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
  }

  Future<void> _scanForKrasnale() async {
    setState(() {
      _isScanning = true;
    });
    
    _scanAnimationController.repeat();

    try {
      final discoveryProvider = context.read<DiscoveryProvider>();
      final discoverableKrasnale = await discoveryProvider.scanForDiscoverableKrasnale();
      
      await Future.delayed(const Duration(seconds: 2)); // For dramatic effect
      
      if (mounted) {
        if (discoverableKrasnale.isNotEmpty) {
          _showDiscoverableKrasnaleDialog(discoverableKrasnale);
        } else {
          _showNoKrasnaleDialog();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _scanAnimationController.stop();
      }
    }
  }

  void _showDiscoverableKrasnaleDialog(List<KrasnalModel> krasnale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Krasnale Found!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Found ${krasnale.length} krasnale you can discover:'),
              const SizedBox(height: 16),
              ...krasnale.map((krasnal) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getKrasnalMarkerColor(krasnal, false, true),
                  child: const Icon(Icons.star, color: Colors.white),
                ),
                title: Text(krasnal.name),
                subtitle: Text(krasnal.locationName ?? ''),
                trailing: Text('${krasnal.pointsValue} pts'),
                onTap: () {
                  Navigator.pop(context);
                  _showKrasnalDetails(krasnal, false);
                },
              )),
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

  void _showNoKrasnaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey),
            SizedBox(width: 8),
            Text('No Krasnale Nearby'),
          ],
        ),
        content: const Text(
          'No krasnale found within discovery range.\n\n'
          'Try moving closer to a krasnal location or explore the map to find new ones!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showKrasnalDetails(KrasnalModel krasnal, bool isDiscovered) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(krasnal.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (krasnal.description != null) ...[
              Text(krasnal.description!),
              const SizedBox(height: 12),
            ],
            Text('Location: ${krasnal.locationName ?? "Unknown"}'),
            Text('Rarity: ${krasnal.rarity.name.toUpperCase()}'),
            Text('Points: ${krasnal.pointsValue}'),
            if (!isDiscovered) ...[
              const SizedBox(height: 12),
              const Text('Status: Not discovered'),
            ] else ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Discovered!', style: TextStyle(color: Colors.green)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isDiscovered)
            ElevatedButton(
              onPressed: () => _attemptDiscovery(krasnal),
              child: const Text('Try to Discover'),
            ),
        ],
      ),
    );
  }

  Future<void> _attemptDiscovery(KrasnalModel krasnal) async {
    Navigator.pop(context); // Close details dialog
    
    final discoveryProvider = context.read<DiscoveryProvider>();
    final result = await discoveryProvider.attemptDiscovery(krasnal);
    
    if (result.canDiscover) {
      final success = await discoveryProvider.discoverKrasnal(krasnal);
      if (success && mounted) {
        _showSuccessDialog(krasnal);
      }
    } else {
      if (mounted) {
        _showDiscoveryFailedDialog(result);
      }
    }
  }

  void _showSuccessDialog(KrasnalModel krasnal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('Discovery Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You discovered ${krasnal.name}!'),
            const SizedBox(height: 16),
            Text('You earned ${krasnal.pointsValue} points!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showDiscoveryFailedDialog(DiscoveryResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discovery Failed'),
        content: Text(result.reason ?? 'Unable to discover this krasnal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Krasnale',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Show All'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.green),
              title: const Text('Discovered Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: const Text('Undiscovered Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Nearby Only'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}