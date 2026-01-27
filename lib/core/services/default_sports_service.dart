import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultSportsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize default sports in Firestore if they don't exist
  static Future<void> initializeDefaultSports() async {
    try {
      // Check if Cricket sport exists
      final cricketQuery = await _firestore
          .collection('sports')
          .where('name', isEqualTo: 'Cricket')
          .limit(1)
          .get();

      if (cricketQuery.docs.isEmpty) {
        // Add Cricket as default sport
        await _firestore.collection('sports').add({
          'name': 'Cricket',
          'icon': '🏏',
          'description': 'Professional cricket scoring with ball-by-ball tracking, partnerships, and detailed statistics',
          'category': 'Outdoor',
          'createdAt': FieldValue.serverTimestamp(),
          'isCricket': true, // Special flag to identify cricket
        });
        print('✅ Cricket sport added to database');
      }

      // You can add more default sports here
      final footballQuery = await _firestore
          .collection('sports')
          .where('name', isEqualTo: 'Football')
          .limit(1)
          .get();

      if (footballQuery.docs.isEmpty) {
        await _firestore.collection('sports').add({
          'name': 'Football',
          'icon': '⚽',
          'description': 'The beautiful game',
          'category': 'Outdoor',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Football sport added to database');
      }

      final basketballQuery = await _firestore
          .collection('sports')
          .where('name', isEqualTo: 'Basketball')
          .limit(1)
          .get();

      if (basketballQuery.docs.isEmpty) {
        await _firestore.collection('sports').add({
          'name': 'Basketball',
          'icon': '🏀',
          'description': 'Fast-paced indoor sport',
          'category': 'Indoor',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Basketball sport added to database');
      }

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
