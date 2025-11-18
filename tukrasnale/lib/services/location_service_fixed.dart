import 'dart:math';

enum LocationServiceStatus {
  granted,
  denied,
  deniedForever,
  disabled,
}

class LocationData {
  final double latitude;
  final double longitude;
  final bool success;
  final String? error;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.success = true,
    this.error,
  });

  LocationData.error(String errorMessage)
      : latitude = 0.0,
        longitude = 0.0,
        success = false,
        error = errorMessage;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;
  
  LocationService._internal();

  // Factory constructor for regular instantiation
  factory LocationService() => _instance;

  bool get hasLocationAccess => true; // Mock implementation

  Future<LocationServiceStatus> checkAndRequestPermissions() async {
    // Mock implementation - always return granted
    await Future.delayed(const Duration(milliseconds: 500));
    return LocationServiceStatus.granted;
  }

  Future<LocationData> getCurrentPosition() async {
    try {
      // Mock implementation - return Krakow city center
      await Future.delayed(const Duration(seconds: 1));
      return LocationData(latitude: 50.0647, longitude: 19.9450);
    } catch (e) {
      return LocationData.error('Failed to get current location: $e');
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      // Mock implementation - return Krakow city center
      await Future.delayed(const Duration(seconds: 1));
      return LocationData(latitude: 50.0647, longitude: 19.9450);
    } catch (e) {
      return null;
    }
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final lat1Rad = startLatitude * (pi / 180);
    final lat2Rad = endLatitude * (pi / 180);
    final deltaLatRad = (endLatitude - startLatitude) * (pi / 180);
    final deltaLngRad = (endLongitude - startLongitude) * (pi / 180);

    final a = pow(sin(deltaLatRad / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        pow(sin(deltaLngRad / 2), 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  Future<double> distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return calculateDistance(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  Future<bool> openLocationSettings() async {
    // Mock implementation - always return true
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Static methods for coordinate parsing and formatting
  static double? parseCoordinate(String value, bool isLatitude) {
    try {
      final parsed = double.tryParse(value.trim());
      if (parsed == null) return null;
      
      if (isLatitude && (parsed < -90 || parsed > 90)) return null;
      if (!isLatitude && (parsed < -180 || parsed > 180)) return null;
      
      return parsed;
    } catch (e) {
      return null;
    }
  }

  static String formatCoordinate(double coordinate) {
    return coordinate.toStringAsFixed(8);
  }
}