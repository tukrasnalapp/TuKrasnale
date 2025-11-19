// Comprehensive Krasnal Models
// This file contains all Krasnal-related models and enums

enum KrasnalCategory {
  historical,
  cultural,
  artistic,
  memorial,
  entertainment,
  other,
}

enum KrasnalStatus {
  active,
  inactive,
  maintenance,
  removed,
}

enum KrasnalRarity {
  common,
  rare,
  epic,
  legendary,
}

class KrasnalLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? district;

  const KrasnalLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.district,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'district': district,
    };
  }

  factory KrasnalLocation.fromMap(Map<String, dynamic> map) {
    return KrasnalLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      district: map['district'],
    );
  }

  KrasnalLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? district,
  }) {
    return KrasnalLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      district: district ?? this.district,
    );
  }
}

class KrasnalImage {
  final String id;
  final String url;
  final String? caption;
  final bool isPrimary;
  final DateTime uploadedAt;

  const KrasnalImage({
    required this.id,
    required this.url,
    this.caption,
    this.isPrimary = false,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'caption': caption,
      'isPrimary': isPrimary,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory KrasnalImage.fromMap(Map<String, dynamic> map) {
    return KrasnalImage(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      caption: map['caption'],
      isPrimary: map['isPrimary'] ?? false,
      uploadedAt: DateTime.parse(map['uploadedAt']),
    );
  }

  KrasnalImage copyWith({
    String? id,
    String? url,
    String? caption,
    bool? isPrimary,
    DateTime? uploadedAt,
  }) {
    return KrasnalImage(
      id: id ?? this.id,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      isPrimary: isPrimary ?? this.isPrimary,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class Krasnal {
  final String id;
  final String name;
  final String description;
  final KrasnalLocation location;
  final List<KrasnalImage> images;
  final KrasnalCategory category;
  final KrasnalStatus status;
  final bool isVisited;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? author;
  final String? sculptor;
  final int? yearCreated;
  final Map<String, dynamic>? metadata;

  const Krasnal({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.images = const [],
    this.category = KrasnalCategory.other,
    this.status = KrasnalStatus.active,
    this.isVisited = false,
    required this.createdAt,
    this.updatedAt,
    this.author,
    this.sculptor,
    this.yearCreated,
    this.metadata,
  });

  // Legacy constructor for backward compatibility
  factory Krasnal.legacy({
    required String id,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required List<String> images,
    required bool isVisited,
    required DateTime createdAt,
  }) {
    return Krasnal(
      id: id,
      name: name,
      description: description,
      location: KrasnalLocation(latitude: latitude, longitude: longitude),
      images: images.asMap().entries.map((entry) {
        return KrasnalImage(
          id: '${id}_img_${entry.key}',
          url: entry.value,
          uploadedAt: createdAt,
          isPrimary: entry.key == 0,
        );
      }).toList(),
      isVisited: isVisited,
      createdAt: createdAt,
    );
  }

  // Legacy getters for backward compatibility
  double get latitude => location.latitude;
  double get longitude => location.longitude;
  List<String> get imageUrls => images.map((img) => img.url).toList();
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((img) => img.isPrimary);
    return primary.isNotEmpty ? primary.first.url : images.first.url;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location.toMap(),
      'images': images.map((img) => img.toMap()).toList(),
      'category': category.name,
      'status': status.name,
      'isVisited': isVisited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'author': author,
      'sculptor': sculptor,
      'yearCreated': yearCreated,
      'metadata': metadata,
    };
  }

  // Legacy toMap for backward compatibility
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'images': imageUrls,
      'isVisited': isVisited,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Krasnal.fromMap(Map<String, dynamic> map) {
    return Krasnal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] != null 
        ? KrasnalLocation.fromMap(map['location'])
        : KrasnalLocation(
            latitude: map['latitude']?.toDouble() ?? 0.0,
            longitude: map['longitude']?.toDouble() ?? 0.0,
          ),
      images: map['images'] != null
        ? (map['images'] as List).map((img) {
            if (img is String) {
              // Legacy support for string URLs
              return KrasnalImage(
                id: '${map['id']}_img_${map['images'].indexOf(img)}',
                url: img,
                uploadedAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
                isPrimary: map['images'].indexOf(img) == 0,
              );
            } else {
              return KrasnalImage.fromMap(img);
            }
          }).toList()
        : [],
      category: KrasnalCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => KrasnalCategory.other,
      ),
      status: KrasnalStatus.values.firstWhere(
        (stat) => stat.name == map['status'],
        orElse: () => KrasnalStatus.active,
      ),
      isVisited: map['isVisited'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      author: map['author'],
      sculptor: map['sculptor'],
      yearCreated: map['yearCreated'],
      metadata: map['metadata'],
    );
  }

  Krasnal copyWith({
    String? id,
    String? name,
    String? description,
    KrasnalLocation? location,
    List<KrasnalImage>? images,
    KrasnalCategory? category,
    KrasnalStatus? status,
    bool? isVisited,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? author,
    String? sculptor,
    int? yearCreated,
    Map<String, dynamic>? metadata,
  }) {
    return Krasnal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      images: images ?? this.images,
      category: category ?? this.category,
      status: status ?? this.status,
      isVisited: isVisited ?? this.isVisited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      sculptor: sculptor ?? this.sculptor,
      yearCreated: yearCreated ?? this.yearCreated,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Krasnal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Krasnal(id: $id, name: $name, location: ${location.latitude}, ${location.longitude})';
  }
}

// Extensions for additional functionality
extension KrasnalExtensions on Krasnal {
  bool get hasImages => images.isNotEmpty;
  bool get hasLocation => location.latitude != 0.0 && location.longitude != 0.0;
  bool get isActive => status == KrasnalStatus.active;
  
  String get categoryDisplayName {
    switch (category) {
      case KrasnalCategory.historical:
        return 'Historical';
      case KrasnalCategory.cultural:
        return 'Cultural';
      case KrasnalCategory.artistic:
        return 'Artistic';
      case KrasnalCategory.memorial:
        return 'Memorial';
      case KrasnalCategory.entertainment:
        return 'Entertainment';
      case KrasnalCategory.other:
        return 'Other';
    }
  }
  
  String get statusDisplayName {
    switch (status) {
      case KrasnalStatus.active:
        return 'Active';
      case KrasnalStatus.inactive:
        return 'Inactive';
      case KrasnalStatus.maintenance:
        return 'Under Maintenance';
      case KrasnalStatus.removed:
        return 'Removed';
    }
  }
}

// Search and filtering models
class KrasnalSearchCriteria {
  final String? name;
  final KrasnalCategory? category;
  final KrasnalStatus? status;
  final double? nearLatitude;
  final double? nearLongitude;
  final double? radiusKm;
  final bool? onlyVisited;
  final bool? onlyUnvisited;

  const KrasnalSearchCriteria({
    this.name,
    this.category,
    this.status,
    this.nearLatitude,
    this.nearLongitude,
    this.radiusKm,
    this.onlyVisited,
    this.onlyUnvisited,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category?.name,
      'status': status?.name,
      'nearLatitude': nearLatitude,
      'nearLongitude': nearLongitude,
      'radiusKm': radiusKm,
      'onlyVisited': onlyVisited,
      'onlyUnvisited': onlyUnvisited,
    };
  }
}

// User discovery model for tracking discovered krasnale
class UserDiscovery {
  final String id;
  final String userId;
  final String krasnalId;
  final DateTime discoveredAt;
  final double userLatitude;
  final double userLongitude;
  final double? distance;
  final Map<String, dynamic>? metadata;

  const UserDiscovery({
    required this.id,
    required this.userId,
    required this.krasnalId,
    required this.discoveredAt,
    required this.userLatitude,
    required this.userLongitude,
    this.distance,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'krasnalId': krasnalId,
      'discoveredAt': discoveredAt.toIso8601String(),
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'distance': distance,
      'metadata': metadata,
    };
  }

  factory UserDiscovery.fromMap(Map<String, dynamic> map) {
    return UserDiscovery(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      krasnalId: map['krasnalId'] ?? map['krasnal_id'] ?? '',
      discoveredAt: DateTime.parse(map['discoveredAt'] ?? map['discovered_at'] ?? DateTime.now().toIso8601String()),
      userLatitude: map['userLatitude']?.toDouble() ?? map['user_latitude']?.toDouble() ?? 0.0,
      userLongitude: map['userLongitude']?.toDouble() ?? map['user_longitude']?.toDouble() ?? 0.0,
      distance: map['distance']?.toDouble(),
      metadata: map['metadata'],
    );
  }
}

// Discovery attempt result model
class DiscoveryResult {
  final bool canDiscover;
  final double distance;
  final Krasnal krasnal;
  final String? reason;

  const DiscoveryResult({
    required this.canDiscover,
    required this.distance,
    required this.krasnal,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'canDiscover': canDiscover,
      'distance': distance,
      'krasnal': krasnal.toMap(),
      'reason': reason,
    };
  }
}