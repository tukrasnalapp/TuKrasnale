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
    String? locationName,
    required KrasnalRarity rarity,
    required int pointsValue,
    String? imageUrl,
    String? undiscoveredMedallionUrl,
    String? discoveredMedallionUrl,
    List<String> galleryImages = const [],
  }) async {
    final response = await _supabase.from('krasnale').insert({
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'rarity': rarity.name,
      'points_value': pointsValue,
      'image_url': imageUrl,
      'undiscovered_medallion_url': undiscoveredMedallionUrl,
      'discovered_medallion_url': discoveredMedallionUrl,
      'gallery_images': galleryImages,
    }).select().single();

    return response['id'];
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
  Future<List<KrasnalModel>> getAllKrasnale() async {
    final response = await _supabase
        .from('krasnale')
        .select('*')
        .order('created_at', ascending: false);

    return response.map<KrasnalModel>((json) => KrasnalModel.fromJson(json)).toList();
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