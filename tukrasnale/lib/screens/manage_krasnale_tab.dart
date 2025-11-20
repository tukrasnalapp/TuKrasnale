import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/krasnal_models.dart';

import 'krasnal_detail_screen.dart';
import 'edit_krasnal_screen.dart';

class ManageKrasnaleTab extends StatefulWidget {
  const ManageKrasnaleTab({super.key});

  @override
  State<ManageKrasnaleTab> createState() => _ManageKrasnaleTabState();
}

class _ManageKrasnaleTabState extends State<ManageKrasnaleTab> {
  final AdminService _adminService = AdminService();
  List<Krasnal> _krasnale = [];
  bool _isLoading = true;
  String _searchQuery = '';
  KrasnalRarity? _selectedRarity;

  @override
  void initState() {
    super.initState();
    _loadKrasnale();
  }

  Future<void> _loadKrasnale() async {
    print('🔄 Loading krasnale...');
    setState(() {
      _isLoading = true;
    });

    try {
      final krasnale = await _adminService.getAllKrasnaleForAdmin();
      if (mounted) {
        setState(() {
          _krasnale = krasnale;
          _isLoading = false;
        });
        print('✅ Loaded ${_krasnale.length} krasnale');
      }
    } catch (e) {
      print('❌ Error loading krasnale: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load krasnale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Krasnal> get _filteredKrasnale {
    return _krasnale.where((krasnal) {
      final matchesSearch = _searchQuery.isEmpty ||
          krasnal.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          krasnal.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (krasnal.location.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Get rarity from metadata
      KrasnalRarity krasnalRarity = KrasnalRarity.common;
      if (krasnal.metadata != null && krasnal.metadata!['rarity'] != null) {
        final rarityString = krasnal.metadata!['rarity'] as String;
        krasnalRarity = KrasnalRarity.values.firstWhere(
          (r) => r.name == rarityString,
          orElse: () => KrasnalRarity.common,
        );
      }
      
      final matchesRarity = _selectedRarity == null || krasnalRarity == _selectedRarity;

      return matchesSearch && matchesRarity;
    }).toList();
  }

  Future<void> _deleteKrasnal(Krasnal krasnal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Krasnal'),
        content: Text('Are you sure you want to delete "${krasnal.name}"? This action cannot be undone.'),
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
      print('🔄 Deleting krasnal: ${krasnal.name}');
      try {
        // Use enhanced deletion that removes both record and images
        final success = await _adminService.deleteKrasnalWithImages(krasnal.id);
        if (mounted && success) {
          print('✅ Krasnal deleted successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Krasnal and images deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadKrasnale(); // Refresh the list
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete krasnal'),
              backgroundColor: Colors.red,
            ),
          );
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
      }
    }
  }

  Future<void> _viewKrasnal(Krasnal krasnal) async {
    print('👀 Viewing krasnal: ${krasnal.name}');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KrasnalDetailScreen(krasnal: krasnal),
      ),
    );
    
    // Refresh if any changes were made
    if (result == true) {
      await _loadKrasnale();
    }
  }

  Future<void> _editKrasnal(Krasnal krasnal) async {
    print('✏️ Editing krasnal: ${krasnal.name}');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditKrasnalScreen(krasnal: krasnal),
      ),
    );
    
    // Refresh if any changes were made
    if (result == true) {
      await _loadKrasnale();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header with search and filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title and count
                Row(
                  children: [
                    Text(
                      'Manage Krasnale',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[700]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_filteredKrasnale.length} krasnale',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name, description, or location...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Rarity filter and refresh button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<KrasnalRarity?>(
                        value: _selectedRarity,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Rarity',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<KrasnalRarity?>(
                            value: null,
                            child: Text('All Rarities'),
                          ),
                          ...KrasnalRarity.values.map((rarity) {
                            return DropdownMenuItem<KrasnalRarity?>(
                              value: rarity,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getRarityColor(rarity),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(rarity.name.toUpperCase()),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRarity = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadKrasnale,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Krasnale list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredKrasnale.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedRarity != null
                                  ? 'No krasnale match your search criteria'
                                  : 'No krasnale found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredKrasnale.length,
                        itemBuilder: (context, index) {
                          final krasnal = _filteredKrasnale[index];
                          return _buildKrasnalCard(krasnal);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKrasnalCard(Krasnal krasnal) {
    // Get rarity from metadata
    KrasnalRarity krasnalRarity = KrasnalRarity.common;
    if (krasnal.metadata != null && krasnal.metadata!['rarity'] != null) {
      final rarityString = krasnal.metadata!['rarity'] as String;
      krasnalRarity = KrasnalRarity.values.firstWhere(
        (r) => r.name == rarityString,
        orElse: () => KrasnalRarity.common,
      );
    }

    // Get points value from metadata
    int pointsValue = 10;
    if (krasnal.metadata != null && krasnal.metadata!['pointsValue'] != null) {
      pointsValue = krasnal.metadata!['pointsValue'] as int;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Krasnal image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildKrasnalThumbnail(krasnal),
              ),
            ),
            const SizedBox(width: 12),
            
            // Krasnal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rarity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          krasnal.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRarityColor(krasnalRarity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getRarityColor(krasnalRarity)),
                        ),
                        child: Text(
                          krasnalRarity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getRarityColor(krasnalRarity),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  if (krasnal.description.isNotEmpty)
                    Text(
                      krasnal.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  
                  // Location and points
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          krasnal.location.address ?? '${krasnal.latitude}, ${krasnal.longitude}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pointsValue pts',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Action buttons
            Column(
              children: [
                IconButton(
                  onPressed: () => _viewKrasnal(krasnal),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View Details',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => _editKrasnal(krasnal),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => _deleteKrasnal(krasnal),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildKrasnalThumbnail(Krasnal krasnal) {
    // Check if we have a valid image URL
    if (krasnal.primaryImageUrl == null || krasnal.primaryImageUrl!.isEmpty) {
      return _buildImagePlaceholder();
    }

    final imageUrl = krasnal.primaryImageUrl!;
    
    // For Supabase URLs (should start with http)
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red[700],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Failed to load thumbnail: $imageUrl');
          return _buildImagePlaceholder();
        },
      );
    } else {
      // Log warning for non-HTTP URLs
      print('⚠️ Non-HTTP image URL detected: $imageUrl');
      return _buildImagePlaceholder();
    }
  }
}