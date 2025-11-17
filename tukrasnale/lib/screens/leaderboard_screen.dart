import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.leaderboard),
              text: 'Global',
            ),
            Tab(
              icon: Icon(Icons.group),
              text: 'Friends',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalLeaderboard(),
          _buildFriendsLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return Column(
      children: [
        // Top 3 podium
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: _buildPodium(),
        ),
        
        // Rest of leaderboard
        Expanded(
          child: ListView.builder(
            itemCount: 20, // Mock data
            itemBuilder: (context, index) {
              return _buildLeaderboardItem(
                rank: index + 4,
                username: 'User${index + 4}',
                score: 850 - (index * 30),
                krasnaleCount: 12 - index,
                isCurrentUser: index == 5, // Mock current user at 9th place
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPodiumPlace(
          rank: 2,
          username: 'Silver_Hunter',
          score: 1450,
          height: 120,
          color: Colors.grey,
        ),
        _buildPodiumPlace(
          rank: 1,
          username: 'Krasnal_Master',
          score: 1890,
          height: 150,
          color: Colors.amber,
        ),
        _buildPodiumPlace(
          rank: 3,
          username: 'Explorer_WRO',
          score: 1200,
          height: 100,
          color: Colors.brown,
        ),
      ],
    );
  }

  Widget _buildPodiumPlace({
    required int rank,
    required String username,
    required int score,
    required double height,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String username,
    required int score,
    required int krasnaleCount,
    bool isCurrentUser = false,
  }) {
    return Container(
      color: isCurrentUser 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUser 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: Text(
            '$rank',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              username,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              const Icon(Icons.person, size: 16),
            ],
          ],
        ),
        subtitle: Text('$krasnaleCount krasnale discovered'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'points',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsLeaderboard() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Friends Feature\nComing Soon!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '👫 Add friends\n🏆 Compare scores\n🎯 Challenge each other',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}