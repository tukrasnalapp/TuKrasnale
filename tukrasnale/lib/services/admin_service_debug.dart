import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/krasnal_models.dart';

class AdminServiceDebug {
  final _supabase = Supabase.instance.client;

  // Debug version of createKrasnal with comprehensive logging
  Future<bool> createKrasnalDebug(KrasnalModel krasnal) async {
    print('🔄 AdminService.createKrasnal called');
    print('📝 Input data:');
    print('   Name: ${krasnal.name}');
    print('   Description: ${krasnal.description}');
    print('   Location: ${krasnal.latitude}, ${krasnal.longitude}');
    print('   Location Name: ${krasnal.locationName}');
    print('   Rarity: ${krasnal.rarity}');
    print('   Points: ${krasnal.pointsValue}');
    print('   Main Image: ${krasnal.imageUrl}');
    
    try {
      // Step 1: Check authentication
      final user = _supabase.auth.currentUser;
      print('👤 Current user: ${user?.email} (ID: ${user?.id})');
      
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }
      
      // Step 2: Check user profile and admin status
      print('🔄 Checking user profile...');
      final userProfile = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();
      
      print('👤 User profile: $userProfile');
      
      if (userProfile == null) {
        print('❌ User profile not found - creating one...');
        try {
          await _supabase.from('user_profiles').insert({
            'user_id': user.id,
            'username': user.email?.split('@').first ?? 'admin',
            'full_name': user.userMetadata?['full_name'] ?? '',
            'role': 'user', // Default role
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('✅ User profile created with default role');
        } catch (e) {
          print('❌ Failed to create user profile: $e');
        }
        return false;
      }
      
      if (userProfile['role'] != 'admin') {
        print('❌ User role is "${userProfile['role']}", not admin');
        return false;
      }
      
      print('✅ User confirmed as admin');
      
      // Step 3: Prepare data for insertion
      String rarityValue;
      switch (krasnal.rarity) {
        case KrasnalRarity.common:
          rarityValue = 'common';
          break;
        case KrasnalRarity.rare:
          rarityValue = 'rare';
          break;
        case KrasnalRarity.epic:
          rarityValue = 'epic';
          break;
        case KrasnalRarity.legendary:
          rarityValue = 'legendary';
          break;
      }
      
      final insertData = {
        'name': krasnal.name,
        'description': krasnal.description,
        'latitude': krasnal.latitude,
        'longitude': krasnal.longitude,
        'location_name': krasnal.locationName,
        'rarity': rarityValue,
        'points_value': krasnal.pointsValue,
        'is_active': true,
        'image_url': krasnal.imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('📦 Data prepared for insert:');
      insertData.forEach((key, value) {
        print('   $key: $value');
      });
      
      // Step 4: Check table permissions
      print('🔄 Testing table access...');
      try {
        await _supabase
            .from('krasnale')
            .select('count')
            .limit(1);
        print('✅ Can read from krasnale table');
      } catch (e) {
        print('❌ Cannot read from krasnale table: $e');
        return false;
      }
      
      // Step 5: Attempt the insert
      print('🔄 Executing database insert...');
      
      final response = await _supabase
          .from('krasnale')
          .insert(insertData)
          .select()
          .single();
      
      print('✅ Insert successful! Response:');
      print('   ID: ${response['id']}');
      print('   Name: ${response['name']}');
      print('   Created: ${response['created_at']}');
      
      return true;
      
    } on PostgrestException catch (e) {
      print('❌ PostgrestException occurred:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');
      
      // Common error codes
      switch (e.code) {
        case '42501':
          print('🔒 Permission denied - RLS policy blocking insert');
          print('💡 Suggestion: Check if RLS policies allow admin inserts');
          break;
        case '23505':
          print('🔒 Unique constraint violation');
          break;
        case '23514':
          print('🔒 Check constraint violation');
          break;
        case '42703':
          print('🔒 Column does not exist');
          break;
        default:
          print('🔒 Unknown database error');
      }
      
      return false;
    } catch (e, stackTrace) {
      print('❌ Unexpected error: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  // Debug method to check admin status with logging
  Future<bool> isCurrentUserAdminDebug() async {
    print('🔄 Checking admin status...');
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }
      
      print('👤 User ID: ${user.id}');
      print('👤 User email: ${user.email}');
      
      final response = await _supabase
          .from('user_profiles')
          .select('role, username, full_name')
          .eq('user_id', user.id)
          .maybeSingle();
      
      print('📝 User profile response: $response');
      
      if (response == null) {
        print('❌ No user profile found');
        return false;
      }
      
      final isAdmin = response['role'] == 'admin';
      print('✅ Admin status: $isAdmin (role: ${response['role']})');
      
      return isAdmin;
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Method to manually set admin role (for debugging)
  Future<bool> makeCurrentUserAdmin() async {
    print('🔄 Setting current user as admin...');
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }
      
      await _supabase
          .from('user_profiles')
          .upsert({
            'user_id': user.id,
            'username': user.email?.split('@').first ?? 'admin',
            'full_name': user.userMetadata?['full_name'] ?? '',
            'role': 'admin',
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      print('✅ User set as admin');
      return true;
    } catch (e) {
      print('❌ Error setting admin role: $e');
      return false;
    }
  }
}