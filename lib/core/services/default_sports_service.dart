import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultSportsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize default sports in Firestore if they don't exist
  static Future<void> initializeDefaultSports() async {
    try {
      // Check if any sports exist
      final sportsQuery = await _firestore.collection('sports').limit(1).get();
      
      if (sportsQuery.docs.isNotEmpty) {
        print('✅ Default sports already initialized');
        return;
      }

      print('🏃 Initializing default sports...');

      // Default sports list with all required fields
      final defaultSports = [
        {'name': 'Cricket', 'icon': '🏏', 'description': 'Cricket matches', 'numberOfPlayers': 11},
        {'name': 'Football', 'icon': '⚽', 'description': 'Football matches', 'numberOfPlayers': 11},
        {'name': 'Basketball', 'icon': '🏀', 'description': 'Basketball matches', 'numberOfPlayers': 5},
        {'name': 'Badminton', 'icon': '🏸', 'description': 'Badminton matches', 'numberOfPlayers': 2},
        {'name': 'Volleyball', 'icon': '🏐', 'description': 'Volleyball matches', 'numberOfPlayers': 6},
        {'name': 'Table Tennis', 'icon': '🏓', 'description': 'Table Tennis matches', 'numberOfPlayers': 2},
        {'name': 'Tennis', 'icon': '🎾', 'description': 'Tennis matches', 'numberOfPlayers': 2},
        {'name': 'Tug of War', 'icon': '🪢', 'description': 'Tug of War matches', 'numberOfPlayers': 8},
        {'name': 'Kabaddi', 'icon': '🤼', 'description': 'Kabaddi matches', 'numberOfPlayers': 7},
        {'name': 'Athletics', 'icon': '🏃', 'description': 'Athletics events', 'numberOfPlayers': 1},
        {'name': 'Swimming', 'icon': '🏊', 'description': 'Swimming events', 'numberOfPlayers': 1},
        {'name': 'Chess', 'icon': '♟️', 'description': 'Chess matches', 'numberOfPlayers': 2},
        {'name': 'Carrom', 'icon': '🎯', 'description': 'Carrom matches', 'numberOfPlayers': 2},
        {'name': 'Frisbee', 'icon': '🥏', 'description': 'Frisbee matches', 'numberOfPlayers': 7},
      ];

      // Add each sport to Firestore
      final batch = _firestore.batch();
      for (final sport in defaultSports) {
        final docRef = _firestore.collection('sports').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'name': sport['name'],
          'icon': sport['icon'],
          'description': sport['description'],
          'numberOfPlayers': sport['numberOfPlayers'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
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
