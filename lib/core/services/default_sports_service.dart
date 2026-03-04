import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/default_sport_configurations_comprehensive.dart';
import '../repositories/sport_config_repository.dart';

class DefaultSportsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize default sports in Firestore if they don't exist.
  /// Uses the unified 'sports' collection with comprehensive configs.
  static Future<void> initializeDefaultSports() async {
    try {
      // Check if comprehensive default sports already exist
      final sportsQuery = await _firestore
          .collection('sports')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (sportsQuery.docs.isNotEmpty) {
        print('✅ Default sports already initialized');
        return;
      }

      print('🏃 Initializing default sports with comprehensive configs...');

      final sportConfigRepo = SportConfigRepository();
      await sportConfigRepo.initializeDefaultSports();

      print('✅ Default sports initialized successfully');
    } catch (e) {
      print('❌ Error initializing default sports: $e');
    }
  }

  /// Check if a sport is cricket
  static Future<bool> isCricketSport(String sportId) async {
    try {
      final doc = await _firestore.collection('sports').doc(sportId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isCricket'] == true ||
               (data?['name'] as String?)?.toLowerCase() == 'cricket';
      }
    } catch (e) {
      print('Error checking cricket sport: $e');
    }
    return false;
  }
}
