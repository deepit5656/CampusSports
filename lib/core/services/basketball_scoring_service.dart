import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/basketball/basketball_match.dart';
import '../models/basketball/basketball_event.dart';

class BasketballScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get _matchesCollection => 'basketball_matches';
  String get _eventsCollection => 'basketball_events';

  // Create Match
  Future<String> createMatch(BasketballMatch match) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .add(match.toMap());
    return doc.id;
  }

  // Update Match
  Future<void> updateMatch(String matchId, BasketballMatch match) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update(match.toMap());
  }

  // Get Match
  Future<BasketballMatch?> getMatch(String matchId) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .get();
    
    if (!doc.exists) return null;
    return BasketballMatch.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Get Match Stream
  Stream<BasketballMatch> getMatchStream(String matchId) {
    return _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((doc) => BasketballMatch.fromMap({...doc.data()!, 'id': doc.id}));
  }

  // Add Score
  Future<void> addScore({
    required String matchId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int points,
    required int quarter,
  }) async {
    final match = await getMatch(matchId);
    if (match == null) return;

    // Create event
    final event = BasketballEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      teamId: teamId,
      eventType: points == 1
          ? BasketballEventType.freeThrow
          : points == 2
              ? BasketballEventType.twoPointer
              : BasketballEventType.threePointer,
      quarter: quarter,
      playerId: playerId,
      playerName: playerName,
      points: points,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .set(event.toMap());

    // Update scores
    final updatedMatch = match.copyWith(
      team1Score: match.team1Score + (teamId == match.team1Id ? points : 0),
      team2Score: match.team2Score + (teamId == match.team2Id ? points : 0),
    );

    await updateMatch(matchId, updatedMatch);
  }

  // Add Foul
  Future<void> addFoul({
    required String matchId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int quarter,
  }) async {
    final event = BasketballEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      teamId: teamId,
      eventType: BasketballEventType.foul,
      quarter: quarter,
      playerId: playerId,
      playerName: playerName,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .set(event.toMap());
  }

  // Get Match Events
  Future<List<BasketballEvent>> getMatchEvents(String matchId) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp')
        .get();
    
    return snapshot.docs
        .map((doc) => BasketballEvent.fromMap(doc.data()))
        .toList();
  }

  // Get Match Events Stream
  Stream<List<BasketballEvent>> getMatchEventsStream(String matchId) {
    return _firestore
        .collection(_eventsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BasketballEvent.fromMap(doc.data()))
            .toList());
  }

  // Start Match
  Future<void> startMatch(String matchId) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({
      'status': 'ongoing',
      'startTime': Timestamp.now(),
    });
  }

  // End Quarter
  Future<void> endQuarter(String matchId, int quarter) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({
      'currentQuarter': quarter + 1,
    });
  }

  // End Match
  Future<void> endMatch(String matchId) async {
    final match = await getMatch(matchId);
    if (match == null) return;

    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({
      'status': 'completed',
      'endTime': Timestamp.now(),
      'winnerId': match.team1Score > match.team2Score
          ? match.team1Id
          : match.team1Score < match.team2Score
              ? match.team2Id
              : null,
    });
  }

  // Delete Event
  Future<void> deleteEvent(String eventId, String matchId) async {
    final event = await _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .get();
    
    if (!event.exists) return;
    
    final eventData = BasketballEvent.fromMap(event.data()!);
    
    // If it's a scoring event, update scores
    if (eventData.points != null) {
      final match = await getMatch(matchId);
      if (match != null) {
        final updatedMatch = match.copyWith(
          team1Score: match.team1Score - (eventData.teamId == match.team1Id ? eventData.points! : 0),
          team2Score: match.team2Score - (eventData.teamId == match.team2Id ? eventData.points! : 0),
        );
        await updateMatch(matchId, updatedMatch);
      }
    }
    
    await _firestore.collection(_eventsCollection).doc(eventId).delete();
  }

  // Get All Matches for Sport
  Future<List<BasketballMatch>> getSportMatches(String sportId) async {
    final snapshot = await _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => BasketballMatch.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get Live Matches
  Stream<List<BasketballMatch>> getLiveMatchesStream(String sportId) {
    return _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BasketballMatch.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
