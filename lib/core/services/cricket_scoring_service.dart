import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cricket/cricket_ball.dart';
import '../models/cricket/cricket_batting_stats.dart';
import '../models/cricket/cricket_bowling_stats.dart';
import '../models/cricket/cricket_inning.dart';
import '../models/cricket/cricket_match_config.dart';
import '../models/cricket/cricket_partnership.dart';
import '../models/cricket/cricket_player.dart';

class CricketScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get _matchConfigsCollection => 'cricket_match_configs';
  String get _playersCollection => 'cricket_players';
  String get _inningsCollection => 'cricket_innings';
  String get _ballsCollection => 'cricket_balls';
  String get _battingStatsCollection => 'cricket_batting_stats';
  String get _bowlingStatsCollection => 'cricket_bowling_stats';
  String get _partnershipsCollection => 'cricket_partnerships';

  // Create/Update Match Config
  Future<void> saveMatchConfig(CricketMatchConfig config) async {
    await _firestore
        .collection(_matchConfigsCollection)
        .doc(config.matchId)
        .set(config.toMap());
  }

  // Get Match Config
  Future<CricketMatchConfig?> getMatchConfig(String matchId) async {
    final doc = await _firestore
        .collection(_matchConfigsCollection)
        .doc(matchId)
        .get();
    
    if (!doc.exists) return null;
    return CricketMatchConfig.fromMap(doc.data()!);
  }

  // Player Management
  Future<void> addPlayer(CricketPlayer player) async {
    await _firestore
        .collection(_playersCollection)
        .doc(player.id)
        .set(player.toMap());
  }

  Future<void> updatePlayer(CricketPlayer player) async {
    await _firestore
        .collection(_playersCollection)
        .doc(player.id)
        .update(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    await _firestore
        .collection(_playersCollection)
        .doc(playerId)
        .delete();
  }

  Future<List<CricketPlayer>> getTeamPlayers(String teamId) async {
    final snapshot = await _firestore
        .collection(_playersCollection)
        .where('teamId', isEqualTo: teamId)
        .get();
    
    return snapshot.docs
        .map((doc) => CricketPlayer.fromMap(doc.data()))
        .toList();
  }

  // Inning Management
  Future<String> startInning(CricketInning inning) async {
    final doc = await _firestore
        .collection(_inningsCollection)
        .add(inning.toMap());
    return doc.id;
  }

  Future<void> updateInning(CricketInning inning) async {
    await _firestore
        .collection(_inningsCollection)
        .doc(inning.id)
        .update(inning.toMap());
  }

  Future<CricketInning?> getInning(String inningId) async {
    final doc = await _firestore
        .collection(_inningsCollection)
        .doc(inningId)
        .get();
    
    if (!doc.exists) return null;
    return CricketInning.fromMap(doc.data()!);
  }

  Future<List<CricketInning>> getMatchInnings(String matchId) async {
    final snapshot = await _firestore
        .collection(_inningsCollection)
        .where('matchId', isEqualTo: matchId)
        .orderBy('inningNumber')
        .get();
    
    return snapshot.docs
        .map((doc) => CricketInning.fromMap(doc.data()))
        .toList();
  }

  // Ball-by-Ball Scoring
  Future<void> recordBall(CricketBall ball, CricketMatchConfig config) async {
    final batch = _firestore.batch();

    // 1. Add ball record
    final ballRef = _firestore.collection(_ballsCollection).doc(ball.id);
    batch.set(ballRef, ball.toMap());

    // 2. Update inning
    final inning = await getInning(ball.inningId);
    if (inning != null) {
      double newOvers = inning.overs;
      if (ball.isValidBall) {
        // Increment ball count for valid deliveries
        int overBalls = ((inning.overs - inning.overs.floor()) * 10).round();
        overBalls++;
        if (overBalls == 6) {
          newOvers = inning.overs.floor() + 1.0;
          // Swap striker and non-striker after over completes
        } else {
          newOvers = inning.overs.floor() + (overBalls / 10.0);
        }
      }

      final updatedInning = inning.copyWith(
        totalRuns: inning.totalRuns + ball.totalRuns,
        wickets: inning.wickets + (ball.isWicket ? 1 : 0),
        overs: newOvers,
        extras: inning.extras + ball.extras,
        wides: inning.wides + (ball.ballType == BallType.wide || ball.ballType == BallType.widePlusRuns ? 1 : 0),
        noBalls: inning.noBalls + (ball.ballType == BallType.noBall || ball.ballType == BallType.noBallPlusRuns ? 1 : 0),
        byes: inning.byes + (ball.ballType == BallType.bye ? ball.runs : 0),
        legByes: inning.legByes + (ball.ballType == BallType.legBye ? ball.runs : 0),
      );

      final inningRef = _firestore.collection(_inningsCollection).doc(ball.inningId);
      batch.update(inningRef, updatedInning.toMap());
    }

    // 3. Update batting stats
    await _updateBattingStats(ball, batch);

    // 4. Update bowling stats
    await _updateBowlingStats(ball, batch);

    // 5. Update partnership
    await _updatePartnership(ball, batch);

    await batch.commit();
  }

  Future<void> _updateBattingStats(CricketBall ball, WriteBatch batch) async {
    if (!ball.isValidBall && ball.ballType != BallType.noBallPlusRuns) {
      // Don't update batting stats for wides (but do for no-balls where batsman scores)
      return;
    }

    // Get or create batting stats for the striker
    final statsSnapshot = await _firestore
        .collection(_battingStatsCollection)
        .where('matchId', isEqualTo: ball.matchId)
        .where('inningId', isEqualTo: ball.inningId)
        .where('playerId', isEqualTo: ball.batsmanId)
        .limit(1)
        .get();

    CricketBattingStats stats;
    String statsId;

    if (statsSnapshot.docs.isEmpty) {
      // Create new stats
      statsId = _firestore.collection(_battingStatsCollection).doc().id;
      final player = await _getPlayerById(ball.batsmanId);
      stats = CricketBattingStats(
        id: statsId,
        matchId: ball.matchId,
        inningId: ball.inningId,
        playerId: ball.batsmanId,
        playerName: player?.name ?? '',
        position: 0, // Will be set properly when player starts batting
        createdAt: DateTime.now(),
      );
    } else {
      final doc = statsSnapshot.docs.first;
      statsId = doc.id;
      stats = CricketBattingStats.fromMap(doc.data());
    }

    // Update stats
    final updatedStats = stats.copyWith(
      runs: stats.runs + ball.runs,
      ballsFaced: stats.ballsFaced + (ball.isValidBall ? 1 : 0),
      fours: stats.fours + (ball.isFour ? 1 : 0),
      sixes: stats.sixes + (ball.isSix ? 1 : 0),
      isOut: stats.isOut || ball.isWicket,
      updatedAt: DateTime.now(),
    );

    final statsRef = _firestore.collection(_battingStatsCollection).doc(statsId);
    if (statsSnapshot.docs.isEmpty) {
      batch.set(statsRef, updatedStats.toMap());
    } else {
      batch.update(statsRef, updatedStats.toMap());
    }
  }

  Future<void> _updateBowlingStats(CricketBall ball, WriteBatch batch) async {
    // Get or create bowling stats
    final statsSnapshot = await _firestore
        .collection(_bowlingStatsCollection)
        .where('matchId', isEqualTo: ball.matchId)
        .where('inningId', isEqualTo: ball.inningId)
        .where('playerId', isEqualTo: ball.bowlerId)
        .limit(1)
        .get();

    CricketBowlingStats stats;
    String statsId;

    if (statsSnapshot.docs.isEmpty) {
      statsId = _firestore.collection(_bowlingStatsCollection).doc().id;
      final player = await _getPlayerById(ball.bowlerId);
      stats = CricketBowlingStats(
        id: statsId,
        matchId: ball.matchId,
        inningId: ball.inningId,
        playerId: ball.bowlerId,
        playerName: player?.name ?? '',
        createdAt: DateTime.now(),
      );
    } else {
      final doc = statsSnapshot.docs.first;
      statsId = doc.id;
      stats = CricketBowlingStats.fromMap(doc.data());
    }

    // Calculate overs bowled
    double newOvers = stats.overs;
    if (ball.isValidBall) {
      int overBalls = ((stats.overs - stats.overs.floor()) * 10).round();
      overBalls++;
      if (overBalls == 6) {
        newOvers = stats.overs.floor() + 1.0;
      } else {
        newOvers = stats.overs.floor() + (overBalls / 10.0);
      }
    }

    final updatedStats = stats.copyWith(
      overs: newOvers,
      runs: stats.runs + ball.totalRuns,
      wickets: stats.wickets + (ball.isWicket ? 1 : 0),
      wides: stats.wides + (ball.ballType == BallType.wide || ball.ballType == BallType.widePlusRuns ? 1 : 0),
      noBalls: stats.noBalls + (ball.ballType == BallType.noBall || ball.ballType == BallType.noBallPlusRuns ? 1 : 0),
      dotBalls: stats.dotBalls + (ball.runs == 0 && ball.extras == 0 ? 1 : 0),
      updatedAt: DateTime.now(),
    );

    final statsRef = _firestore.collection(_bowlingStatsCollection).doc(statsId);
    if (statsSnapshot.docs.isEmpty) {
      batch.set(statsRef, updatedStats.toMap());
    } else {
      batch.update(statsRef, updatedStats.toMap());
    }
  }

  Future<void> _updatePartnership(CricketBall ball, WriteBatch batch) async {
    // Get active partnership
    final partnershipSnapshot = await _firestore
        .collection(_partnershipsCollection)
        .where('matchId', isEqualTo: ball.matchId)
        .where('inningId', isEqualTo: ball.inningId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (partnershipSnapshot.docs.isEmpty) return;

    final doc = partnershipSnapshot.docs.first;
    final partnership = CricketPartnership.fromMap(doc.data());

    // Determine which batsman scored
    final isBatsman1 = partnership.batsman1Id == ball.batsmanId;
    
    final updatedPartnership = CricketPartnership(
      id: partnership.id,
      matchId: partnership.matchId,
      inningId: partnership.inningId,
      batsman1Id: partnership.batsman1Id,
      batsman1Name: partnership.batsman1Name,
      batsman1Runs: partnership.batsman1Runs + (isBatsman1 ? ball.runs : 0),
      batsman2Id: partnership.batsman2Id,
      batsman2Name: partnership.batsman2Name,
      batsman2Runs: partnership.batsman2Runs + (!isBatsman1 ? ball.runs : 0),
      totalRuns: partnership.totalRuns + ball.totalRuns,
      balls: partnership.balls + (ball.isValidBall ? 1 : 0),
      isActive: !ball.isWicket,
      startedAt: partnership.startedAt,
      endedAt: ball.isWicket ? DateTime.now() : null,
    );

    final partnershipRef = _firestore.collection(_partnershipsCollection).doc(partnership.id);
    batch.update(partnershipRef, updatedPartnership.toMap());
  }

  // Start new partnership
  Future<String> startPartnership(CricketPartnership partnership) async {
    final doc = await _firestore
        .collection(_partnershipsCollection)
        .add(partnership.toMap());
    return doc.id;
  }

  // Get partnership history
  Future<List<CricketPartnership>> getPartnerships(String inningId) async {
    final snapshot = await _firestore
        .collection(_partnershipsCollection)
        .where('inningId', isEqualTo: inningId)
        .orderBy('startedAt')
        .get();
    
    return snapshot.docs
        .map((doc) => CricketPartnership.fromMap(doc.data()))
        .toList();
  }

  // Get balls for an over
  Future<List<CricketBall>> getOverBalls(String inningId, int overNumber) async {
    final snapshot = await _firestore
        .collection(_ballsCollection)
        .where('inningId', isEqualTo: inningId)
        .where('overNumber', isEqualTo: overNumber)
        .orderBy('ballNumber')
        .get();
    
    return snapshot.docs
        .map((doc) => CricketBall.fromMap(doc.data()))
        .toList();
  }

  // Get all balls for an inning
  Future<List<CricketBall>> getInningBalls(String inningId) async {
    final snapshot = await _firestore
        .collection(_ballsCollection)
        .where('inningId', isEqualTo: inningId)
        .orderBy('overNumber')
        .orderBy('ballNumber')
        .get();
    
    return snapshot.docs
        .map((doc) => CricketBall.fromMap(doc.data()))
        .toList();
  }

  // Get batting stats for an inning
  Future<List<CricketBattingStats>> getInningBattingStats(String inningId) async {
    final snapshot = await _firestore
        .collection(_battingStatsCollection)
        .where('inningId', isEqualTo: inningId)
        .orderBy('position')
        .get();
    
    return snapshot.docs
        .map((doc) => CricketBattingStats.fromMap(doc.data()))
        .toList();
  }

  // Get bowling stats for an inning
  Future<List<CricketBowlingStats>> getInningBowlingStats(String inningId) async {
    final snapshot = await _firestore
        .collection(_bowlingStatsCollection)
        .where('inningId', isEqualTo: inningId)
        .get();
    
    return snapshot.docs
        .map((doc) => CricketBowlingStats.fromMap(doc.data()))
        .toList();
  }

  // Undo last ball
  Future<void> undoLastBall(String inningId) async {
    // Get last ball
    final ballsSnapshot = await _firestore
        .collection(_ballsCollection)
        .where('inningId', isEqualTo: inningId)
        .orderBy('overNumber', descending: true)
        .orderBy('ballNumber', descending: true)
        .limit(1)
        .get();

    if (ballsSnapshot.docs.isEmpty) return;

    final lastBall = CricketBall.fromMap(ballsSnapshot.docs.first.data());
    final batch = _firestore.batch();

    // Delete the ball
    final ballRef = _firestore.collection(_ballsCollection).doc(lastBall.id);
    batch.delete(ballRef);

    // Reverse inning stats
    final inning = await getInning(inningId);
    if (inning != null) {
      double newOvers = inning.overs;
      if (lastBall.isValidBall) {
        int overBalls = ((inning.overs - inning.overs.floor()) * 10).round();
        overBalls--;
        if (overBalls < 0) {
          newOvers = (inning.overs.floor() - 1) + 0.5;
        } else {
          newOvers = inning.overs.floor() + (overBalls / 10.0);
        }
      }

      final updatedInning = inning.copyWith(
        totalRuns: inning.totalRuns - lastBall.totalRuns,
        wickets: inning.wickets - (lastBall.isWicket ? 1 : 0),
        overs: newOvers,
      );

      final inningRef = _firestore.collection(_inningsCollection).doc(inningId);
      batch.update(inningRef, updatedInning.toMap());
    }

    await batch.commit();
  }

  // Helper to get player by ID
  Future<CricketPlayer?> _getPlayerById(String playerId) async {
    final doc = await _firestore
        .collection(_playersCollection)
        .doc(playerId)
        .get();
    
    if (!doc.exists) return null;
    return CricketPlayer.fromMap(doc.data()!);
  }

  // Check if over is complete
  bool isOverComplete(double overs) {
    int balls = ((overs - overs.floor()) * 10).round();
    return balls == 6 || balls == 0;
  }

  // Calculate current run rate
  double calculateRunRate(int runs, double overs) {
    if (overs == 0) return 0.0;
    return runs / overs;
  }

  // Calculate required run rate
  double calculateRequiredRunRate(int target, int scored, double oversRemaining) {
    if (oversRemaining == 0) return 0.0;
    return (target - scored) / oversRemaining;
  }
}
