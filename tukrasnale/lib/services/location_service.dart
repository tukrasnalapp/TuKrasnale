import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get current device location
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Location permission denied. Please grant location permission to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return LocationResult.error('Failed to get current location: ${e.toString()}');
    }
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Open app settings for location permissions
  Future<bool> openLocationSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Validate latitude value
  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= -90.0 && lat <= 90.0;
  }

  /// Validate longitude value
  static bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng >= -180.0 && lng <= 180.0;
  }

  /// Format coordinate with max 8 decimal places
  static String formatCoordinate(double coordinate) {
    return coordinate.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  /// Parse and validate coordinate string
  static double? parseCoordinate(String value, bool isLatitude) {
    if (value.isEmpty) return null;
    
    try {
      final parsed = double.parse(value);
      
      // Check decimal places (max 8)
      final parts = value.split('.');
      if (parts.length > 1 && parts[1].length > 8) {
        return null; // Too many decimal places
      }
      
      // Validate range
      if (isLatitude) {
        return isValidLatitude(parsed) ? parsed : null;
      } else {
        return isValidLongitude(parsed) ? parsed : null;
      }
    } catch (e) {
      return null;
    }
  }
}

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  final bool success;

  LocationResult._({
    this.latitude,
    this.longitude,
    this.error,
    required this.success,
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
  }) {
    return LocationResult._(
      latitude: latitude,
      longitude: longitude,
      success: true,
    );
  }

  factory LocationResult.error(String error) {
    return LocationResult._(
      error: error,
      success: false,
    );
  }
}