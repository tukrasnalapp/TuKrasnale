import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/krasnal_models.dart';

// 🎯 ENHANCED ADMIN SERVICE WITH COMPLETE IMAGE SUPPORT
// This service fetches ALL image fields from database and works with the consolidated Krasnal model
class AdminServiceComplete {
  
  /// Get all krasnale with COMPLETE image data including all images
  Future<List<Krasnal>> getAllKrasnaleComplete() async {
    try {
      print('🔄 Fetching all krasnale with complete image data...');
      
      // 🎯 KEY: SELECT all fields including the images table
      final response = await Supabase.instance.client
          .from('krasnale')
          .select('''
            id,
            name,
            description,
            latitude,
            longitude,
            location:locations(
              id,
              address,
              country,
              city
            ),
            metadata,
            primary_image_url,
            created_at,
            images(
              id,
              url,
              type,
              order_index
            )
          ''')
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} krasnale with complete data');
      print('📊 Sample data: ${response.isNotEmpty ? response.first : 'No data'}');
      
      // 🎯 Parse response directly since we need custom handling for the consolidated model
      final List<Krasnal> krasnale = [];
      
      for (final json in response) {
        try {
          final krasnal = Krasnal(
            id: json['id'] as String,
            name: json['name'] as String,
            description: json['description'] as String? ?? '',
            location: _parseLocation(json['location'], 
                                   (json['latitude'] as num).toDouble(), 
                                   (json['longitude'] as num).toDouble()),
            metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
            createdAt: DateTime.parse(json['created_at'] as String),
            images: _parseImages(json['images']),
          );
          krasnale.add(krasnal);
        } catch (e) {
          print('⚠️ Failed to parse krasnal ${json['id']}: $e');
        }
      }
      
      return krasnale;
      
    } catch (e) {
      print('❌ Error fetching complete krasnale: $e');
      return [];
    }
  }

  /// Helper method to parse location data
  KrasnalLocation _parseLocation(dynamic locationData, double latitude, double longitude) {
    if (locationData == null) {
      return KrasnalLocation(
        latitude: latitude,
        longitude: longitude,
        address: null,
      );
    }
    
    return KrasnalLocation(
      latitude: latitude,
      longitude: longitude,
      address: locationData['address'] as String?,
    );
  }

  /// Helper method to parse images data
  List<KrasnalImage> _parseImages(dynamic imagesData) {
    if (imagesData == null) return [];
    
    final imagesList = imagesData as List<dynamic>;
    return imagesList.map((imageJson) => KrasnalImage(
      id: imageJson['id'] as String,
      url: imageJson['url'] as String,
      uploadedAt: DateTime.now(), // Default value since we don't have this in the query
    )).toList();
  }
  
  /// Get single krasnal with complete image data
  Future<Krasnal?> getKrasnalComplete(String id) async {
    try {
      print('🔄 Fetching krasnal $id with complete image data...');
      
      final response = await Supabase.instance.client
          .from('krasnale')
          .select('''
            id,
            name,
            description,
            latitude,
            longitude,
            location:locations(
              id,
              address,
              country,
              city
            ),
            metadata,
            primary_image_url,
            created_at,
            images(
              id,
              url,
              type,
              order_index
            )
          ''')
          .eq('id', id)
          .single();

      print('✅ Fetched complete krasnal data');
      print('📊 Image data: primary=${response['primary_image_url'] != null}, additional=${response['images']?.length ?? 0}');
      
      // Parse the single result
      return Krasnal(
        id: response['id'] as String,
        name: response['name'] as String,
        description: response['description'] as String? ?? '',
        location: _parseLocation(response['location'], 
                               (response['latitude'] as num).toDouble(), 
                               (response['longitude'] as num).toDouble()),
        metadata: response['metadata'] != null ? Map<String, dynamic>.from(response['metadata']) : null,
        createdAt: DateTime.parse(response['created_at'] as String),
        images: _parseImages(response['images']),
      );
      
    } catch (e) {
      print('❌ Error fetching complete krasnal: $e');
      return null;
    }
  }
  
  /// Get krasnale with specific image types
  Future<List<Krasnal>> getKrasnaleWithImageType(String imageType) async {
    try {
      print('🔄 Fetching krasnale with image type: $imageType');
      
      final response = await Supabase.instance.client
          .from('krasnale')
          .select('''
            id,
            name,
            description,
            latitude,
            longitude,
            location:locations(
              id,
              address,
              country,
              city
            ),
            metadata,
            primary_image_url,
            created_at,
            images!inner(
              id,
              url,
              type,
              order_index
            )
          ''')
          .eq('images.type', imageType)
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} krasnale with $imageType images');
      
      // Parse each result
      final List<Krasnal> krasnale = [];
      for (final json in response) {
        try {
          final krasnal = Krasnal(
            id: json['id'] as String,
            name: json['name'] as String,
            description: json['description'] as String? ?? '',
            location: _parseLocation(json['location'], 
                                   (json['latitude'] as num).toDouble(), 
                                   (json['longitude'] as num).toDouble()),
            metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
            createdAt: DateTime.parse(json['created_at'] as String),
            images: _parseImages(json['images']),
          );
          krasnale.add(krasnal);
        } catch (e) {
          print('⚠️ Failed to parse krasnal ${json['id']}: $e');
        }
      }
      
      return krasnale;
      
    } catch (e) {
      print('❌ Error fetching krasnale with image type $imageType: $e');
      return [];
    }
  }
  
  /// Get images by type for a specific krasnal
  Future<List<KrasnalImage>> getKrasnalImagesByType(String krasnalId, String imageType) async {
    try {
      print('🔄 Fetching $imageType images for krasnal $krasnalId');
      
      final response = await Supabase.instance.client
          .from('images')
          .select('*')
          .eq('krasnal_id', krasnalId)
          .eq('type', imageType)
          .order('order_index', ascending: true);

      print('✅ Fetched ${response.length} $imageType images');
      
      return response.map((json) => KrasnalImage(
        id: json['id'] as String,
        url: json['url'] as String,
        uploadedAt: DateTime.parse(json['uploaded_at'] as String? ?? DateTime.now().toIso8601String()),
      )).toList();
      
    } catch (e) {
      print('❌ Error fetching $imageType images: $e');
      return [];
    }
  }
  
  /// Get count of krasnale by image availability
  Future<Map<String, int>> getImageStatistics() async {
    try {
      print('🔄 Calculating image statistics...');
      
      // Get all krasnale and count in memory for simplicity
      final allKrasnale = await getAllKrasnaleComplete();
      
      final withPrimaryImage = allKrasnale.where((k) => 
          k.images.where((img) => img.url.isNotEmpty).isNotEmpty).length;
      final withAdditionalImages = allKrasnale.where((k) => k.images.length > 1).length;
      
      final stats = {
        'total': allKrasnale.length,
        'with_primary_image': withPrimaryImage,
        'with_additional_images': withAdditionalImages,
      };
      
      print('✅ Image statistics: $stats');
      return stats;
      
    } catch (e) {
      print('❌ Error calculating image statistics: $e');
      return {
        'total': 0,
        'with_primary_image': 0,
        'with_additional_images': 0,
      };
    }
  }
}