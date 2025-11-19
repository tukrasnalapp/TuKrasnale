// 🔄 UPDATED KRASNAL MODELS TO MATCH DATABASE SCHEMA
// This file has been updated to match the actual Supabase database schema
// Based on CSV export showing actual table structure

import 'package:flutter/foundation.dart';

enum KrasnalRarity {
  common,
  rare,
  epic,
  legendary,
}

class KrasnalLocation {
  final String? address;
  final double latitude;
  final double longitude;

  const KrasnalLocation({
    this.address,
    required this.latitude,
    required this.longitude,
  });

  factory KrasnalLocation.fromJson(Map<String, dynamic> json) {
    return KrasnalLocation(
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class KrasnalImage {
  final String url;
  final String? type;
  final int? orderIndex;

  const KrasnalImage({
    required this.url,
    this.type,
    this.orderIndex,
  });

  factory KrasnalImage.fromJson(Map<String, dynamic> json) {
    return KrasnalImage(
      url: json['url'] as String,
      type: json['type'] as String?,
      orderIndex: json['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'orderIndex': orderIndex,
    };
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
  });

  // Convenience getters for backwards compatibility
  double get latitude => location.latitude;
  double get longitude => location.longitude;

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
        url: json['image_url'] as String,
        type: 'primary',
        orderIndex: 0,
      ));
    }

    // Add medallion images
    if (json['undiscovered_medallion_url'] != null) {
      images.add(KrasnalImage(
        url: json['undiscovered_medallion_url'] as String,
        type: 'medallion_undiscovered',
        orderIndex: 1,
      ));
    }

    if (json['discovered_medallion_url'] != null) {
      images.add(KrasnalImage(
        url: json['discovered_medallion_url'] as String,
        type: 'medallion_discovered',
        orderIndex: 2,
      ));
    }

    // Add gallery images
    for (int i = 0; i < galleryImages.length; i++) {
      images.add(KrasnalImage(
        url: galleryImages[i],
        type: 'gallery',
        orderIndex: i + 3,
      ));
    }

    return Krasnal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      history: json['history'] as String?,
      location: KrasnalLocation(
        address: json['location_name'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      primaryImageUrl: json['image_url'] as String?,
      model3dUrl: json['model_3d_url'] as String?,
      rarity: rarity,
      discoveryRadius: (json['discovery_radius'] as num?)?.toInt() ?? 25,
      pointsValue: (json['points_value'] as num?)?.toInt() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      undiscoveredMedallionUrl: json['undiscovered_medallion_url'] as String?,
      discoveredMedallionUrl: json['discovered_medallion_url'] as String?,
      galleryImages: galleryImages,
      images: images,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
    };
  }

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
    );
  }
}