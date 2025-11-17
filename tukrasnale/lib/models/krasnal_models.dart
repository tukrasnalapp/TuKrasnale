// Enums
enum KrasnalRarity {
  common('common'),
  rare('rare'),
  epic('epic'),
  legendary('legendary');

  const KrasnalRarity(this.value);
  final String value;

  static KrasnalRarity fromString(String value) {
    return KrasnalRarity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => KrasnalRarity.common,
    );
  }

  int get pointsMultiplier {
    switch (this) {
      case KrasnalRarity.common:
        return 1;
      case KrasnalRarity.rare:
        return 2;
      case KrasnalRarity.epic:
        return 3;
      case KrasnalRarity.legendary:
        return 5;
    }
  }
}

enum AchievementType {
  discovery('discovery'),
  collection('collection'),
  social('social'),
  exploration('exploration'),
  special('special');

  const AchievementType(this.value);
  final String value;

  static AchievementType fromString(String value) {
    return AchievementType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AchievementType.discovery,
    );
  }
}

enum AchievementRarity {
  bronze('bronze'),
  silver('silver'),
  gold('gold'),
  platinum('platinum');

  const AchievementRarity(this.value);
  final String value;

  static AchievementRarity fromString(String value) {
    return AchievementRarity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AchievementRarity.bronze,
    );
  }
}

// User model matching the database schema
class AppUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int krasnaleDiscovered;
  final int totalScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.krasnaleDiscovered = 0,
    this.totalScore = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      krasnaleDiscovered: json['krasnale_discovered'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'krasnale_discovered': krasnaleDiscovered,
      'total_score': totalScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    int? krasnaleDiscovered,
    int? totalScore,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      krasnaleDiscovered: krasnaleDiscovered ?? this.krasnaleDiscovered,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, username: $username, score: $totalScore, discovered: $krasnaleDiscovered)';
  }
}

// Krasnal model matching the database schema
class KrasnalModel {
  final String id;
  final String name;
  final String? description;
  final String? history;
  final String? locationName;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? model3dUrl;
  final KrasnalRarity rarity;
  final int discoveryRadius;
  final int pointsValue;
  final bool isActive;
  final DateTime createdAt;

  KrasnalModel({
    required this.id,
    required this.name,
    this.description,
    this.history,
    this.locationName,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.model3dUrl,
    this.rarity = KrasnalRarity.common,
    this.discoveryRadius = 30,
    this.pointsValue = 10,
    this.isActive = true,
    required this.createdAt,
  });

  factory KrasnalModel.fromJson(Map<String, dynamic> json) {
    return KrasnalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      history: json['history'] as String?,
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      model3dUrl: json['model_3d_url'] as String?,
      rarity: KrasnalRarity.fromString(json['rarity'] as String? ?? 'common'),
      discoveryRadius: json['discovery_radius'] as int? ?? 30,
      pointsValue: json['points_value'] as int? ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'history': history,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'model_3d_url': model3dUrl,
      'rarity': rarity.value,
      'discovery_radius': discoveryRadius,
      'points_value': pointsValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  KrasnalModel copyWith({
    String? name,
    String? description,
    String? history,
    String? locationName,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? model3dUrl,
    KrasnalRarity? rarity,
    int? discoveryRadius,
    int? pointsValue,
    bool? isActive,
  }) {
    return KrasnalModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      history: history ?? this.history,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      model3dUrl: model3dUrl ?? this.model3dUrl,
      rarity: rarity ?? this.rarity,
      discoveryRadius: discoveryRadius ?? this.discoveryRadius,
      pointsValue: pointsValue ?? this.pointsValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'KrasnalModel(id: $id, name: $name, rarity: ${rarity.value}, points: $pointsValue)';
  }
}

// Achievement model
class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final AchievementType type;
  final AchievementRarity rarity;
  final String requirementType;
  final int requirementValue;
  final int pointsReward;
  final bool isHidden;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.type,
    this.rarity = AchievementRarity.bronze,
    required this.requirementType,
    required this.requirementValue,
    this.pointsReward = 0,
    this.isHidden = false,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      type: AchievementType.fromString(json['type'] as String? ?? 'discovery'),
      rarity: AchievementRarity.fromString(json['rarity'] as String? ?? 'bronze'),
      requirementType: json['requirement_type'] as String,
      requirementValue: json['requirement_value'] as int,
      pointsReward: json['points_reward'] as int? ?? 0,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'type': type.value,
      'rarity': rarity.value,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'points_reward': pointsReward,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Achievement(id: $id, name: $name, type: ${type.value}, rarity: ${rarity.value})';
  }
}

// User achievement model
class UserAchievement {
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Achievement? achievement; // Optional populated achievement data

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      achievement: json['achievement'] != null 
          ? Achievement.fromJson(json['achievement'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserAchievement(userId: $userId, achievementId: $achievementId, unlockedAt: $unlockedAt)';
  }
}

// Progress tracking for achievements
class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final int requiredValue;
  final Achievement achievement;

  AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.requiredValue,
    required this.achievement,
  });

  double get progressPercentage => 
      currentValue >= requiredValue ? 1.0 : currentValue / requiredValue;

  bool get isCompleted => currentValue >= requiredValue;

  int get remainingValue => requiredValue - currentValue;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievement_id'] as String,
      currentValue: json['current_value'] as int,
      requiredValue: json['required_value'] as int,
      achievement: Achievement.fromJson(json['achievement'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() {
    return 'AchievementProgress(achievementId: $achievementId, progress: $currentValue/$requiredValue)';
  }
}

// User discovery model
class UserDiscovery {
  final String id;
  final String userId;
  final String krasnalId;
  final DateTime discoveredAt;
  final double? discoveryLocationLat;
  final double? discoveryLocationLng;

  UserDiscovery({
    required this.id,
    required this.userId,
    required this.krasnalId,
    required this.discoveredAt,
    this.discoveryLocationLat,
    this.discoveryLocationLng,
  });

  factory UserDiscovery.fromJson(Map<String, dynamic> json) {
    return UserDiscovery(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      krasnalId: json['krasnal_id'] as String,
      discoveredAt: DateTime.parse(json['discovered_at'] as String),
      discoveryLocationLat: (json['discovery_location_lat'] as num?)?.toDouble(),
      discoveryLocationLng: (json['discovery_location_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'krasnal_id': krasnalId,
      'discovered_at': discoveredAt.toIso8601String(),
      'discovery_location_lat': discoveryLocationLat,
      'discovery_location_lng': discoveryLocationLng,
    };
  }

  UserDiscovery copyWith({
    String? userId,
    String? krasnalId,
    DateTime? discoveredAt,
    double? discoveryLocationLat,
    double? discoveryLocationLng,
  }) {
    return UserDiscovery(
      id: id,
      userId: userId ?? this.userId,
      krasnalId: krasnalId ?? this.krasnalId,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      discoveryLocationLat: discoveryLocationLat ?? this.discoveryLocationLat,
      discoveryLocationLng: discoveryLocationLng ?? this.discoveryLocationLng,
    );
  }

  @override
  String toString() {
    return 'UserDiscovery(id: $id, krasnalId: $krasnalId, discoveredAt: $discoveredAt)';
  }
}

// Leaderboard entry model
class LeaderboardEntry {
  final String username;
  final String? displayName;
  final int krasnaleDiscovered;
  final int totalScore;
  final int rank;

  LeaderboardEntry({
    required this.username,
    this.displayName,
    required this.krasnaleDiscovered,
    required this.totalScore,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      krasnaleDiscovered: json['krasnale_discovered'] as int,
      totalScore: json['total_score'] as int,
      rank: json['rank'] as int,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, username: $username, score: $totalScore)';
  }
}

// Discovery result model for GPS checking
class DiscoveryResult {
  final bool canDiscover;
  final double distance;
  final KrasnalModel krasnal;
  final String? reason;

  DiscoveryResult({
    required this.canDiscover,
    required this.distance,
    required this.krasnal,
    this.reason,
  });

  bool get isInRange => distance <= krasnal.discoveryRadius;
  
  @override
  String toString() {
    return 'DiscoveryResult(canDiscover: $canDiscover, distance: ${distance.toStringAsFixed(1)}m, krasnal: ${krasnal.name})';
  }
}