import 'admin_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enhanced AdminService method to fetch krasnale with ALL image fields
extension AdminServiceEnhancedFetch on AdminService {
  
  /// Get all krasnale with complete image data
  Future<List<Map<String, dynamic>>> getAllKrasnaleWithImages() async {
    try {
      print('🔄 Fetching all krasnale with image fields...');
      
      final response = await Supabase.instance.client
          .from('krasnale')
          .select('*, undiscovered_medallion_url, discovered_medallion_url, gallery_images')
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} krasnale with image data');
      
      // Return raw JSON data that includes image fields
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      print('❌ Error fetching krasnale with images: $e');
      return [];
    }
  }
  
  /// Get single krasnal with complete image data
  Future<Map<String, dynamic>?> getKrasnalWithImages(String id) async {
    try {
      print('🔄 Fetching krasnal $id with image fields...');
      
      final response = await Supabase.instance.client
          .from('krasnale')
          .select('*, undiscovered_medallion_url, discovered_medallion_url, gallery_images')
          .eq('id', id)
          .single();

      print('✅ Fetched krasnal with image data');
      
      return response as Map<String, dynamic>;
      
    } catch (e) {
      print('❌ Error fetching krasnal with images: $e');
      return null;
    }
  }
}