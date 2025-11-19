import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/krasnal_models.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  late SupabaseClient _client;
  
  SupabaseClient get client => _client;
  
  Future<void> initialize() async {
    await dotenv.load();
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    
    _client = Supabase.instance.client;
  }
  
  // Auth methods
  User? get currentUser => _client.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Database methods
  Future<PostgrestList> getData(String table) async {
    return await _client.from(table).select();
  }
  
  Future<PostgrestList> insertData(String table, Map<String, dynamic> data) async {
    return await _client.from(table).insert(data).select();
  }
  
  Future<PostgrestList> updateData(String table, Map<String, dynamic> data, String column, dynamic value) async {
    return await _client.from(table).update(data).eq(column, value).select();
  }
  
  Future<void> deleteData(String table, String column, dynamic value) async {
    await _client.from(table).delete().eq(column, value);
  }
  
  // Krasnal methods
  Future<List<Krasnal>> getAllKrasnale() async {
    final response = await _client
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
        .order('name');
        
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

  Future<List<Krasnal>> getNearbyKrasnale({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    // Simple distance calculation for now
    final allKrasnale = await getAllKrasnale();
    return allKrasnale.where((krasnal) {
      double distance = _calculateDistance(
        latitude, longitude,
        krasnal.location.latitude, krasnal.location.longitude,
      );
      return distance <= (radiusKm * 1000); // Convert to meters
    }).toList();
  }

  Future<List<Krasnal>> getDiscoverableKrasnale({
    required double userLat,
    required double userLng,
    double discoveryRadiusMeters = 50.0, // Default discovery radius
  }) async {
    final allKrasnale = await getAllKrasnale();
    List<Krasnal> discoverable = [];
    
    for (var krasnal in allKrasnale) {
      double distance = _calculateDistance(
        userLat, userLng,
        krasnal.location.latitude, krasnal.location.longitude,
      );
      if (distance <= discoveryRadiusMeters) {
        discoverable.add(krasnal);
      }
    }
    
    return discoverable;
  }

  // Helper method for distance calculation
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);
    
    double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) * math.sin(dLng / 2));
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // User discovery methods
  Future<List<Map<String, dynamic>>> getUserDiscoveries(String userId) async {
    final response = await _client
        .from('user_discoveries')
        .select('*, krasnale(*)')
        .eq('user_id', userId)
        .order('discovered_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> discoverKrasnal({
    required String krasnalId,
    required double userLat,
    required double userLng,
  }) async {
    try {
      // Record the discovery
      final response = await _client
          .from('user_discoveries')
          .insert({
            'user_id': currentUser!.id,
            'krasnal_id': krasnalId,
            'discovery_location_lat': userLat,
            'discovery_location_lng': userLng,
          })
          .select()
          .single();
          
      return response;
    } catch (e) {
      throw Exception('Failed to discover krasnal: $e');
    }
  }

  Future<bool> hasDiscovered(String krasnalId) async {
    if (currentUser == null) return false;
    
    final response = await _client
        .from('user_discoveries')
        .select('id')
        .eq('user_id', currentUser!.id)
        .eq('krasnal_id', krasnalId)
        .maybeSingle();
        
    return response != null;
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
        
    return response;
  }

  // Leaderboard methods
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    final response = await _client
        .from('user_profiles')
        .select('username, full_name, total_points, discoveries_count')
        .order('total_points', ascending: false)
        .limit(limit);
        
    return List<Map<String, dynamic>>.from(response);
  }
}