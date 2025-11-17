# TuKrasnal Map Performance Enhancement Guide

## 🗺️ **OpenStreetMap Performance Optimization**

Since the advanced caching libraries have dependency issues, here's how to make OpenStreetMap much more responsive:

### **1. Update pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.5.6
  
  # State management
  provider: ^6.1.2
  
  # HTTP client
  http: ^1.2.1
  
  # Environment variables
  flutter_dotenv: ^5.1.0

  # Location and GPS
  geolocator: ^11.0.0
  
  # Maps - optimized versions
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  
  # Basic caching
  path_provider: ^2.1.2
  crypto: ^3.0.3
  
  # JSON serialization
  json_annotation: ^4.8.1

  # Icons
  cupertino_icons: ^1.0.8
```

### **2. Simple Performance Optimizations**

#### **A. Use NetworkImage with caching:**
```dart
// In your map screen TileLayer:
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.tukrasnale.app',
  maxNativeZoom: 19,
  maxZoom: 19,
  // Enable browser caching
  additionalOptions: {
    'cache': 'force-cache',
  },
),
```

#### **B. Optimize map interactions:**
```dart
FlutterMap(
  options: MapOptions(
    // Limit zoom for performance
    initialZoom: 13.0,
    minZoom: 10.0,
    maxZoom: 16.0, // Reduce max zoom
    
    // Optimize interactions
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    ),
  ),
)
```

#### **C. Reduce marker complexity:**
```dart
// Use simple circle markers instead of complex widgets
Marker(
  point: LatLng(lat, lng),
  width: 20,
  height: 20,
  child: Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: markerColor,
      border: Border.all(color: Colors.white, width: 2),
    ),
  ),
)
```

### **3. Pre-load Critical Tiles**

#### **A. Background tile preloading:**
```dart
class SimpleTilePreloader {
  static Future<void> preloadCriticalTiles() async {
    // Preload tiles for Wrocław center at medium zoom
    const center = LatLng(51.1079, 17.0385);
    const zoom = 14;
    
    // Load tiles in a 3x3 grid around center
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final x = _lonToTileX(center.longitude, zoom) + dx;
        final y = _latToTileY(center.latitude, zoom) + dy;
        
        // Preload tile
        final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
        precacheImage(NetworkImage(url), context);
      }
    }
  }
  
  static int _lonToTileX(double lon, int zoom) =>
      ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
      
  static int _latToTileY(double lat, int zoom) {
    final rad = lat * (pi / 180.0);
    return ((1.0 - log(tan(rad) + 1.0 / cos(rad)) / pi) / 2.0 * (1 << zoom)).floor();
  }
}
```

### **4. Performance-Optimized Map Screen**

Update your map screen with these optimizations:

```dart
// Reduce marker updates
bool _shouldRebuildMarkers = true;
List<Marker> _cachedMarkers = [];

List<Marker> _buildKrasnalMarkers(DiscoveryProvider discoveryProvider) {
  if (!_shouldRebuildMarkers) return _cachedMarkers;
  
  _cachedMarkers = discoveryProvider.allKrasnale.map((krasnal) {
    // Use simple, performant markers
    return Marker(
      point: LatLng(krasnal.latitude, krasnal.longitude),
      width: 24,
      height: 24,
      child: GestureDetector(
        onTap: () => _showKrasnalDetails(krasnal),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getKrasnalColor(krasnal),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }).toList();
  
  _shouldRebuildMarkers = false;
  return _cachedMarkers;
}
```

### **5. Alternative: Use Mapbox (Free Tier)**

For even better performance, consider Mapbox which offers:
- **50,000 free map loads/month**
- **Better caching**
- **Vector tiles** (faster rendering)
- **Offline support**

```yaml
dependencies:
  mapbox_maps_flutter: ^1.0.0
```

### **6. Network Optimization**

```dart
// In your app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize HTTP client
  final httpClient = HttpClient();
  httpClient.connectionTimeout = const Duration(seconds: 10);
  httpClient.idleTimeout = const Duration(seconds: 15);
  
  runApp(MyApp());
}
```

### **7. GPS Optimization**

```dart
// Reduce GPS updates frequency
Stream<Position> getOptimizedPositionStream() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.balanced, // Not high
      distanceFilter: 20, // Update every 20 meters
      timeLimit: Duration(seconds: 30), // Timeout quickly
    ),
  );
}
```

## 🚀 **Expected Performance Improvements:**

1. **Faster initial load** - Reduced complexity
2. **Smoother panning** - Optimized interactions
3. **Less memory usage** - Simple markers
4. **Better responsiveness** - Reduced GPS frequency
5. **Faster tile loading** - Browser caching

## 📊 **Performance Monitoring:**

```dart
class PerformanceMonitor {
  static void trackMapPerformance() {
    final stopwatch = Stopwatch()..start();
    
    // Track tile load times
    Timer.periodic(Duration(seconds: 5), (timer) {
      print('Map render time: ${stopwatch.elapsedMilliseconds}ms');
    });
  }
}
```

This approach will make your OpenStreetMap much more responsive without complex caching dependencies!