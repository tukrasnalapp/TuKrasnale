import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/krasnal_models.dart';
import '../services/admin_service.dart';
import 'edit_krasnal_screen.dart';

class KrasnalDetailScreen extends StatefulWidget {
  final KrasnalModel krasnal;

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
        return TuKrasnalColors.textLight;
      case KrasnalRarity.rare:
        return TuKrasnalColors.skyBlue;
      case KrasnalRarity.epic:
        return Colors.purple;
      case KrasnalRarity.legendary:
        return Colors.amber;
    }
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
          Navigator.of(context).pop(true); // Return true to indicate changes
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
      // Return true to indicate changes were made
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.krasnal.name),
        backgroundColor: TuKrasnalColors.background,
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: Container(
        color: TuKrasnalColors.background,
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
              
              // TODO: Add medallion and gallery images when KrasnalModel supports them
              // Medallion images
              // if (widget.krasnal.undiscoveredMedallionUrl != null || 
              //     widget.krasnal.discoveredMedallionUrl != null) ...[
              //   _buildMedallionSection(),
              //   const SizedBox(height: 24),
              // ],
              
              // Gallery images  
              // if (widget.krasnal.galleryImages?.isNotEmpty == true) ...[
              //   _buildGallerySection(),
              //   const SizedBox(height: 24),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImageSection() {
    return TuKrasnalCard(
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
              border: Border.all(color: TuKrasnalColors.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: widget.krasnal.imageUrl != null && widget.krasnal.imageUrl!.isNotEmpty
                  ? widget.krasnal.imageUrl!.startsWith('http')
                      ? Image.network(
                          widget.krasnal.imageUrl!,
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
                              File(widget.krasnal.imageUrl!),
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
    );
  }

  Widget _buildBasicInfoSection() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Name
          _buildInfoRow('Name', widget.krasnal.name),
          
          // Description
          if (widget.krasnal.description?.isNotEmpty == true)
            _buildInfoRow('Description', widget.krasnal.description!),
          
          // Created date
          _buildInfoRow(
            'Created', 
            '${widget.krasnal.createdAt.day}/${widget.krasnal.createdAt.month}/${widget.krasnal.createdAt.year}'
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          if (widget.krasnal.locationName?.isNotEmpty == true)
            _buildInfoRow('Location Name', widget.krasnal.locationName!),
          
          _buildInfoRow('Latitude', widget.krasnal.latitude.toString()),
          _buildInfoRow('Longitude', widget.krasnal.longitude.toString()),
          
          const SizedBox(height: 12),
          TuKrasnalButton(
            text: 'Open in Maps',
            icon: Icons.map,
            isSecondary: true,
            onPressed: () {
              // TODO: Implement opening in maps
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening in maps... (not implemented yet)')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGamePropertiesSection() {
    return TuKrasnalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Rarity with colored indicator
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
                  color: _getRarityColor(widget.krasnal.rarity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getRarityColor(widget.krasnal.rarity)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRarityColor(widget.krasnal.rarity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.krasnal.rarity.name.toUpperCase(),
                      style: TextStyle(
                        color: _getRarityColor(widget.krasnal.rarity),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Points value
          _buildInfoRow('Points Value', '${widget.krasnal.pointsValue} points'),
        ],
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
}