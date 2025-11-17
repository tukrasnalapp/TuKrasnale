import 'dart:math';
import 'package:flutter/material.dart';

class MapOptimizer {
  static MapOptimizer? _instance;
  static MapOptimizer get instance => _instance ??= MapOptimizer._();
  
  MapOptimizer._();
  
  // Preload critical tiles for Wrocław
  static Future<void> preloadWroclawTiles(BuildContext context) async {
    // Wrocław center coordinates
    const double centerLat = 51.1079;
    const double centerLng = 17.0385;
    const int zoom = 13;
    
    // Calculate tile coordinates for 3x3 grid around center
    final centerX = _lonToTileX(centerLng, zoom);
    final centerY = _latToTileY(centerLat, zoom);
    
    // Preload tiles in background
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;
        
        final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
        
        try {
          // Use Flutter's image cache
          await precacheImage(NetworkImage(url), context);
        } catch (e) {
          // Ignore preload failures
          debugPrint('Failed to preload tile: $url');
        }
      }
    }
    
    debugPrint('Preloaded Wrocław map tiles');
  }
  
  // Convert longitude to tile X coordinate
  static int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }
  
  // Convert latitude to tile Y coordinate  
  static int _latToTileY(double lat, int zoom) {
    final rad = lat * (pi / 180.0);
    return ((1.0 - log(tan(rad) + 1.0 / cos(rad)) / pi) / 2.0 * (1 << zoom)).floor();
  }
  
  // Get optimal zoom level based on distance
  static double getOptimalZoom(double distanceKm) {
    if (distanceKm < 1) return 16.0;
    if (distanceKm < 2) return 15.0;
    if (distanceKm < 5) return 14.0;
    if (distanceKm < 10) return 13.0;
    return 12.0;
  }
  
  // Get performant marker color based on krasnal properties
  static Color getPerformantMarkerColor(String rarity, bool isDiscovered, bool isNearby) {
    if (isDiscovered) return Colors.green;
    if (isNearby) return Colors.orange;
    
    switch (rarity) {
      case 'common': return Colors.blue;
      case 'rare': return Colors.purple;
      case 'epic': return Colors.deepPurple;
      case 'legendary': return Colors.amber;
      default: return Colors.grey;
    }
  }
  
  // Create optimized marker widget
  static Widget createOptimizedMarker({
    required Color color,
    required VoidCallback onTap,
    bool isDiscovered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          isDiscovered ? Icons.check : Icons.location_on,
          color: Colors.white,
          size: 10,
        ),
      ),
    );
  }
}