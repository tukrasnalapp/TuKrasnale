import '../services/admin_service.dart';
import '../models/krasnal_models.dart';

// Extension methods for AdminService to support uniqueness validation
extension AdminServiceUniqueness on AdminService {
  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    try {
      print('🔍 Checking if name exists: $name (excluding: $excludeId)');
      
      // Get all krasnale and check names
      final krasnale = await getAllKrasnale();
      final validKrasnale = krasnale.whereType<Krasnal>().toList();
      
      return validKrasnale.any((krasnal) => 
        krasnal.name.toLowerCase() == name.toLowerCase() && 
        (excludeId == null || krasnal.id != excludeId)
      );
    } catch (e) {
      print('❌ Error checking name uniqueness: $e');
      return false; // Assume unique on error to not block user
    }
  }
  
  Future<bool> checkCoordinatesExist(double latitude, double longitude, {String? excludeId}) async {
    try {
      print('🔍 Checking if coordinates exist: ($latitude, $longitude) (excluding: $excludeId)');
      
      // Get all krasnale and check coordinates (with small tolerance for floating point comparison)
      final krasnale = await getAllKrasnale();
      final validKrasnale = krasnale.whereType<Krasnal>().toList();
      
      const tolerance = 0.000001; // About 10cm tolerance
      
      return validKrasnale.any((krasnal) => 
        (krasnal.location.latitude - latitude).abs() < tolerance &&
        (krasnal.location.longitude - longitude).abs() < tolerance &&
        (excludeId == null || krasnal.id != excludeId)
      );
    } catch (e) {
      print('❌ Error checking coordinate uniqueness: $e');
      return false; // Assume unique on error to not block user
    }
  }
}