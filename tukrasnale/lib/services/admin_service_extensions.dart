import '../services/admin_service.dart';

// Extension methods for AdminService to support uniqueness validation
extension AdminServiceUniqueness on AdminService {
  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    try {
      print('🔍 Checking if name exists: $name (excluding: $excludeId)');
      
      // Get all krasnale and check names
      final krasnale = await getAllKrasnale();
      
      return krasnale.any((krasnal) => 
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
      
      const tolerance = 0.000001; // About 10cm tolerance
      
      return krasnale.any((krasnal) => 
        (krasnal.latitude - latitude).abs() < tolerance &&
        (krasnal.longitude - longitude).abs() < tolerance &&
        (excludeId == null || krasnal.id != excludeId)
      );
    } catch (e) {
      print('❌ Error checking coordinate uniqueness: $e');
      return false; // Assume unique on error to not block user
    }
  }
}