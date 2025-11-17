import 'dart:math' as math;

class LocationUtils {
  /// Calculate distance between two geographic points using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Check if a location is within discovery radius of a krasnal
  static bool isWithinDiscoveryRadius(
    double userLat,
    double userLng,
    double krasnalLat,
    double krasnalLng,
    int discoveryRadius,
  ) {
    final double distance = calculateDistance(
      userLat,
      userLng,
      krasnalLat,
      krasnalLng,
    );
    
    return distance <= discoveryRadius;
  }

  /// Get formatted distance string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Get direction text based on distance
  static String getDirectionText(double distanceInMeters, int discoveryRadius) {
    if (distanceInMeters <= discoveryRadius) {
      return 'You are close enough to discover this krasnal!';
    } else if (distanceInMeters <= discoveryRadius * 2) {
      return 'Getting close! Move a bit closer.';
    } else if (distanceInMeters <= 100) {
      return 'Very close! Look around for the krasnal.';
    } else if (distanceInMeters <= 500) {
      return 'Nearby - keep walking in this direction.';
    } else if (distanceInMeters <= 1000) {
      return 'About ${formatDistance(distanceInMeters)} away.';
    } else {
      return 'Far away - ${formatDistance(distanceInMeters)}.';
    }
  }
}