// Re-export all models for easier imports
export 'krasnal_models.dart';

// Legacy models for backward compatibility
// These can be removed once all references are updated

class AppUser {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Example data model for app content
class AppData {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppData({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}