import 'admin_service.dart';
import '../services/supabase_image_service.dart';
import '../models/krasnal_models.dart';

extension AdminServiceImageExtensions on AdminService {
  
  /// Delete a krasnal and its associated images from Supabase
  Future<bool> deleteKrasnalWithImages(String krasnalId) async {
    final imageService = SupabaseImageService();
    
    try {
      print('🔄 Deleting krasnal with images: $krasnalId');
      
      // First, get the krasnal to find its image URLs
      final krasnale = await getAllKrasnale();
      final validKrasnale = krasnale.whereType<Krasnal>().toList();
      final krasnal = validKrasnale.where((k) => k.id == krasnalId).firstOrNull;
      
      if (krasnal == null) {
        print('❌ Krasnal not found: $krasnalId');
        return false;
      }
      
      // Delete images from Supabase Storage first
      final imageUrls = <String>[];
      
      // Add all images from the images array
      for (final image in krasnal.images) {
        if (image.url.isNotEmpty && image.url.startsWith('http')) {
          imageUrls.add(image.url);
        }
      }
      
      print('📸 Found ${imageUrls.length} images to delete');
      
      // Delete each image from Supabase
      for (final imageUrl in imageUrls) {
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