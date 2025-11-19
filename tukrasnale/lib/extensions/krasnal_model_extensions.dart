import '../models/krasnal_models.dart';

// 🎯 ENHANCED KRASNAL MODEL EXTENSIONS
//
// This extension adds the missing image fields to Krasnal
// until the original model class can be updated

extension KrasnalModelImageExtension on Krasnal {
  // Access image fields from a raw JSON object
  // This allows us to get the image data that exists in DB
  
  String? get undiscoveredMedallionUrl {
    // In a real scenario, we'd access this from the original JSON
    // For now, return null since original model doesn't store this
    return null;
  }
  
  String? get discoveredMedallionUrl {
    // Same issue - original model doesn't include this field
    return null;
  }
  
  List<String> get galleryImages {
    // Same issue - original model doesn't include this field
    return [];
  }
}

// 🔧 UTILITY: Create enhanced model from raw JSON
class KrasnalModelEnhanced {
  final Krasnal base;
  final String? undiscoveredMedallionUrl;
  final String? discoveredMedallionUrl;
  final List<String> galleryImages;

  KrasnalModelEnhanced({
    required this.base,
    this.undiscoveredMedallionUrl,
    this.discoveredMedallionUrl,
    this.galleryImages = const [],
  });
  
  // Create from raw JSON that includes image fields
  factory KrasnalModelEnhanced.fromJson(Map<String, dynamic> json) {
    return KrasnalModelEnhanced(
      base: Krasnal.fromMap(json),
      undiscoveredMedallionUrl: json['undiscovered_medallion_url'] as String?,
      discoveredMedallionUrl: json['discovered_medallion_url'] as String?,
      galleryImages: json['gallery_images'] != null 
          ? List<String>.from(json['gallery_images'] as List)
          : [],
    );
  }
  
  // Proxy all Krasnal properties
  String get id => base.id;
  String get name => base.name;
  String get description => base.description;
  double get latitude => base.latitude;
  double get longitude => base.longitude;
  String? get locationName => base.location.address;
  KrasnalRarity? get rarity => null; // This field doesn't exist in the base model
  int get pointsValue => 10; // Default value since this doesn't exist in base model
  String? get imageUrl => base.primaryImageUrl;
  DateTime get createdAt => base.createdAt;
}