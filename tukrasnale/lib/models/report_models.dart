enum ReportType {
  missing,
  wrongLocation,
  wrongInfo,
  damaged,
  newSuggestion,
  other
}

enum ReportStatus {
  pending,
  inReview,
  resolved,
  rejected
}

class KrasnaleReport {
  final String id;
  final String userId;
  final String? krasnalId;
  final ReportType reportType;
  final String title;
  final String description;
  final double? locationLat;
  final double? locationLng;
  final String? photoUrl;
  final ReportStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  KrasnaleReport({
    required this.id,
    required this.userId,
    this.krasnalId,
    required this.reportType,
    required this.title,
    required this.description,
    this.locationLat,
    this.locationLng,
    this.photoUrl,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KrasnaleReport.fromJson(Map<String, dynamic> json) {
    return KrasnaleReport(
      id: json['id'],
      userId: json['user_id'],
      krasnalId: json['krasnal_id'],
      reportType: ReportType.values.firstWhere(
        (e) => e.name == _convertReportType(json['report_type']),
        orElse: () => ReportType.other,
      ),
      title: json['title'],
      description: json['description'],
      locationLat: json['location_lat']?.toDouble(),
      locationLng: json['location_lng']?.toDouble(),
      photoUrl: json['photo_url'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == _convertStatus(json['status']),
        orElse: () => ReportStatus.pending,
      ),
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'krasnal_id': krasnalId,
      'report_type': _convertReportTypeToDb(reportType),
      'title': title,
      'description': description,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'photo_url': photoUrl,
      'status': _convertStatusToDb(status),
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _convertReportType(String dbValue) {
    switch (dbValue) {
      case 'wrong_location':
        return 'wrongLocation';
      case 'wrong_info':
        return 'wrongInfo';
      case 'new_suggestion':
        return 'newSuggestion';
      default:
        return dbValue;
    }
  }

  static String _convertStatus(String dbValue) {
    switch (dbValue) {
      case 'in_review':
        return 'inReview';
      default:
        return dbValue;
    }
  }

  static String _convertReportTypeToDb(ReportType type) {
    switch (type) {
      case ReportType.wrongLocation:
        return 'wrong_location';
      case ReportType.wrongInfo:
        return 'wrong_info';
      case ReportType.newSuggestion:
        return 'new_suggestion';
      default:
        return type.name;
    }
  }

  static String _convertStatusToDb(ReportStatus status) {
    switch (status) {
      case ReportStatus.inReview:
        return 'in_review';
      default:
        return status.name;
    }
  }
}

enum UserRole {
  user,
  admin
}

class UserProfile {
  final String id;
  final String? username;
  final String? fullName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.username,
    this.fullName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user_id'],
      username: json['username'],
      fullName: json['full_name'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'full_name': fullName,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == UserRole.admin;
}