import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/krasnal_models.dart';
import 'supabase_service.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['role'] == 'admin';
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Create new Krasnal with all required schema fields
  Future<String> createKrasnal({
    required String name,
    required String description,
    String? history,
    required double latitude,
    required double longitude,
    String? locationAddress,
    required KrasnalRarity rarity,
    required int pointsValue,
    int discoveryRadius = 25,
    String? primaryImageUrl,
    String? undiscoveredMedallionUrl,
    String? discoveredMedallionUrl,
    List<String> galleryImages = const [],
    List<Map<String, dynamic>> additionalImages = const [],
  }) async {
    try {
      // Extract medallion URLs from additionalImages if not provided directly
      String? finalUndiscoveredUrl = undiscoveredMedallionUrl;
      String? finalDiscoveredUrl = discoveredMedallionUrl;
      List<String> finalGalleryImages = List.from(galleryImages);

      // Process additionalImages to extract medallion and gallery images
      for (var imageData in additionalImages) {
        final type = imageData['type'] as String?;
        final url = imageData['url'] as String?;
        
        if (url != null) {
          switch (type) {
            case 'medallion_undiscovered':
              finalUndiscoveredUrl ??= url;
              break;
            case 'medallion_discovered':
              finalDiscoveredUrl ??= url;
              break;
            case 'gallery':
              finalGalleryImages.add(url);
              break;
          }
        }
      }

      // Prepare gallery images as JSON array string for database
      String? galleryImagesJson;
      if (finalGalleryImages.isNotEmpty) {
        galleryImagesJson = '["${finalGalleryImages.join('","')}"]';
      }

      // Prepare data matching database schema
      final krasnalData = {
        'name': name,
        'description': description,
        'history': history,
        'location_name': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': primaryImageUrl,
        'rarity': rarity.name,
        'discovery_radius': discoveryRadius,
        'points_value': pointsValue,
        'is_active': true,
        'undiscovered_medallion_url': finalUndiscoveredUrl,
        'discovered_medallion_url': finalDiscoveredUrl,
        'gallery_images': galleryImagesJson,
      };

      // Insert into database
      final response = await _supabase
          .from('krasnale')
          .insert(krasnalData)
          .select('id')
          .single();

      final krasnalId = response['id'] as String;
      print('✅ Krasnal created successfully with ID: $krasnalId');
      return krasnalId;
      
    } catch (e) {
      print('❌ Error creating krasnal: $e');
      throw Exception('Failed to create krasnal: $e');
    }
  }

  // Update existing Krasnal
  Future<void> updateKrasnal(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('krasnale')
          .update(updates)
          .eq('id', id);
      
      print('✅ Krasnal updated successfully: $id');
    } catch (e) {
      print('❌ Error updating krasnal: $e');
      throw Exception('Failed to update krasnal: $e');
    }
  }

  // Delete Krasnal (basic method - kept for compatibility)
  Future<void> deleteKrasnal(String id) async {
    try {
      await _supabase
          .from('krasnale')
          .delete()
          .eq('id', id);
      
      print('✅ Krasnal deleted successfully: $id');
    } catch (e) {
      print('❌ Error deleting krasnal: $e');
      throw Exception('Failed to delete krasnal: $e');
    }
  }

  // Enhanced delete method that also removes associated images from storage
  Future<bool> deleteKrasnalWithImages(String krasnalId) async {
    try {
      // First get the krasnal to find its images
      final krasnal = await SupabaseService.instance.getKrasnalById(krasnalId);
      if (krasnal == null) {
        print('⚠️ Krasnal not found: $krasnalId');
        return false;
      }

      // Delete associated images from storage
      try {
        if (krasnal.primaryImageUrl != null) {
          await _deleteImageFromStorage(krasnal.primaryImageUrl!);
        }
        if (krasnal.undiscoveredMedallionUrl != null) {
          await _deleteImageFromStorage(krasnal.undiscoveredMedallionUrl!);
        }
        if (krasnal.discoveredMedallionUrl != null) {
          await _deleteImageFromStorage(krasnal.discoveredMedallionUrl!);
        }
        for (var galleryUrl in krasnal.galleryImages) {
          await _deleteImageFromStorage(galleryUrl);
        }
      } catch (storageError) {
        print('⚠️ Some images could not be deleted from storage: $storageError');
        // Continue with database deletion even if storage cleanup fails
      }

      // Delete from database
      await deleteKrasnal(krasnalId);
      return true;
      
    } catch (e) {
      print('❌ Error in deleteKrasnalWithImages: $e');
      return false;
    }
  }

  // Helper method to delete image from Supabase storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      // Extract storage path from full URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3 && pathSegments[0] == 'storage' && pathSegments[1] == 'v1') {
        final bucket = pathSegments[4]; // Assuming structure: /storage/v1/object/public/bucket/path
        final filePath = pathSegments.skip(5).join('/');
        
        await _supabase.storage.from(bucket).remove([filePath]);
        print('✅ Image deleted from storage: $filePath');
      }
    } catch (e) {
      print('⚠️ Could not delete image from storage: $imageUrl - $e');
      // Don't throw, as this is cleanup operation
    }
  }

  // Get all Krasnale for admin management
  Future<List<Krasnal>> getAllKrasnaleForAdmin() async {
    try {
      final response = await _supabase
          .from('krasnale')
          .select('*')
          .order('created_at', ascending: false);

      final krasnaleData = response as List<dynamic>;
      return krasnaleData.map((json) => Krasnal.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching krasnale for admin: $e');
      return [];
    }
  }

  // Get user reports
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select('*, krasnale(name), user_profiles(username)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching user reports: $e');
      return [];
    }
  }

  // Update krasnal activation status
  Future<void> updateKrasnalActiveStatus(String krasnalId, bool isActive) async {
    try {
      await updateKrasnal(krasnalId, {'is_active': isActive});
      print('✅ Krasnal active status updated: $krasnalId -> $isActive');
    } catch (e) {
      print('❌ Error updating krasnal active status: $e');
      throw e;
    }
  }

  // Batch operations
  Future<void> batchUpdateKrasnale(List<String> krasnalIds, Map<String, dynamic> updates) async {
    try {
      for (var id in krasnalIds) {
        await updateKrasnal(id, updates);
      }
      print('✅ Batch update completed for ${krasnalIds.length} krasnale');
    } catch (e) {
      print('❌ Error in batch update: $e');
      throw e;
    }
  }
}