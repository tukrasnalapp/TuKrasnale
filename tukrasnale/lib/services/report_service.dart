import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_models.dart';

class ReportService {
  final _supabase = Supabase.instance.client;

  // Submit a new report
  Future<String> submitReport({
    required String title,
    required String description,
    required ReportType reportType,
    String? krasnalId,
    double? locationLat,
    double? locationLng,
    String? photoUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit reports');
    }

    String reportTypeValue;
    switch (reportType) {
      case ReportType.wrongLocation:
        reportTypeValue = 'wrong_location';
        break;
      case ReportType.wrongInfo:
        reportTypeValue = 'wrong_info';
        break;
      case ReportType.newSuggestion:
        reportTypeValue = 'new_suggestion';
        break;
      default:
        reportTypeValue = reportType.name;
    }

    final response = await _supabase.from('krasnale_reports').insert({
      'user_id': user.id,
      'krasnal_id': krasnalId,
      'report_type': reportTypeValue,
      'title': title,
      'description': description,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'photo_url': photoUrl,
      'status': 'pending',
    }).select().single();

    return response['id'];
  }

  // Get reports submitted by current user
  Future<List<KrasnaleReport>> getUserReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [];
    }

    final response = await _supabase
        .from('krasnale_reports')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response.map<KrasnaleReport>((json) => KrasnaleReport.fromJson(json)).toList();
  }

  // Get report by ID (for detailed view)
  Future<KrasnaleReport?> getReportById(String id) async {
    try {
      final response = await _supabase
          .from('krasnale_reports')
          .select('*')
          .eq('id', id)
          .single();

      return KrasnaleReport.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Upload photo for report
  Future<String?> uploadReportPhoto(String reportId, List<int> bytes) async {
    try {
      final fileName = '${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('report-photos')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      return _supabase.storage
          .from('report-photos')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }
}