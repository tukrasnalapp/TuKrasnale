import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_picker_bottom_sheet.dart';

class ImageUploadWithPreview extends StatefulWidget {
  final String? initialImageUrl;
  final ImageUploadType uploadType;
  final Function(String?) onImageSelected;
  final String title;
  final bool required;
  final double? width;
  final double? height;

  const ImageUploadWithPreview({
    super.key,
    this.initialImageUrl,
    required this.uploadType,
    required this.onImageSelected,
    this.title = 'Upload Image',
    this.required = false,
    this.width,
    this.height,
  });

  @override
  State<ImageUploadWithPreview> createState() => _ImageUploadWithPreviewState();
}

class _ImageUploadWithPreviewState extends State<ImageUploadWithPreview> {
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: TuKrasnalColors.error,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Image preview and upload area
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: _imageUrl != null 
                  ? TuKrasnalColors.forestGreen
                  : TuKrasnalColors.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: TuKrasnalColors.surface,
          ),
          child: Stack(
            children: [
              // Image or placeholder
              if (_imageUrl != null)
                _buildImagePreview()
              else
                _buildUploadPlaceholder(),
              
              // Upload overlay
              if (_isUploading)
                _buildUploadingOverlay(),
              
              // Action buttons
              if (!_isUploading)
                _buildActionButtons(),
            ],
          ),
        ),
        
        // Upload status
        if (_imageUrl != null && !_isUploading) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: TuKrasnalColors.forestGreen,
              ),
              const SizedBox(width: 4),
              Text(
                'Image uploaded successfully',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TuKrasnalColors.forestGreen,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                color: TuKrasnalColors.brickRed,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: TuKrasnalColors.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: TuKrasnalColors.error),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return InkWell(
      onTap: _selectImage,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: TuKrasnalColors.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add image',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: TuKrasnalColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Camera or Gallery',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TuKrasnalColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: TuKrasnalColors.brickRed,
            ),
            const SizedBox(height: 12),
            const Text(
              'Uploading image...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageUrl != null) ...[
            // Remove button
            Container(
              decoration: BoxDecoration(
                color: TuKrasnalColors.error.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                onPressed: _removeImage,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Upload/Change button
          Container(
            decoration: BoxDecoration(
              color: TuKrasnalColors.brickRed.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: _selectImage,
              icon: Icon(
                _imageUrl != null ? Icons.edit : Icons.add,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final result = await ImagePickerBottomSheet.show(
        context,
        widget.uploadType,
      );

      if (result != null) {
        if (result.success && result.url != null) {
          setState(() {
            _imageUrl = result.url;
          });
          widget.onImageSelected(_imageUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: ${result.error ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
    widget.onImageSelected(null);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}