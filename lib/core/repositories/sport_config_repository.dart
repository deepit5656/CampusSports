import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sport_config_comprehensive.dart';
import '../models/default_sport_configurations_comprehensive.dart';

class SportConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'sports';

  /// Initialize default sports in Firestore (call once on first run)
  Future<void> initializeDefaultSports() async {
    try {
      final batch = _firestore.batch();
      final defaultSports = DefaultSportConfigurations.getAllDefaultSports();

      for (final sport in defaultSports) {
        // Check if sport already exists
        final doc = await _firestore.collection(_collection).doc(sport.id).get();
        if (!doc.exists) {
          batch.set(
            _firestore.collection(_collection).doc(sport.id),
            sport.toMap(),
          );
        }
      }

      await batch.commit();
      print('✅ Default sports initialized successfully');
    } catch (e) {
      print('❌ Error initializing default sports: $e');
      rethrow;
    }
  }

  /// Get all sports (default + custom) as a stream
  Stream<List<SportConfigModel>> getSports() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SportConfigModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get single sport by ID
  Future<SportConfigModel?> getSportById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return SportConfigModel.fromMap(doc.data()!);
    } catch (e) {
      print('❌ Error getting sport by ID: $e');
      return null;
    }
  }

  /// Get sport by ID as stream
  Stream<SportConfigModel?> getSportByIdStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return SportConfigModel.fromMap(snapshot.data()!);
    });
  }

  /// Add custom sport
  Future<void> addSport(SportConfigModel sport) async {
    try {
      if (sport.isDefault) {
        throw Exception('Cannot manually add default sports. Use initializeDefaultSports()');
      }

      await _firestore.collection(_collection).doc(sport.id).set(sport.toMap());
      print('✅ Sport added successfully: ${sport.name}');
    } catch (e) {
      print('❌ Error adding sport: $e');
      rethrow;
    }
  }

  /// Update sport configuration
  /// For default sports, only parameters can be updated (not name, id, isDefault)
  Future<void> updateSport(SportConfigModel sport) async {
    try {
      final existingDoc = await _firestore.collection(_collection).doc(sport.id).get();
      
      if (!existingDoc.exists) {
        throw Exception('Sport not found');
      }

      final existingSport = SportConfigModel.fromMap(existingDoc.data()!);

      // For default sports, preserve critical fields
      if (existingSport.isDefault) {
        final updatedSport = sport.copyWith(
          id: existingSport.id,
          name: existingSport.name,
          icon: existingSport.icon,
          isDefault: true,
        );
        await _firestore.collection(_collection).doc(sport.id).update(updatedSport.toMap());
      } else {
        // Custom sports can be fully updated
        await _firestore.collection(_collection).doc(sport.id).update(sport.toMap());
      }

      print('✅ Sport updated successfully: ${sport.name}');
    } catch (e) {
      print('❌ Error updating sport: $e');
      rethrow;
    }
  }

  /// Delete sport (only if not default)
  Future<void> deleteSport(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        throw Exception('Sport not found');
      }

      final sport = SportConfigModel.fromMap(doc.data()!);

      if (sport.isDefault) {
        throw Exception('Cannot delete default sports. They are protected system sports.');
      }

      await _firestore.collection(_collection).doc(id).delete();
      print('✅ Sport deleted successfully: ${sport.name}');
    } catch (e) {
      print('❌ Error deleting sport: $e');
      rethrow;
    }
  }

  /// Get default sports only
  Future<List<SportConfigModel>> getDefaultSports() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isDefault', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => SportConfigModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting default sports: $e');
      return [];
    }
  }

  /// Get custom sports only
  Future<List<SportConfigModel>> getCustomSports() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isDefault', isEqualTo: false)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => SportConfigModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting custom sports: $e');
      return [];
    }
  }

  /// Search sports by name
  Future<List<SportConfigModel>> searchSports(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get();

      final allSports = snapshot.docs
          .map((doc) => SportConfigModel.fromMap(doc.data()))
          .toList();

      return allSports
          .where((sport) =>
              sport.name.toLowerCase().contains(query.toLowerCase()) ||
              sport.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('❌ Error searching sports: $e');
      return [];
    }
  }

  /// Check if default sports are initialized
  Future<bool> areDefaultSportsInitialized() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking default sports: $e');
      return false;
    }
  }

  /// Reset all default sports to original configuration
  Future<void> resetDefaultSports() async {
    try {
      final batch = _firestore.batch();
      final defaultSports = DefaultSportConfigurations.getAllDefaultSports();

      for (final sport in defaultSports) {
        batch.set(
          _firestore.collection(_collection).doc(sport.id),
          sport.toMap(),
          SetOptions(merge: false),
        );
      }

      await batch.commit();
      print('✅ Default sports reset successfully');
    } catch (e) {
      print('❌ Error resetting default sports: $e');
      rethrow;
    }
  }
}
