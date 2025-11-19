import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseImageService {
  static const String bucketName = 'krasnale-images';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload an image and return the public URL
  Future<String?> uploadImage({
    required XFile imageFile,
    String? customFileName,
    String folder = 'krasnale',
  }) async {
    try {
      print('🔄 Uploading image to Supabase...');
      
      // Generate unique filename
      final fileName = customFileName ?? _generateFileName(imageFile.name);
      final filePath = '$folder/$fileName';
      
      // Get image data
      final imageBytes = await imageFile.readAsBytes();
      
      print('   📁 Bucket: $bucketName');
      print('   📄 Path: $filePath');
      print('   📦 Size: ${imageBytes.length} bytes');
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true, // Allow overwriting
            ),
          );
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
      
      print('✅ Image uploaded successfully!');
      print('   🔗 URL: $publicUrl');
      
      return publicUrl;
      
    } catch (e) {
      print('❌ Error uploading image to Supabase: $e');
      return null;
    }
  }
  
  /// Upload image from local file path (mobile)
  Future<String?> uploadImageFromPath({
    required String filePath,
    String? customFileName,
    String folder = 'krasnale',
  }) async {
    try {
      if (kIsWeb) {
        throw Exception('uploadImageFromPath not supported on web');
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      // Create XFile from path
      final xFile = XFile(filePath);
      
      return await uploadImage(
        imageFile: xFile,
        customFileName: customFileName,
        folder: folder,
      );
      
    } catch (e) {
      print('❌ Error uploading image from path: $e');
      return null;
    }
  }
  
  /// Upload image from bytes (web)
  Future<String?> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'krasnale',
  }) async {
    try {
      print('🔄 Uploading image bytes to Supabase...');
      
      // Generate unique filename
      final uniqueFileName = _generateFileName(fileName);
      final filePath = '$folder/$uniqueFileName';
      
      print('   📁 Bucket: $bucketName');
      print('   📄 Path: $filePath');
      print('   📦 Size: ${imageBytes.length} bytes');
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
      
      print('✅ Image uploaded successfully!');
      print('   🔗 URL: $publicUrl');
      
      return publicUrl;
      
    } catch (e) {
      print('❌ Error uploading image bytes to Supabase: $e');
      return null;
    }
  }
  
  /// Delete an image from Supabase storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from Supabase URL
      final filePath = _extractFilePathFromUrl(imageUrl);
      if (filePath == null) {
        print('❌ Could not extract file path from URL: $imageUrl');
        return false;
      }
      
      print('🗑️ Deleting image from Supabase...');
      print('   📄 Path: $filePath');
      
      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);
      
      print('✅ Image deleted successfully!');
      return true;
      
    } catch (e) {
      print('❌ Error deleting image from Supabase: $e');
      return false;
    }
  }
  
  /// Extract file path from Supabase public URL
  String? _extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Expected format: /storage/v1/object/public/bucket-name/folder/file
      final objectIndex = pathSegments.indexOf('object');
      if (objectIndex >= 0 && pathSegments.length > objectIndex + 3) {
        final bucketIndex = objectIndex + 2;
        final filePathSegments = pathSegments.skip(bucketIndex + 1);
        return filePathSegments.join('/');
      }
    } catch (e) {
      print('Error parsing Supabase URL: $e');
    }
    return null;
  }
  
  /// Generate unique filename
  String _generateFileName(String originalFileName) {
    final extension = path.extension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000).toString().padLeft(3, '0');
    
    return 'krasnal_${timestamp}_$random$extension';
  }
  
  /// Check if bucket exists and is properly configured
  Future<bool> checkBucketExists() async {
    try {
      await _supabase.storage.getBucket(bucketName);
      return true;
    } catch (e) {
      print('❌ Bucket $bucketName not found or not accessible: $e');
      return false;
    }
  }
  
  /// Create bucket if it doesn't exist (admin function)
  Future<bool> createBucketIfNeeded() async {
    try {
      if (await checkBucketExists()) {
        print('✅ Bucket $bucketName already exists');
        return true;
      }
      
      print('🔄 Creating bucket: $bucketName');
      await _supabase.storage.createBucket(
        bucketName,
        BucketOptions(
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        ),
      );
      
      print('✅ Bucket created successfully!');
      return true;
      
    } catch (e) {
      print('❌ Error creating bucket: $e');
      return false;
    }
  }
}