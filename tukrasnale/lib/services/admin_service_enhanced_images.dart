import '../models/krasnal_models.dart';
import '../services/admin_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enhanced AdminService methods for handling all image types
extension AdminServiceEnhancedImages on AdminService {
  
  /// Create a krasnal with all image types (main, medallions, gallery)
  Future<bool> createKrasnalWithAllImages({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    String? locationName,
    required KrasnalRarity rarity,
    required int pointsValue,
    required String imageUrl, // Main image (required)
    String? undiscoveredMedallionUrl,
    String? discoveredMedallionUrl,
    List<String> galleryImages = const [],
  }) async {
    try {
      print('🔄 Creating krasnal with enhanced images...');
      print('   Main image: $imageUrl');
      print('   Undiscovered medallion: $undiscoveredMedallionUrl');
      print('   Discovered medallion: $discoveredMedallionUrl');
      print('   Gallery images: ${galleryImages.length} images');

      final response = await Supabase.instance.client
          .from('krasnale')
          .insert({
            'name': name,
            'description': description,
            'latitude': latitude,
            'longitude': longitude,
            'location_name': locationName,
            'rarity': rarity.name,
            'points_value': pointsValue,
            'image_url': imageUrl,
            'undiscovered_medallion_url': undiscoveredMedallionUrl,
            'discovered_medallion_url': discoveredMedallionUrl,
            'gallery_images': galleryImages,
            'created_at': DateTime.now().toIso8601String(),
          });

      print('✅ Krasnal created with all images successfully');
      return true;
      
    } catch (e) {
      print('❌ Error creating krasnal with all images: $e');
      return false;
    }
  }
}