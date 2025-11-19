import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/krasnal_models.dart';
import 'supabase_service.dart';
import '../models/report_models.dart';

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
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Create new Krasnal
  Future<String> createKrasnal({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    String? locationAddress,
    KrasnalRarity rarity = KrasnalRarity.common,
    int pointsValue = 10,
    String? primaryImageUrl,
    List<Map<String, dynamic>> additionalImages = const [],
  }) async {
    print('🔧 AdminService.createKrasnal called with updated version');
    print('📊 Parameters: name=$name, lat=$latitude, lng=$longitude');
    
    // Prepare gallery images array from additional images
    List<String> galleryImageUrls = [];
    if (additionalImages.isNotEmpty) {
      galleryImageUrls = additionalImages
          .map((image) => image['url'] as String)
          .where((url) => url.isNotEmpty)
          .toList();
    }

    print('🖼️ Gallery images to store: ${galleryImageUrls.length}');

    try {
      // Create the krasnal with coordinates directly in the table
      print('💾 Inserting into krasnale table directly...');
      final krasnalResponse = await _supabase.from('krasnale').insert({
        'name': name,
        'description': description ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationAddress,
        'rarity': rarity.name,
        'points_value': pointsValue,
        'image_url': primaryImageUrl,
        'gallery_images': galleryImageUrls.isEmpty ? null : galleryImageUrls,
        'discovery_radius': 50, // Default discovery radius in meters
        'is_active': true,
      }).select().single();

      final krasnalId = krasnalResponse['id'];
      print('✅ Krasnal created successfully with ID: $krasnalId');
      return krasnalId;
    } catch (e) {
      print('❌ Error in createKrasnal: $e');
      rethrow;
    }
  }

  // Update existing Krasnal
  Future<void> updateKrasnal(String id, Map<String, dynamic> updates) async {
    await _supabase
        .from('krasnale')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // Delete Krasnal (basic method - kept for compatibility)
  Future<void> deleteKrasnal(String id) async {
    await _supabase.from('krasnale').delete().eq('id', id);
  }

  // Enhanced delete method that also removes associated images from storage
  Future<bool> deleteKrasnalWithImages(String krasnalId) async {
    try {
      print('🔄 Deleting krasnal with images: $krasnalId');
      
      // First, get the krasnal to find its image URLs
      final krasnale = await getAllKrasnale();
      final krasnal = krasnale.where((k) => k.id == krasnalId).firstOrNull;
      
      if (krasnal == null) {
        print('❌ Krasnal not found: $krasnalId');
        return false;
      }
      
      // Collect all image URLs that need to be deleted from storage
      final imageUrls = <String>[];
      
      // Add primary image if exists
      if (krasnal.primaryImageUrl != null && krasnal.primaryImageUrl!.isNotEmpty) {
        imageUrls.add(krasnal.primaryImageUrl!);
      }
      
      // Add all images from the images array
      for (final image in krasnal.images) {
        if (image.url.isNotEmpty && image.url.startsWith('http')) {
          imageUrls.add(image.url);
        }
      }
      
      print('📸 Found ${imageUrls.length} images to delete');
      
      // Delete each image from Supabase Storage
      for (final imageUrl in imageUrls) {
        try {
          await deleteImage(imageUrl);
          print('✅ Deleted image: $imageUrl');
        } catch (e) {
          print('⚠️ Failed to delete image $imageUrl: $e');
          // Continue with other images even if one fails
        }
      }
      
      // Now delete the krasnal record
      await deleteKrasnal(krasnalId);
      print('✅ Krasnal and images deleted successfully');
      return true;
      
    } catch (e) {
      print('❌ Error in deleteKrasnalWithImages: $e');
      return false;
    }
  }

  // Get all Krasnale for admin management
  Future<List<Krasnal>> getAllKrasnale() async {
    // Use the working SupabaseService instead of complex joins
    final supabaseService = SupabaseService.instance;
    return await supabaseService.getAllKrasnale();
  }

  // Check if name is unique (excluding current krasnal if editing)
  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    final query = _supabase.from('krasnale').select('id').eq('name', name);
    
    if (excludeId != null) {
      query.neq('id', excludeId);
    }
    
    final response = await query;
    return response.isNotEmpty;
  }

  // Check if coordinates exist (excluding current krasnal if editing)
  Future<bool> checkCoordinatesExist(double latitude, double longitude, {String? excludeId}) async {
    final query = _supabase
        .from('krasnale')
        .select('id')
        .eq('latitude', latitude)
        .eq('longitude', longitude);
    
    if (excludeId != null) {
      query.neq('id', excludeId);
    }
    
    final response = await query;
    return response.isNotEmpty;
  }


  // Get all reports for admin review
  Future<List<KrasnaleReport>> getAllReports() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('*')
        .order('created_at', ascending: false);

    return response.map<KrasnaleReport>((json) => KrasnaleReport.fromJson(json)).toList();
  }

  // Update report status with admin notes
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminNotes,
  }) async {
    String statusValue;
    switch (status) {
      case ReportStatus.inReview:
        statusValue = 'in_review';
        break;
      default:
        statusValue = status.name;
    }

    await _supabase.from('krasnale_reports').update({
      'status': statusValue,
      'admin_notes': adminNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  // Get reports by status for admin dashboard
  Future<List<KrasnaleReport>> getReportsByStatus(ReportStatus status) async {
    String statusValue;
    switch (status) {
      case ReportStatus.inReview:
        statusValue = 'in_review';
        break;
      default:
        statusValue = status.name;
    }

    final response = await _supabase
        .from('krasnale_reports')
        .select('*')
        .eq('status', statusValue)
        .order('created_at', ascending: false);

    return response.map<KrasnaleReport>((json) => KrasnaleReport.fromJson(json)).toList();
  }

  // Get report statistics for admin dashboard
  Future<Map<String, int>> getReportStatistics() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('status');

    final stats = <String, int>{
      'pending': 0,
      'in_review': 0,
      'resolved': 0,
      'rejected': 0,
    };

    for (final row in response) {
      final status = row['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // Get pending reports count
  Future<int> getPendingReportsCount() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('id')
        .eq('status', 'pending');

    return response.length;
  }

  // Upload image to storage
  Future<String?> uploadImage(String path, List<int> bytes) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      await _supabase.storage
          .from('krasnale-images')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      return _supabase.storage
          .from('krasnale-images')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabase.storage
          .from('krasnale-images')
          .remove([fileName]);
    } catch (e) {
      // Ignore deletion errors
    }
  }
}