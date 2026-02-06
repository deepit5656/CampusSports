import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/football/football_match.dart';
import '../models/football/football_event.dart';

class FootballScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get _matchesCollection => 'football_matches';
  String get _eventsCollection => 'football_events';

  // Create Match
  Future<String> createMatch(FootballMatch match) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .add(match.toMap());
    return doc.id;
  }

  // Update Match
  Future<void> updateMatch(String matchId, FootballMatch match) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update(match.toMap());
  }

  // Get Match
  Future<FootballMatch?> getMatch(String matchId) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .get();
    
    if (!doc.exists) return null;
    return FootballMatch.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Get Match Stream
  Stream<FootballMatch> getMatchStream(String matchId) {
    return _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((doc) => FootballMatch.fromMap({...doc.data()!, 'id': doc.id}));
  }

  // Add Goal
  Future<void> addGoal({
    required String matchId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int minute,
    String? assistPlayerId,
    String? assistPlayerName,
    bool isPenalty = false,
    bool isOwnGoal = false,
  }) async {
    final match = await getMatch(matchId);
    if (match == null) return;

    // Create event
    final event = FootballEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      teamId: isOwnGoal ? (teamId == match.team1Id ? match.team2Id : match.team1Id) : teamId,
      eventType: isOwnGoal ? FootballEventType.ownGoal : 
                  isPenalty ? FootballEventType.penalty : FootballEventType.goal,
      minute: minute,
      playerId: playerId,
      playerName: playerName,
      assistPlayerId: assistPlayerId,
      assistPlayerName: assistPlayerName,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .set(event.toMap());

    // Update scores
    final updatedMatch = match.copyWith(
      team1Score: match.team1Score + (event.teamId == match.team1Id ? 1 : 0),
      team2Score: match.team2Score + (event.teamId == match.team2Id ? 1 : 0),
    );

    await updateMatch(matchId, updatedMatch);
  }

  // Add Card
  Future<void> addCard({
    required String matchId,
    required String teamId,
    required String playerId,
    required String playerName,
    required int minute,
    required bool isYellow,
  }) async {
    final event = FootballEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      teamId: teamId,
      eventType: isYellow ? FootballEventType.yellowCard : FootballEventType.redCard,
      minute: minute,
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
  Future<List<FootballEvent>> getMatchEvents(String matchId) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('minute')
        .get();
    
    return snapshot.docs
        .map((doc) => FootballEvent.fromMap(doc.data()))
        .toList();
  }

  // Get Match Events Stream
  Stream<List<FootballEvent>> getMatchEventsStream(String matchId) {
    return _firestore
        .collection(_eventsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('minute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FootballEvent.fromMap(doc.data()))
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

  // End Half
  Future<void> endHalf(String matchId, int half) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({
      'currentHalf': half,
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
    
    final eventData = FootballEvent.fromMap(event.data()!);
    
    // If it's a goal, update scores
    if (eventData.eventType == FootballEventType.goal ||
        eventData.eventType == FootballEventType.penalty ||
        eventData.eventType == FootballEventType.ownGoal) {
      final match = await getMatch(matchId);
      if (match != null) {
        final updatedMatch = match.copyWith(
          team1Score: match.team1Score - (eventData.teamId == match.team1Id ? 1 : 0),
          team2Score: match.team2Score - (eventData.teamId == match.team2Id ? 1 : 0),
        );
        await updateMatch(matchId, updatedMatch);
      }
    }
    
    await _firestore.collection(_eventsCollection).doc(eventId).delete();
  }

  // Get All Matches for Sport
  Future<List<FootballMatch>> getSportMatches(String sportId) async {
    final snapshot = await _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => FootballMatch.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get Live Matches
  Stream<List<FootballMatch>> getLiveMatchesStream(String sportId) {
    return _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FootballMatch.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
