import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
import '../models/krasnal_models.dart';
import '../services/location_service.dart' as location_service;
import '../services/supabase_service.dart';

// Discovery result class for discovery attempts
class DiscoveryResult {
  final bool canDiscover;
  final double distance;
  final Krasnal krasnal;
  final String? reason;

  const DiscoveryResult({
    required this.canDiscover,
    required this.distance,
    required this.krasnal,
    this.reason,
  });
}

class DiscoveryProvider extends ChangeNotifier {
  List<Krasnal> _allKrasnale = [];
  List<Krasnal> _nearbyKrasnale = [];
  List<Krasnal> _discoverableKrasnale = [];
  List<Map<String, dynamic>> _userDiscoveries = [];
  location_service.Position? _userPosition;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Krasnal> get allKrasnale => _allKrasnale;
  List<Krasnal> get nearbyKrasnale => _nearbyKrasnale;
  List<Krasnal> get discoverableKrasnale => _discoverableKrasnale;
  List<Map<String, dynamic>> get userDiscoveries => _userDiscoveries;
  location_service.Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get hasLocationPermission => location_service.LocationService.instance.hasLocationAccess;

  // Load all krasnale data
  Future<void> loadAllKrasnale() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allKrasnale = await SupabaseService.instance.getAllKrasnale();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load krasnale: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user position and refresh nearby krasnale
  Future<void> updateUserPosition() async {
    try {
      final position = await location_service.LocationService.instance.getCurrentPosition();
      _userPosition = position;
      await _updateNearbyKrasnale();
      await _updateDiscoverableKrasnale();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get location: ${e.toString()}';
      notifyListeners();
    }
  }

  // Update nearby krasnale based on current position
  Future<void> _updateNearbyKrasnale() async {
    if (_userPosition == null) return;

    try {
      _nearbyKrasnale = await SupabaseService.instance.getNearbyKrasnale(
        latitude: _userPosition!.latitude,
        longitude: _userPosition!.longitude,
        radiusKm: 2.0, // 2km radius
      );
    } catch (e) {
      if (kDebugMode) print('Error updating nearby krasnale: $e');
    }
  }

  // Update discoverable krasnale (within discovery radius)
  Future<void> _updateDiscoverableKrasnale() async {
    if (_userPosition == null) return;

    try {
      _discoverableKrasnale = await SupabaseService.instance.getDiscoverableKrasnale(
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
      );
    } catch (e) {
      if (kDebugMode) print('Error updating discoverable krasnale: $e');
    }
  }

  // Load user's discoveries
  Future<void> loadUserDiscoveries() async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return;

    try {
      _userDiscoveries = await SupabaseService.instance.getUserDiscoveries(currentUser.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load discoveries: ${e.toString()}';
      notifyListeners();
    }
  }

  // Attempt to discover a krasnal
  Future<DiscoveryResult> attemptDiscovery(Krasnal krasnal) async {
    if (_userPosition == null) {
      return DiscoveryResult(
        canDiscover: false,
        distance: double.infinity,
        krasnal: krasnal,
        reason: 'Location not available',
      );
    }

    // Calculate distance to krasnal
    double distance = location_service.LocationService.instance.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      krasnal.location.latitude,
      krasnal.location.longitude,
    );

    // Check if within discovery radius (default 50m if not specified)
    double discoveryRadius = 50.0; // Default discovery radius
    if (krasnal.metadata != null && krasnal.metadata!['discoveryRadius'] != null) {
      discoveryRadius = (krasnal.metadata!['discoveryRadius'] as num).toDouble();
    }
    
    bool withinRadius = distance <= discoveryRadius;
    
    if (!withinRadius) {
      return DiscoveryResult(
        canDiscover: false,
        distance: distance,
        krasnal: krasnal,
        reason: 'Too far away (${distance.toStringAsFixed(0)}m). Get within ${discoveryRadius.toInt()}m.',
      );
    }

    // Check if already discovered
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser != null) {
      bool alreadyDiscovered = await SupabaseService.instance.hasDiscovered(krasnal.id);
      if (alreadyDiscovered) {
        return DiscoveryResult(
          canDiscover: false,
          distance: distance,
          krasnal: krasnal,
          reason: 'Already discovered',
        );
      }
    }

    return DiscoveryResult(
      canDiscover: true,
      distance: distance,
      krasnal: krasnal,
    );
  }

  // Discover a krasnal
  Future<bool> discoverKrasnal(Krasnal krasnal) async {
    if (_userPosition == null) {
      _errorMessage = 'Location not available';
      notifyListeners();
      return false;
    }

    try {
      final discovery = await SupabaseService.instance.discoverKrasnal(
        krasnalId: krasnal.id,
        userLat: _userPosition!.latitude,
        userLng: _userPosition!.longitude,
      );

      if (discovery != null) {
        _userDiscoveries.insert(0, discovery);
        await _updateDiscoverableKrasnale(); // Refresh discoverable list
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }

    return false;
  }

  // Scan for nearby discoverable krasnale
  Future<List<Krasnal>> scanForDiscoverableKrasnale() async {
    await updateUserPosition();
    return _discoverableKrasnale;
  }

  // Check if krasnal is discovered by current user
  bool isDiscovered(String krasnalId) {
    return _userDiscoveries.any((discovery) => discovery['krasnal_id'] == krasnalId);
  }

  // Get discovery for specific krasnal
  Map<String, dynamic>? getDiscovery(String krasnalId) {
    try {
      return _userDiscoveries.firstWhere((discovery) => discovery['krasnal_id'] == krasnalId);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _allKrasnale.clear();
    _nearbyKrasnale.clear();
    _discoverableKrasnale.clear();
    _userDiscoveries.clear();
    _userPosition = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}