import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tennis/tennis_match.dart';
import '../models/tennis/tennis_point.dart';

class TennisScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get _matchesCollection => 'tennis_matches';
  String get _pointsCollection => 'tennis_points';

  // Create Match
  Future<String> createMatch(TennisMatch match) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .add(match.toMap());
    return doc.id;
  }

  // Update Match
  Future<void> updateMatch(String matchId, TennisMatch match) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update(match.toMap());
  }

  // Get Match
  Future<TennisMatch?> getMatch(String matchId) async {
    final doc = await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .get();
    
    if (!doc.exists) return null;
    return TennisMatch.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Get Match Stream
  Stream<TennisMatch> getMatchStream(String matchId) {
    return _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((doc) => TennisMatch.fromMap({...doc.data()!, 'id': doc.id}));
  }

  // Add Point
  Future<void> addPoint({
    required String matchId,
    required String winnerId,
    required int set,
    required int game,
    bool isAce = false,
    bool isDoubleFault = false,
  }) async {
    final match = await getMatch(matchId);
    if (match == null) return;

    // Create point event
    final point = TennisPoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      winnerId: winnerId,
      set: set,
      game: game,
      isAce: isAce,
      isDoubleFault: isDoubleFault,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection(_pointsCollection)
        .doc(point.id)
        .set(point.toMap());

    // Calculate new scores
    final updatedMatch = _calculateScore(match, winnerId);
    await updateMatch(matchId, updatedMatch);
  }

  TennisMatch _calculateScore(TennisMatch match, String pointWinnerId) {
    // Copy current scores
    Map<int, Map<String, int>> newSetScores = Map.from(match.setScores);
    Map<String, String> newGameScore = Map.from(match.currentGameScore);

    final currentSet = match.currentSet;
    final player1Id = match.player1Id;
    final player2Id = match.player2Id;
    
    // Get current game scores
    String p1Score = newGameScore[player1Id] ?? '0';
    String p2Score = newGameScore[player2Id] ?? '0';

    // Point winner gets a point
    if (pointWinnerId == player1Id) {
      p1Score = _getNextScore(p1Score, p2Score);
    } else {
      p2Score = _getNextScore(p2Score, p1Score);
    }

    newGameScore[player1Id] = p1Score;
    newGameScore[player2Id] = p2Score;

    // Check if game is won
    if (p1Score == 'W') {
      // Player 1 wins game
      newSetScores[currentSet]![player1Id] = (newSetScores[currentSet]![player1Id] ?? 0) + 1;
      newGameScore = {player1Id: '0', player2Id: '0'};
    } else if (p2Score == 'W') {
      // Player 2 wins game
      newSetScores[currentSet]![player2Id] = (newSetScores[currentSet]![player2Id] ?? 0) + 1;
      newGameScore = {player1Id: '0', player2Id: '0'};
    }

    // Check if set is won
    final p1Games = newSetScores[currentSet]![player1Id] ?? 0;
    final p2Games = newSetScores[currentSet]![player2Id] ?? 0;
    
    bool setWon = false;
    String? setWinner;
    
    if (p1Games >= 6 && p1Games - p2Games >= 2) {
      setWon = true;
      setWinner = player1Id;
    } else if (p2Games >= 6 && p2Games - p1Games >= 2) {
      setWon = true;
      setWinner = player2Id;
    }

    int newCurrentSet = currentSet;
    int newPlayer1Sets = match.player1Sets;
    int newPlayer2Sets = match.player2Sets;
    String status = match.status;
    String? winnerId = match.winnerId;

    if (setWon) {
      if (setWinner == player1Id) {
        newPlayer1Sets++;
      } else {
        newPlayer2Sets++;
      }

      // Check if match is won
      final setsToWin = (match.totalSets + 1) ~/ 2;
      if (newPlayer1Sets >= setsToWin) {
        status = 'completed';
        winnerId = player1Id;
      } else if (newPlayer2Sets >= setsToWin) {
        status = 'completed';
        winnerId = player2Id;
      } else {
        // Start new set
        newCurrentSet++;
        newSetScores[newCurrentSet] = {player1Id: 0, player2Id: 0};
      }
    }

    return match.copyWith(
      setScores: newSetScores,
      currentGameScore: newGameScore,
      currentSet: newCurrentSet,
      player1Sets: newPlayer1Sets,
      player2Sets: newPlayer2Sets,
      status: status,
      winnerId: winnerId,
    );
  }

  String _getNextScore(String currentScore, String opponentScore) {
    switch (currentScore) {
      case '0':
        return '15';
      case '15':
        return '30';
      case '30':
        return '40';
      case '40':
        if (opponentScore == '40') {
          return 'AD';
        } else if (opponentScore == 'AD') {
          return '40';
        } else {
          return 'W';
        }
      case 'AD':
        return 'W';
      default:
        return '0';
    }
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

  // End Match
  Future<void> endMatch(String matchId) async {
    await _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .update({
      'status': 'completed',
      'endTime': Timestamp.now(),
    });
  }

  // Get Match Points
  Future<List<TennisPoint>> getMatchPoints(String matchId) async {
    final snapshot = await _firestore
        .collection(_pointsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp')
        .get();
    
    return snapshot.docs
        .map((doc) => TennisPoint.fromMap(doc.data()))
        .toList();
  }

  // Get All Matches for Sport
  Future<List<TennisMatch>> getSportMatches(String sportId) async {
    final snapshot = await _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => TennisMatch.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get Live Matches
  Stream<List<TennisMatch>> getLiveMatchesStream(String sportId) {
    return _firestore
        .collection(_matchesCollection)
        .where('sportId', isEqualTo: sportId)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TennisMatch.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
