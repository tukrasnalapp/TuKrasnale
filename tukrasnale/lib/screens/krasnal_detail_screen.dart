import 'package:flutter/material.dart';
import '../models/krasnal_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../services/admin_service.dart';
import 'edit_krasnal_screen.dart';


class KrasnalDetailScreen extends StatefulWidget {
  final Krasnal krasnal;

  const KrasnalDetailScreen({
    super.key,
    required this.krasnal,
  });

  @override
  State<KrasnalDetailScreen> createState() => _KrasnalDetailScreenState();
}

class _KrasnalDetailScreenState extends State<KrasnalDetailScreen> {
  final AdminService _adminService = AdminService();
  bool _isDeleting = false;

  Color _getRarityColor(KrasnalRarity rarity) {
    switch (rarity) {
      case KrasnalRarity.common:
        return Colors.grey;
      case KrasnalRarity.rare:
        return Colors.blue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
  }

  // Helper method to get rarity from metadata
  KrasnalRarity get _krasnalRarityValue {
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['rarity'] != null) {
      final rarityString = widget.krasnal.metadata!['rarity'] as String;
      return KrasnalRarity.values.firstWhere(
        (r) => r.name == rarityString,
        orElse: () => KrasnalRarity.common,
      );
    }
    return KrasnalRarity.common;
  }

  // Helper method to get points value from metadata
  int get _krasnalPointsValue {
    if (widget.krasnal.metadata != null && widget.krasnal.metadata!['pointsValue'] != null) {
      return widget.krasnal.metadata!['pointsValue'] as int;
    }
    return 10; // Default value
  }

  Widget _buildMainImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: widget.krasnal.primaryImageUrl != null && widget.krasnal.primaryImageUrl!.isNotEmpty
                    ? widget.krasnal.primaryImageUrl!.startsWith('http')
                        ? Image.network(
                            widget.krasnal.primaryImageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImageError();
                            },
                          )
                        : !kIsWeb
                            ? Image.file(
                                File(widget.krasnal.primaryImageUrl!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImageError();
                                },
                              )
                            : _buildImageError()
                    : _buildImagePlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteKrasnal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Krasnal'),
        content: Text('Are you sure you want to delete "${widget.krasnal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        print('🔄 Deleting krasnal: ${widget.krasnal.name}');
        await _adminService.deleteKrasnal(widget.krasnal.id);
        
        if (mounted) {
          print('✅ Krasnal deleted successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Krasnal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('❌ Error deleting krasnal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting krasnal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _editKrasnal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditKrasnalScreen(krasnal: widget.krasnal),
      ),
    );
    
    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.white, size: 48),
                            SizedBox(height: 16),
                            Text('Failed to load image', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.krasnal.name),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _editKrasnal,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: _isDeleting ? null : _deleteKrasnal,
            icon: _isDeleting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main image section
              _buildMainImageSection(),
              const SizedBox(height: 24),
              
              // Basic information
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              // Location information
              _buildLocationSection(),
              const SizedBox(height: 24),
              
              // Game properties
              _buildGamePropertiesSection(),
              const SizedBox(height: 24),
              
              // Medallion images section
              _buildMedallionSection(),
              const SizedBox(height: 24),
              
              // Gallery images section
              _buildGallerySection(),
              const SizedBox(height: 24),
              
              // Note about additional images
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Multi-Image Support',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This krasnal supports multiple image types:\n'
                        '• Main Image: Primary display image\n'
                        '• Medallion Images: Undiscovered and discovered states\n'
                        '• Gallery Images: Additional photos\n\n'
                        'Images are categorized based on their URL patterns and displayed in the appropriate sections above.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Name', widget.krasnal.name),
          
          if (widget.krasnal.description.isNotEmpty)
            _buildInfoRow('Description', widget.krasnal.description),
          
          _buildInfoRow(
            'Created', 
            '${widget.krasnal.createdAt.day}/${widget.krasnal.createdAt.month}/${widget.krasnal.createdAt.year}'
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          if (widget.krasnal.location.address?.isNotEmpty == true)
            _buildInfoRow('Location Name', widget.krasnal.location.address!),
          
          _buildInfoRow('Latitude', widget.krasnal.latitude.toString()),
          _buildInfoRow('Longitude', widget.krasnal.longitude.toString()),
          
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening in maps... (not implemented yet)')),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildGamePropertiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Game Properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Text(
                'Rarity: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRarityColor(_krasnalRarityValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getRarityColor(_krasnalRarityValue)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRarityColor(_krasnalRarityValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _krasnalRarityValue.name.toUpperCase(),
                      style: TextStyle(
                        color: _getRarityColor(_krasnalRarityValue),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Points Value', '$_krasnalPointsValue points'),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.red[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedallionSection() {
    // Filter medallion images from the images array based on URL patterns
    // Since KrasnalImage doesn't have metadata, we'll look for specific patterns
    final undiscoveredMedallion = widget.krasnal.images
        .where((img) => img.url.contains('medallion_undiscovered') || 
                       img.url.contains('medallions') && img.url.contains('undiscovered'))
        .firstOrNull;
    
    final discoveredMedallion = widget.krasnal.images
        .where((img) => img.url.contains('medallion_discovered') || 
                       img.url.contains('medallions') && img.url.contains('discovered'))
        .firstOrNull;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medallion Images',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            if (undiscoveredMedallion != null || discoveredMedallion != null) ...[
              Row(
                children: [
                  if (undiscoveredMedallion != null) ...[
                    Expanded(
                      child: _buildMedallionImage('Undiscovered', undiscoveredMedallion.url),
                    ),
                    if (discoveredMedallion != null) const SizedBox(width: 16),
                  ],
                  if (discoveredMedallion != null) ...[
                    Expanded(
                      child: _buildMedallionImage('Discovered', discoveredMedallion.url),
                    ),
                  ],
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Medallion Images',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Medallion images can be added when editing this krasnal.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedallionImage(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageError();
                    },
                  )
                : _buildImageError(),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    // Filter gallery images: exclude primary image and medallion images
    final galleryImages = widget.krasnal.images.where((img) {
      // Skip primary image (usually the first one)
      if (widget.krasnal.primaryImageUrl != null && img.url == widget.krasnal.primaryImageUrl) {
        return false;
      }
      
      // Skip medallion images
      if (img.url.contains('medallion_undiscovered') || 
          img.url.contains('medallion_discovered') ||
          (img.url.contains('medallions') && (img.url.contains('undiscovered') || img.url.contains('discovered')))) {
        return false;
      }
      
      // Include gallery images (either explicitly named or remaining images)
      return true;
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(
                'Gallery Images',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (galleryImages.isNotEmpty)
                Text(
                  '${galleryImages.length} image${galleryImages.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Display gallery images if they exist
          if (galleryImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: galleryImages.length,
              itemBuilder: (context, index) {
                final krasnalImage = galleryImages[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: krasnalImage.url.startsWith('http')
                        ? GestureDetector(
                            onTap: () => _showFullScreenImage(krasnalImage.url),
                            child: Image.network(
                              krasnalImage.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 24),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 24),
                            ),
                          ),
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Gallery Images',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gallery images can be added when editing this krasnal.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}