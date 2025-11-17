import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

enum ImageUploadType {
  krasnaleMain,
  krasnaleUndiscoveredMedallion,
  krasnaleDiscoveredMedallion,
  krasnaleGallery,
  reportPhoto,
}

class ImageUploadResult {
  final String? url;
  final String? error;
  final bool success;

  ImageUploadResult({
    this.url,
    this.error,
    required this.success,
  });

  factory ImageUploadResult.success(String url) {
    return ImageUploadResult(url: url, success: true);
  }

  factory ImageUploadResult.error(String error) {
    return ImageUploadResult(error: error, success: false);
  }
}

class ImageUploadService {
  static final _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // Storage bucket configurations
  static const Map<ImageUploadType, String> _bucketMapping = {
    ImageUploadType.krasnaleMain: 'krasnale-images',
    ImageUploadType.krasnaleUndiscoveredMedallion: 'krasnale-images',
    ImageUploadType.krasnaleDiscoveredMedallion: 'krasnale-images',
    ImageUploadType.krasnaleGallery: 'krasnale-images',
    ImageUploadType.reportPhoto: 'report-photos',
  };

  // Image size limits (in bytes)
  static const Map<ImageUploadType, int> _sizeLimit = {
    ImageUploadType.krasnaleMain: 2 * 1024 * 1024, // 2MB
    ImageUploadType.krasnaleUndiscoveredMedallion: 1 * 1024 * 1024, // 1MB
    ImageUploadType.krasnaleDiscoveredMedallion: 1 * 1024 * 1024, // 1MB
    ImageUploadType.krasnaleGallery: 2 * 1024 * 1024, // 2MB
    ImageUploadType.reportPhoto: 3 * 1024 * 1024, // 3MB
  };

  // Image quality settings
  static const Map<ImageUploadType, int> _qualitySettings = {
    ImageUploadType.krasnaleMain: 85,
    ImageUploadType.krasnaleUndiscoveredMedallion: 90,
    ImageUploadType.krasnaleDiscoveredMedallion: 90,
    ImageUploadType.krasnaleGallery: 80,
    ImageUploadType.reportPhoto: 75,
  };

  /// Pick image from camera
  Future<ImageUploadResult> pickFromCamera(ImageUploadType type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: _qualitySettings[type],
      );

      if (image == null) {
        return ImageUploadResult.error('No image selected');
      }

      return await _processAndUploadImage(image, type);
    } catch (e) {
      return ImageUploadResult.error('Camera error: $e');
    }
  }

  /// Pick image from gallery
  Future<ImageUploadResult> pickFromGallery(ImageUploadType type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: _qualitySettings[type],
      );

      if (image == null) {
        return ImageUploadResult.error('No image selected');
      }

      return await _processAndUploadImage(image, type);
    } catch (e) {
      return ImageUploadResult.error('Gallery error: $e');
    }
  }

  /// Pick multiple images from gallery (for gallery uploads)
  Future<List<ImageUploadResult>> pickMultipleFromGallery(ImageUploadType type) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: _qualitySettings[type],
      );

      if (images.isEmpty) {
        return [ImageUploadResult.error('No images selected')];
      }

      // Limit to 5 images max
      final limitedImages = images.take(5).toList();
      final results = <ImageUploadResult>[];

      for (final image in limitedImages) {
        final result = await _processAndUploadImage(image, type);
        results.add(result);
      }

      return results;
    } catch (e) {
      return [ImageUploadResult.error('Gallery error: $e')];
    }
  }

  /// Process and upload image
  Future<ImageUploadResult> _processAndUploadImage(XFile image, ImageUploadType type) async {
    try {
      // Read image bytes
      final Uint8List bytes = await image.readAsBytes();
      
      // Check file size
      final sizeLimit = _sizeLimit[type]!;
      if (bytes.length > sizeLimit) {
        return ImageUploadResult.error(
          'Image too large. Maximum size: ${(sizeLimit / 1024 / 1024).toStringAsFixed(1)}MB'
        );
      }

      // Compress image if needed
      final processedBytes = await _compressImageIfNeeded(bytes, type);
      
      // Generate unique filename
      final filename = _generateFileName(type);
      
      // Upload to Supabase storage
      final bucket = _bucketMapping[type]!;
      
      await _supabase.storage
          .from(bucket)
          .uploadBinary(filename, processedBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(filename);

      return ImageUploadResult.success(publicUrl);
      
    } catch (e) {
      return ImageUploadResult.error('Upload failed: $e');
    }
  }

  /// Compress image if it exceeds size limits
  Future<Uint8List> _compressImageIfNeeded(Uint8List bytes, ImageUploadType type) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Calculate compression based on type
      int quality = _qualitySettings[type]!;
      final sizeLimit = _sizeLimit[type]!;

      // If image is still too large, reduce quality further
      if (bytes.length > sizeLimit) {
        quality = (quality * 0.7).round(); // Reduce quality by 30%
      }

      // Resize if image is very large
      img.Image resizedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }

      // Encode as JPEG with compression
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      return Uint8List.fromList(compressedBytes);
      
    } catch (e) {
      // If compression fails, return original
      debugPrint('Image compression failed: $e');
      return bytes;
    }
  }

  /// Generate unique filename
  String _generateFileName(ImageUploadType type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    
    String prefix;
    switch (type) {
      case ImageUploadType.krasnaleMain:
        prefix = 'main';
        break;
      case ImageUploadType.krasnaleUndiscoveredMedallion:
        prefix = 'undiscovered';
        break;
      case ImageUploadType.krasnaleDiscoveredMedallion:
        prefix = 'discovered';
        break;
      case ImageUploadType.krasnaleGallery:
        prefix = 'gallery';
        break;
      case ImageUploadType.reportPhoto:
        prefix = 'report';
        break;
    }
    
    return '${prefix}_${timestamp}_$random.jpg';
  }

  /// Delete image from storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final filename = path.basename(uri.path);
      
      // Determine bucket from URL
      String bucket = 'krasnale-images'; // Default
      if (imageUrl.contains('report-photos')) {
        bucket = 'report-photos';
      }
      
      await _supabase.storage.from(bucket).remove([filename]);
      return true;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }
}