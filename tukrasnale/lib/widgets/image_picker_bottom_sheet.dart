import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';

class ImagePickerBottomSheet {
  static Future<ImageUploadResult?> show(
    BuildContext context,
    ImageUploadType type, {
    bool allowMultiple = false,
  }) async {
    final uploadService = ImageUploadService();
    
    return await showModalBottomSheet<ImageUploadResult>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Icon(Icons.camera_alt, color: TuKrasnalColors.brickRed),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () async {
                Navigator.pop(context);
                final result = await uploadService.pickFromCamera(type);
                if (context.mounted) {
                  Navigator.pop(context, result);
                }
              },
            ),
            
            ListTile(
              leading: Icon(Icons.photo_library, color: TuKrasnalColors.forestGreen),
              title: Text(allowMultiple ? 'Gallery (Multiple)' : 'Gallery'),
              subtitle: Text(allowMultiple 
                  ? 'Select multiple images' 
                  : 'Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                if (allowMultiple) {
                  final results = await uploadService.pickMultipleFromGallery(type);
                  // Return first successful result
                  final successResult = results.firstWhere(
                    (r) => r.success,
                    orElse: () => results.first,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, successResult);
                  }
                } else {
                  final result = await uploadService.pickFromGallery(type);
                  if (context.mounted) {
                    Navigator.pop(context, result);
                  }
                }
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(Icons.cancel, color: TuKrasnalColors.textLight),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}