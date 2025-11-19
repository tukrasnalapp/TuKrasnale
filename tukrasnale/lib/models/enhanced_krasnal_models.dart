// This file has been consolidated into krasnal_models.dart
// Please use '../models/krasnal_models.dart' instead
// See MIGRATION_GUIDE.dart for details

// This file is marked for removal - do not use
@Deprecated('Use krasnal_models.dart instead')
library;

// All functionality has been moved to krasnal_models.dart
// 
// MIGRATION NOTES:
// - EnhancedKrasnalModel functionality is now part of the main Krasnal class
// - Use KrasnalImage class for image management
// - Use KrasnalLocation for location data
// - Use the metadata field for additional properties
//
// Example migration:
// OLD: EnhancedKrasnalModel(...)
// NEW: Krasnal(...) with KrasnalImage objects and metadata
//
// For backward compatibility, see the extension in:
// ../extensions/krasnal_model_extensions.dart