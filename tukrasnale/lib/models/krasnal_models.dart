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
  final String? history;                    // NEW: from database schema
  final KrasnalLocation location;
  final String? primaryImageUrl;            // Maps to image_url in DB
  final String? model3dUrl;                 // NEW: from database schema
  final KrasnalRarity rarity;              // From database schema
  final int discoveryRadius;               // NEW: from database schema
  final int pointsValue;                   // From database schema (points_value)
  final bool isActive;                     // NEW: from database schema
  final DateTime createdAt;
  final String? undiscoveredMedallionUrl;  // NEW: direct field from DB
  final String? discoveredMedallionUrl;    // NEW: direct field from DB
  final List<String> galleryImages;       // NEW: JSON array from DB
  final List<KrasnalImage> images;         // For compatibility with existing code
  final Map<String, dynamic>? metadata;    // Keep for compatibility

  // Legacy fields for backward compatibility
  final KrasnalCategory category;
  final KrasnalStatus status;
  final bool isVisited;
  final DateTime? updatedAt;
  final String? author;
  final String? sculptor;
  final int? yearCreated;

  const Krasnal({
    required this.id,
    required this.name,
    required this.description,
    this.history,
    required this.location,
    this.primaryImageUrl,
    this.model3dUrl,
    required this.rarity,
    required this.discoveryRadius,
    required this.pointsValue,
    required this.isActive,
    required this.createdAt,
    this.undiscoveredMedallionUrl,
    this.discoveredMedallionUrl,
    required this.galleryImages,
    required this.images,
    this.metadata,
    // Legacy fields with defaults
    this.category = KrasnalCategory.other,
    this.status = KrasnalStatus.active,
    this.isVisited = false,
    this.updatedAt,
    this.author,
    this.sculptor,
    this.yearCreated,
  });

  // Convenience getters for backwards compatibility
  double get latitude => location.latitude;
  double get longitude => location.longitude;
  List<String> get imageUrls => images.map((img) => img.url).toList();

  factory Krasnal.fromJson(Map<String, dynamic> json) {
    // Parse rarity from string
    KrasnalRarity rarity = KrasnalRarity.common;
    if (json['rarity'] != null) {
      final rarityString = json['rarity'] as String;
      rarity = KrasnalRarity.values.firstWhere(
        (r) => r.name == rarityString,
        orElse: () => KrasnalRarity.common,
      );
    }

    // Parse gallery images from JSON array string
    List<String> galleryImages = [];
    if (json['gallery_images'] != null) {
      if (json['gallery_images'] is String) {
        // Parse JSON string like: ["url1","url2","url3"]
        try {
          final decoded = json['gallery_images'] as String;
          if (decoded.startsWith('[') && decoded.endsWith(']')) {
            final content = decoded.substring(1, decoded.length - 1);
            if (content.isNotEmpty) {
              galleryImages = content
                  .split(',')
                  .map((e) => e.trim().replaceAll('"', ''))
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }
        } catch (e) {
          print('Error parsing gallery_images: $e');
        }
      } else if (json['gallery_images'] is List) {
        galleryImages = (json['gallery_images'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Build images list for compatibility with existing code
    List<KrasnalImage> images = [];
    
    // Add primary image
    if (json['image_url'] != null) {
      images.add(KrasnalImage(
        id: '${json['id']}_primary',
        url: json['image_url'] as String,
        isPrimary: true,
        uploadedAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      ));
    }

    // Add medallion images
    if (json['undiscovered_medallion_url'] != null) {
      images.add(KrasnalImage(
        id: '${json['id']}_undiscovered',
        url: json['undiscovered_medallion_url'] as String,
        caption: 'Undiscovered Medallion',
        uploadedAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      ));
    }

    if (json['discovered_medallion_url'] != null) {
      images.add(KrasnalImage(
        id: '${json['id']}_discovered',
        url: json['discovered_medallion_url'] as String,
        caption: 'Discovered Medallion',
        uploadedAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      ));
    }

    // Add gallery images
    for (int i = 0; i < galleryImages.length; i++) {
      images.add(KrasnalImage(
        id: '${json['id']}_gallery_$i',
        url: galleryImages[i],
        caption: 'Gallery Image ${i + 1}',
        uploadedAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      ));
    }

    // Parse legacy category and status
    KrasnalCategory category = KrasnalCategory.other;
    if (json['category'] != null) {
      category = KrasnalCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => KrasnalCategory.other,
      );
    }

    KrasnalStatus status = KrasnalStatus.active;
    if (json['status'] != null) {
      status = KrasnalStatus.values.firstWhere(
        (stat) => stat.name == json['status'],
        orElse: () => KrasnalStatus.active,
      );
    } else if (json['is_active'] != null) {
      status = (json['is_active'] as bool) ? KrasnalStatus.active : KrasnalStatus.inactive;
    }

    return Krasnal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      history: json['history'] as String?,
      location: KrasnalLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['location_name'] as String?,
        district: json['district'] as String?,
      ),
      primaryImageUrl: json['image_url'] as String?,
      model3dUrl: json['model_3d_url'] as String?,
      rarity: rarity,
      discoveryRadius: (json['discovery_radius'] as num?)?.toInt() ?? 25,
      pointsValue: (json['points_value'] as num?)?.toInt() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      undiscoveredMedallionUrl: json['undiscovered_medallion_url'] as String?,
      discoveredMedallionUrl: json['discovered_medallion_url'] as String?,
      galleryImages: galleryImages,
      images: images,
      metadata: json['metadata'] as Map<String, dynamic>?,
      category: category,
      status: status,
      isVisited: json['isVisited'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      author: json['author'] as String?,
      sculptor: json['sculptor'] as String?,
      yearCreated: json['yearCreated'] as int?,
    );
  }

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
      rarity: KrasnalRarity.common,
      discoveryRadius: 25,
      pointsValue: 10,
      isActive: true,
      galleryImages: images.length > 1 ? images.skip(1).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'history': history,
      'location_name': location.address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'image_url': primaryImageUrl,
      'model_3d_url': model3dUrl,
      'rarity': rarity.name,
      'discovery_radius': discoveryRadius,
      'points_value': pointsValue,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'undiscovered_medallion_url': undiscoveredMedallionUrl,
      'discovered_medallion_url': discoveredMedallionUrl,
      'gallery_images': galleryImages.isNotEmpty 
          ? '["${galleryImages.join('","')}"]' 
          : null,
      'metadata': metadata,
      // Legacy fields
      'category': category.name,
      'status': status.name,
      'isVisited': isVisited,
      'updatedAt': updatedAt?.toIso8601String(),
      'author': author,
      'sculptor': sculptor,
      'yearCreated': yearCreated,
    };
  }

  // Legacy toMap for backward compatibility
  Map<String, dynamic> toMap() => toJson();
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

  factory Krasnal.fromMap(Map<String, dynamic> map) => Krasnal.fromJson(map);

  Krasnal copyWith({
    String? id,
    String? name,
    String? description,
    String? history,
    KrasnalLocation? location,
    String? primaryImageUrl,
    String? model3dUrl,
    KrasnalRarity? rarity,
    int? discoveryRadius,
    int? pointsValue,
    bool? isActive,
    DateTime? createdAt,
    String? undiscoveredMedallionUrl,
    String? discoveredMedallionUrl,
    List<String>? galleryImages,
    List<KrasnalImage>? images,
    Map<String, dynamic>? metadata,
    KrasnalCategory? category,
    KrasnalStatus? status,
    bool? isVisited,
    DateTime? updatedAt,
    String? author,
    String? sculptor,
    int? yearCreated,
  }) {
    return Krasnal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      history: history ?? this.history,
      location: location ?? this.location,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      model3dUrl: model3dUrl ?? this.model3dUrl,
      rarity: rarity ?? this.rarity,
      discoveryRadius: discoveryRadius ?? this.discoveryRadius,
      pointsValue: pointsValue ?? this.pointsValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      undiscoveredMedallionUrl: undiscoveredMedallionUrl ?? this.undiscoveredMedallionUrl,
      discoveredMedallionUrl: discoveredMedallionUrl ?? this.discoveredMedallionUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
      category: category ?? this.category,
      status: status ?? this.status,
      isVisited: isVisited ?? this.isVisited,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      sculptor: sculptor ?? this.sculptor,
      yearCreated: yearCreated ?? this.yearCreated,
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
  bool get isActiveStatus => isActive && status == KrasnalStatus.active;
  bool get hasMedallionImages => undiscoveredMedallionUrl != null || discoveredMedallionUrl != null;
  bool get hasGalleryImages => galleryImages.isNotEmpty;
  bool get hasHistory => history != null && history!.isNotEmpty;
  
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

  String get rarityDisplayName {
    switch (rarity) {
      case KrasnalRarity.common:
        return 'Common';
      case KrasnalRarity.rare:
        return 'Rare';
      case KrasnalRarity.epic:
        return 'Epic';
      case KrasnalRarity.legendary:
        return 'Legendary';
    }
  }

  // Get all image URLs in a flat list
  List<String> get allImageUrls {
    final List<String> allUrls = [];
    if (primaryImageUrl != null) allUrls.add(primaryImageUrl!);
    if (undiscoveredMedallionUrl != null) allUrls.add(undiscoveredMedallionUrl!);
    if (discoveredMedallionUrl != null) allUrls.add(discoveredMedallionUrl!);
    allUrls.addAll(galleryImages);
    return allUrls;
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