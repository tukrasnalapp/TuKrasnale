import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/krasnal_models.dart';
import '../models/report_models.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Create new Krasnal
  Future<String> createKrasnal({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    String? locationAddress,
    KrasnalRarity rarity = KrasnalRarity.common,
    int pointsValue = 10,
    String? primaryImageUrl,
    List<Map<String, dynamic>> additionalImages = const [],
  }) async {
    // First create the location
    final locationResponse = await _supabase.from('locations').insert({
      'latitude': latitude,
      'longitude': longitude,
      'address': locationAddress,
    }).select().single();

    final locationId = locationResponse['id'];

    // Prepare metadata
    final metadata = {
      'rarity': rarity.name,
      'pointsValue': pointsValue,
    };

    // Create the krasnal
    final krasnalResponse = await _supabase.from('krasnale').insert({
      'name': name,
      'description': description ?? '',
      'location_id': locationId,
      'metadata': metadata,
      'primary_image_url': primaryImageUrl,
    }).select().single();

    final krasnalId = krasnalResponse['id'];

    // Insert additional images if provided
    if (additionalImages.isNotEmpty) {
      final imageInserts = additionalImages.map((image) => {
        'krasnal_id': krasnalId,
        'url': image['url'],
        'type': image['type'] ?? 'gallery',
        'order_index': image['orderIndex'] ?? 0,
      }).toList();

      await _supabase.from('images').insert(imageInserts);
    }

    return krasnalId;
  }

  // Update existing Krasnal
  Future<void> updateKrasnal(String id, Map<String, dynamic> updates) async {
    await _supabase
        .from('krasnale')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // Delete Krasnal
  Future<void> deleteKrasnal(String id) async {
    await _supabase.from('krasnale').delete().eq('id', id);
  }

  // Get all Krasnale for admin management
  Future<List<Krasnal>> getAllKrasnale() async {
    final response = await _supabase
        .from('krasnale')
        .select('''
          id,
          name,
          description,
          location:locations(
            id,
            latitude,
            longitude,
            address,
            country,
            city
          ),
          metadata,
          primary_image_url,
          created_at,
          images(
            id,
            url,
            type,
            order_index
          )
        ''')
        .order('created_at', ascending: false);

    return response.map<Krasnal>((json) {
      final location = json['location'];
      final images = json['images'] as List<dynamic>?;
      
      return Krasnal(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        location: KrasnalLocation(
          latitude: location['latitude'],
          longitude: location['longitude'],
          address: location['address'],
        ),
        metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
        createdAt: DateTime.parse(json['created_at']),
        images: images?.map((img) => KrasnalImage(
          id: img['id'],
          url: img['url'],
          uploadedAt: DateTime.now(), // Default since we don't have this field
        )).toList() ?? [],
      );
    }).toList();
  }

  // Get all reports for admin review
  Future<List<KrasnaleReport>> getAllReports() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('*')
        .order('created_at', ascending: false);

    return response.map<KrasnaleReport>((json) => KrasnaleReport.fromJson(json)).toList();
  }

  // Update report status with admin notes
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminNotes,
  }) async {
    String statusValue;
    switch (status) {
      case ReportStatus.inReview:
        statusValue = 'in_review';
        break;
      default:
        statusValue = status.name;
    }

    await _supabase.from('krasnale_reports').update({
      'status': statusValue,
      'admin_notes': adminNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  // Get reports by status for admin dashboard
  Future<List<KrasnaleReport>> getReportsByStatus(ReportStatus status) async {
    String statusValue;
    switch (status) {
      case ReportStatus.inReview:
        statusValue = 'in_review';
        break;
      default:
        statusValue = status.name;
    }

    final response = await _supabase
        .from('krasnale_reports')
        .select('*')
        .eq('status', statusValue)
        .order('created_at', ascending: false);

    return response.map<KrasnaleReport>((json) => KrasnaleReport.fromJson(json)).toList();
  }

  // Get report statistics for admin dashboard
  Future<Map<String, int>> getReportStatistics() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('status');

    final stats = <String, int>{
      'pending': 0,
      'in_review': 0,
      'resolved': 0,
      'rejected': 0,
    };

    for (final row in response) {
      final status = row['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // Get pending reports count
  Future<int> getPendingReportsCount() async {
    final response = await _supabase
        .from('krasnale_reports')
        .select('id')
        .eq('status', 'pending');

    return response.length;
  }

  // Upload image to storage
  Future<String?> uploadImage(String path, List<int> bytes) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      await _supabase.storage
          .from('krasnale-images')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      return _supabase.storage
          .from('krasnale-images')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabase.storage
          .from('krasnale-images')
          .remove([fileName]);
    } catch (e) {
      // Ignore deletion errors
    }
  }
}