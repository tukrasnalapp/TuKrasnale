// This file has been consolidated into krasnal_models.dart
// Please use '../models/krasnal_models.dart' instead
// See MIGRATION_GUIDE.dart for details

// This file is marked for removal - do not use
@Deprecated('Use krasnal_models.dart instead')
library;

class Krasnal {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> images;
  final bool isVisited;
  final DateTime createdAt;

  Krasnal({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.isVisited,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'isVisited': isVisited,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Krasnal.fromMap(Map<String, dynamic> map) {
    return Krasnal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      images: List<String>.from(map['images'] ?? []),
      isVisited: map['isVisited'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Krasnal copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? images,
    bool? isVisited,
    DateTime? createdAt,
  }) {
    return Krasnal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      isVisited: isVisited ?? this.isVisited,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}