import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/krasnal_models.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Common', 'Rare', 'Epic', 'Legendary'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters
                .map((filter) => PopupMenuItem(
                      value: filter,
                      child: Row(
                        children: [
                          if (filter == _selectedFilter)
                            const Icon(Icons.check, size: 16),
                          if (filter != _selectedFilter)
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(filter),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      icon: Icons.collections,
                      label: 'Discovered',
                      value: '0', // TODO: Get from user data
                    ),
                    _buildStatCard(
                      icon: Icons.stars,
                      label: 'Total Points',
                      value: '0', // TODO: Get from user data
                    ),
                    _buildStatCard(
                      icon: Icons.emoji_events,
                      label: 'Achievements',
                      value: '0', // TODO: Get from user data
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Collection grid
          Expanded(
            child: _buildCollectionGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionGrid() {
    // TODO: Replace with actual discovered krasnale data
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 6, // Placeholder count
      itemBuilder: (context, index) {
        return _buildKrasnalCard(index);
      },
    );
  }

  Widget _buildKrasnalCard(int index) {
    final bool isDiscovered = index < 2; // Mock data - first 2 discovered
    
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDiscovered ? () => _showKrasnalDetail(index) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: isDiscovered 
                    ? Colors.blue[50] 
                    : Colors.grey[300],
                child: isDiscovered
                    ? const Icon(
                        Icons.account_box,
                        size: 60,
                        color: Colors.blue,
                      )
                    : const Icon(
                        Icons.help_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDiscovered ? 'Krasnal ${index + 1}' : '???',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: isDiscovered ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDiscovered ? 'Rare' : 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKrasnalDetail(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Krasnal ${index + 1}'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_box, size: 80, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'This is a detailed view of your discovered krasnal.\n\nFuture features:\n• 3D model viewer\n• History and story\n• Discovery location\n• Share with friends',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Share functionality
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }
}