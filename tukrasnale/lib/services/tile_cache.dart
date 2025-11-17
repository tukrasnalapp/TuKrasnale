import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TileCache {
  static TileCache? _instance;
  static TileCache get instance => _instance ??= TileCache._();
  
  TileCache._();
  
  Directory? _cacheDir;
  bool _isInitialized = false;
  
  // Cache configuration
  static const int maxCacheSizeMB = 100;
  static const int maxAgeHours = 24 * 7; // 7 days
  
  bool get isInitialized => _isInitialized;
  
  /// Initialize the tile cache
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/map_tiles');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      _isInitialized = true;
      
      // Clean old tiles periodically
      _cleanOldTiles();
      
      if (kDebugMode) {
        print('Tile cache initialized at: ${_cacheDir!.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing tile cache: $e');
      }
      rethrow;
    }
  }
  
  /// Generate cache key for a tile
  String _getTileKey(int z, int x, int y) {
    final key = '$z-$x-$y';
    return md5.convert(utf8.encode(key)).toString();
  }
  
  /// Get cached tile file path
  File _getTileFile(String key) {
    return File('${_cacheDir!.path}/$key.png');
  }
  
  /// Check if tile exists in cache and is not expired
  Future<bool> hasTile(int z, int x, int y) async {
    if (!_isInitialized) return false;
    
    try {
      final key = _getTileKey(z, x, y);
      final file = _getTileFile(key);
      
      if (!await file.exists()) return false;
      
      // Check if tile is not too old
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      
      return age.inHours < maxAgeHours;
    } catch (e) {
      return false;
    }
  }
  
  /// Get tile from cache
  Future<Uint8List?> getTile(int z, int x, int y) async {
    if (!_isInitialized) return null;
    
    try {
      final key = _getTileKey(z, x, y);
      final file = _getTileFile(key);
      
      if (await hasTile(z, x, y)) {
        return await file.readAsBytes();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading cached tile: $e');
      }
    }
    
    return null;
  }
  
  /// Save tile to cache
  Future<void> saveTile(int z, int x, int y, Uint8List tileData) async {
    if (!_isInitialized) return;
    
    try {
      final key = _getTileKey(z, x, y);
      final file = _getTileFile(key);
      
      await file.writeAsBytes(tileData);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving tile to cache: $e');
      }
    }
  }
  
  /// Download and cache tile
  Future<Uint8List?> downloadAndCacheTile(int z, int x, int y) async {
    if (!_isInitialized) return null;
    
    try {
      // OpenStreetMap tile URL
      final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'TuKrasnal Mobile App',
        },
      );
      
      if (response.statusCode == 200) {
        final tileData = response.bodyBytes;
        await saveTile(z, x, y, tileData);
        return tileData;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading tile: $e');
      }
    }
    
    return null;
  }
  
  /// Get tile (from cache or download)
  Future<Uint8List?> getTileWithFallback(int z, int x, int y) async {
    // Try cache first
    final cached = await getTile(z, x, y);
    if (cached != null) return cached;
    
    // Download if not in cache
    return await downloadAndCacheTile(z, x, y);
  }
  
  /// Pre-cache tiles for Wrocław area
  Future<void> preCacheWroclaw({
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) return;
    
    // Wrocław bounds (approximate)
    const double minLat = 50.9500;
    const double maxLat = 51.2500;
    const double minLng = 16.8000;
    const double maxLng = 17.2000;
    
    // Cache levels 10-15 (city overview to street detail)
    const List<int> zoomLevels = [10, 11, 12, 13, 14, 15];
    
    int totalTiles = 0;
    int currentTile = 0;
    
    // Calculate total tiles to download
    for (int z in zoomLevels) {
      final bounds = _latLngToTileBounds(minLat, maxLat, minLng, maxLng, z);
      totalTiles += (bounds.maxX - bounds.minX + 1) * (bounds.maxY - bounds.minY + 1);
    }
    
    if (kDebugMode) {
      print('Pre-caching $totalTiles tiles for Wrocław...');
    }
    
    for (int z in zoomLevels) {
      final bounds = _latLngToTileBounds(minLat, maxLat, minLng, maxLng, z);
      
      for (int x = bounds.minX; x <= bounds.maxX; x++) {
        for (int y = bounds.minY; y <= bounds.maxY; y++) {
          // Skip if already cached
          if (await hasTile(z, x, y)) {
            currentTile++;
            continue;
          }
          
          // Download tile
          await downloadAndCacheTile(z, x, y);
          currentTile++;
          
          // Report progress
          onProgress?.call(currentTile, totalTiles);
          
          // Small delay to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Break if cache is getting too large
          if (await getCacheSizeMB() > maxCacheSizeMB * 0.8) {
            if (kDebugMode) {
              print('Cache size limit approaching, stopping pre-cache');
            }
            return;
          }
        }
      }
    }
    
    if (kDebugMode) {
      print('Pre-caching completed!');
    }
  }
  
  /// Convert lat/lng bounds to tile bounds
  TileBounds _latLngToTileBounds(double minLat, double maxLat, double minLng, double maxLng, int zoom) {
    final minTileX = _lonToTileX(minLng, zoom);
    final maxTileX = _lonToTileX(maxLng, zoom);
    final minTileY = _latToTileY(maxLat, zoom); // Note: Y is inverted
    final maxTileY = _latToTileY(minLat, zoom);
    
    return TileBounds(
      minX: minTileX,
      maxX: maxTileX,
      minY: minTileY,
      maxY: maxTileY,
    );
  }
  
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }
  
  int _latToTileY(double lat, int zoom) {
    final rad = lat * (pi / 180.0);
    return ((1.0 - log(tan(rad) + 1.0 / cos(rad)) / pi) / 2.0 * (1 << zoom)).floor();
  }
  
  /// Get current cache size in MB
  Future<double> getCacheSizeMB() async {
    if (!_isInitialized) return 0;
    
    try {
      int totalSize = 0;
      final files = await _cacheDir!.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized) {
      return {'tiles': 0, 'sizeMB': 0.0, 'isWroclawCached': false};
    }
    
    try {
      final files = await _cacheDir!.list().toList();
      final tileCount = files.where((f) => f.path.endsWith('.png')).length;
      final sizeMB = await getCacheSizeMB();
      
      return {
        'tiles': tileCount,
        'sizeMB': sizeMB,
        'isWroclawCached': tileCount > 1000, // Rough estimate
      };
    } catch (e) {
      return {'tiles': 0, 'sizeMB': 0.0, 'isWroclawCached': false};
    }
  }
  
  /// Clean old or excess tiles
  Future<void> _cleanOldTiles() async {
    if (!_isInitialized) return;
    
    try {
      final files = await _cacheDir!.list().toList();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          // Delete tiles older than maxAgeHours
          if (age.inHours > maxAgeHours) {
            await file.delete();
          }
        }
      }
      
      // If cache is still too large, delete oldest tiles
      if (await getCacheSizeMB() > maxCacheSizeMB) {
        await _deleteOldestTiles();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning old tiles: $e');
      }
    }
  }
  
  /// Delete oldest tiles to free space
  Future<void> _deleteOldestTiles() async {
    try {
      final files = await _cacheDir!.list().toList();
      final tileFiles = <File>[];
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          tileFiles.add(file);
        }
      }
      
      // Sort by modification date (oldest first)
      tileFiles.sort((a, b) {
        return a.lastModifiedSync().compareTo(b.lastModifiedSync());
      });
      
      // Delete oldest 20% of tiles
      final deleteCount = (tileFiles.length * 0.2).round();
      for (int i = 0; i < deleteCount && i < tileFiles.length; i++) {
        await tileFiles[i].delete();
      }
      
      if (kDebugMode) {
        print('Deleted $deleteCount old tiles to free space');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting oldest tiles: $e');
      }
    }
  }
  
  /// Clear entire cache
  Future<void> clearCache() async {
    if (!_isInitialized) return;
    
    try {
      final files = await _cacheDir!.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          await file.delete();
        }
      }
      
      if (kDebugMode) {
        print('Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }
}

class TileBounds {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  
  TileBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}