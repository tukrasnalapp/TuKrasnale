import '../services/admin_service.dart';
import '../services/supabase_image_service.dart';
import '../services/supabase_service.dart';

extension AdminServiceImageExtensions on AdminService {
  
  /// Delete a krasnal and its associated images from Supabase
  Future<bool> deleteKrasnalWithImages(String krasnalId) async {
    final imageService = SupabaseImageService();
    final supabaseService = SupabaseService.instance;
    
    try {
      print('🔄 Deleting krasnal with images: $krasnalId');
      
      // First, get the krasnal to find its image URLs
      final krasnal = await supabaseService.getAllKrasnale();
      final targetKrasnal = krasnal.where((k) => k.id == krasnalId).firstOrNull;
      
      if (targetKrasnal == null) {
        print('❌ Krasnal not found: $krasnalId');
        return false;
      }
      
      // Delete images from Supabase Storage first
      final imageUrls = <String>[];
      
      // Add primary image
      if (targetKrasnal.primaryImageUrl != null && targetKrasnal.primaryImageUrl!.isNotEmpty) {
        imageUrls.add(targetKrasnal.primaryImageUrl!);
      }
      
      // Add medallion images if they exist
      if (targetKrasnal.undiscoveredMedallionUrl != null) {
        imageUrls.add(targetKrasnal.undiscoveredMedallionUrl!);
      }
      if (targetKrasnal.discoveredMedallionUrl != null) {
        imageUrls.add(targetKrasnal.discoveredMedallionUrl!);
      }
      
      // Add gallery images
      imageUrls.addAll(targetKrasnal.galleryImages);
      
      print('📸 Found ${imageUrls.length} images to delete');
      
      // Delete each image from Supabase
      for (final imageUrl in imageUrls) {
        if (imageUrl.startsWith('http')) {
          try {
            final deleted = await imageService.deleteImage(imageUrl);
            if (deleted) {
              print('✅ Deleted image: $imageUrl');
            } else {
              print('⚠️ Failed to delete image: $imageUrl');
            }
          } catch (e) {
            print('❌ Error deleting image $imageUrl: $e');
            // Continue with other images even if one fails
          }
        }
      }
      
      // Now delete the krasnal record
      try {
        await deleteKrasnal(krasnalId);
        print('✅ Krasnal and images deleted successfully');
        return true;
      } catch (e) {
        print('❌ Failed to delete krasnal record: $e');
        return false;
      }
      
    } catch (e) {
      print('❌ Error in deleteKrasnalWithImages: $e');
      return false;
    }
  }
}