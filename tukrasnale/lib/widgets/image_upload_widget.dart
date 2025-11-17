import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import 'image_picker_bottom_sheet.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final ImageUploadType uploadType;
  final Function(String?) onImageSelected;
  final String title;
  final double? width;
  final double? height;
  final bool required;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrl,
    required this.uploadType,
    required this.onImageSelected,
    required this.title,
    this.width = 120,
    this.height = 120,
    this.required = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _currentImageUrl;
  bool _isUploading = false;
  final ImageUploadService _uploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Image Preview Container
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: _buildContent(),
        ),
        
        const SizedBox(height: 8),
        
        // Action Buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _selectImage,
              icon: _isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 16),
              label: Text(_currentImageUrl == null ? 'Upload' : 'Replace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            
            if (_currentImageUrl != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isUploading ? null : _removeImage,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Uploading...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_currentImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _currentImageUrl!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(height: 4),
                  Text('Failed to load', style: TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await ImagePickerBottomSheet.show(
        context,
        widget.uploadType,
      );

      if (result != null) {
        if (result.success && result.url != null) {
          // Delete old image if exists
          if (_currentImageUrl != null) {
            _uploadService.deleteImage(_currentImageUrl!);
          }
          
          setState(() {
            _currentImageUrl = result.url;
          });
          widget.onImageSelected(result.url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: ${result.error}'),
                backgroundColor: Colors.red,
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
    // Delete from storage
    if (_currentImageUrl != null) {
      _uploadService.deleteImage(_currentImageUrl!);
    }
    
    setState(() {
      _currentImageUrl = null;
    });
    widget.onImageSelected(null);
  }
}

class MultipleImageUploadWidget extends StatefulWidget {
  final List<String> initialImageUrls;
  final ImageUploadType uploadType;
  final Function(List<String>) onImagesChanged;
  final String title;
  final int maxImages;

  const MultipleImageUploadWidget({
    super.key,
    this.initialImageUrls = const [],
    required this.uploadType,
    required this.onImagesChanged,
    required this.title,
    this.maxImages = 5,
  });

  @override
  State<MultipleImageUploadWidget> createState() => _MultipleImageUploadWidgetState();
}

class _MultipleImageUploadWidgetState extends State<MultipleImageUploadWidget> {
  List<String> _imageUrls = [];
  bool _isUploading = false;
  final ImageUploadService _uploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${_imageUrls.length}/${widget.maxImages})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Images Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Existing images
            ..._imageUrls.map((url) => _buildImageTile(url)),
            
            // Add button (if under limit)
            if (_imageUrls.length < widget.maxImages)
              _buildAddImageTile(),
          ],
        ),
        
        if (_isUploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          const Text('Uploading images...', style: TextStyle(fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildImageTile(String imageUrl) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 20),
                );
              },
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(imageUrl),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _isUploading ? null : _addImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 24,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addImages() async {
    if (_imageUrls.length >= widget.maxImages) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Show picker bottom sheet
      final result = await ImagePickerBottomSheet.show(
        context,
        widget.uploadType,
        allowMultiple: true,
      );
      
      if (result != null && result.success && result.url != null) {
        setState(() {
          if (_imageUrls.length < widget.maxImages) {
            _imageUrls.add(result.url!);
          }
        });
        widget.onImagesChanged(_imageUrls);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (result != null && !result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
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

  void _removeImage(String imageUrl) {
    // Delete from storage
    _uploadService.deleteImage(imageUrl);
    
    setState(() {
      _imageUrls.remove(imageUrl);
    });
    widget.onImagesChanged(_imageUrls);
  }
}