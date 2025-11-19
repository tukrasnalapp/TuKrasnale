import 'package:flutter/material.dart';
import '../models/krasnal_models.dart';
import '../services/admin_service.dart';

// 🎯 ENHANCED MANAGE KRASNALE TAB WITH COMPLETE IMAGE SUPPORT
// This version uses AdminServiceComplete to fetch all image data
class EnhancedManageKrasnaleTab extends StatefulWidget {
  const EnhancedManageKrasnaleTab({super.key});

  @override
  State<EnhancedManageKrasnaleTab> createState() => _EnhancedManageKrasnaleTabState();
}

class _EnhancedManageKrasnaleTabState extends State<EnhancedManageKrasnaleTab> {
  final AdminService _adminService = AdminService();
  List<Krasnal> _krasnale = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKrasnale();
  }

  Future<void> _loadKrasnale() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading krasnale...');
      final krasnale = await _adminService.getAllKrasnale();
      
      setState(() {
        _krasnale = krasnale;
        _isLoading = false;
      });
      
      print('✅ Loaded ${krasnale.length} krasnale');
    } catch (e) {
      print('❌ Error loading krasnale: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteKrasnal(String id) async {
    try {
      await _adminService.deleteKrasnal(id);
      await _loadKrasnale(); // Reload the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Krasnal deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting krasnal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToDetail(Krasnal krasnal) async {
    print('🔄 Navigating to detail screen...');
    print('📊 Image data: images=${krasnal.images.length}');
    
    // TODO: Implement proper detail screen navigation
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(krasnal.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${krasnal.description}'),
            Text('Location: ${krasnal.location.address ?? 'No address'}'),
            Text('Coordinates: ${krasnal.latitude.toStringAsFixed(4)}, ${krasnal.longitude.toStringAsFixed(4)}'),
            Text('Images: ${krasnal.images.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[100],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _krasnale.isEmpty
                ? _buildEmptyState()
                : _buildKrasnaleList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Krasnale Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first krasnal using the Add tab',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKrasnaleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _krasnale.length,
      itemBuilder: (context, index) {
        final krasnal = _krasnale[index];
        return _buildKrasnalCard(krasnal);
      },
    );
  }

  Widget _buildKrasnalCard(Krasnal krasnal) {
    // Check if has additional images from metadata
    final hasAdditionalImages = krasnal.images.length > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToDetail(krasnal),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: krasnal.primaryImageUrl != null && krasnal.primaryImageUrl!.isNotEmpty
                      ? Image.network(
                          krasnal.primaryImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            krasnal.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        // Image indicators (simplified for now)
                        if (hasAdditionalImages) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 16,
                                color: Colors.blue,
                              ),
                              Text(
                                '${krasnal.images.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (krasnal.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        krasnal.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            krasnal.location.address ?? '${krasnal.latitude.toStringAsFixed(4)}, ${krasnal.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                onPressed: () => _deleteKrasnal(krasnal.id),
                icon: const Icon(Icons.delete),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}