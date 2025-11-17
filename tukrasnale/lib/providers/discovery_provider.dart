import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/krasnal_models.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  List<KrasnalModel> _allKrasnale = [];
  List<KrasnalModel> _nearbyKrasnale = [];
  List<KrasnalModel> _discoverableKrasnale = [];
  List<UserDiscovery> _userDiscoveries = [];
  Position? _userPosition;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<KrasnalModel> get allKrasnale => _allKrasnale;
  List<KrasnalModel> get nearbyKrasnale => _nearbyKrasnale;
  List<KrasnalModel> get discoverableKrasnale => _discoverableKrasnale;
  List<UserDiscovery> get userDiscoveries => _userDiscoveries;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get hasLocationPermission => LocationService.instance.hasLocationAccess;

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
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        _userPosition = position;
        await _updateNearbyKrasnale();
        await _updateDiscoverableKrasnale();
        notifyListeners();
      }
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
  Future<DiscoveryResult> attemptDiscovery(KrasnalModel krasnal) async {
    if (_userPosition == null) {
      return DiscoveryResult(
        canDiscover: false,
        distance: double.infinity,
        krasnal: krasnal,
        reason: 'Location not available',
      );
    }

    // Calculate distance to krasnal
    double distance = LocationService.instance.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      krasnal.latitude,
      krasnal.longitude,
    );

    // Check if within discovery radius
    bool withinRadius = distance <= krasnal.discoveryRadius;
    
    if (!withinRadius) {
      return DiscoveryResult(
        canDiscover: false,
        distance: distance,
        krasnal: krasnal,
        reason: 'Too far away (${distance.toStringAsFixed(0)}m). Get within ${krasnal.discoveryRadius}m.',
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
  Future<bool> discoverKrasnal(KrasnalModel krasnal) async {
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
  Future<List<KrasnalModel>> scanForDiscoverableKrasnale() async {
    await updateUserPosition();
    return _discoverableKrasnale;
  }

  // Check if krasnal is discovered by current user
  bool isDiscovered(String krasnalId) {
    return _userDiscoveries.any((discovery) => discovery.krasnalId == krasnalId);
  }

  // Get discovery for specific krasnal
  UserDiscovery? getDiscovery(String krasnalId) {
    try {
      return _userDiscoveries.firstWhere((discovery) => discovery.krasnalId == krasnalId);
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