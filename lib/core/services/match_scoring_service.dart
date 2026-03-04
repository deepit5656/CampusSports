import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sport_config_comprehensive.dart';

/// Enhanced match state model for universal scoring
class MatchState {
  final String matchId;
  final int currentInning;
  final int currentPeriod;
  final int currentTime; // seconds elapsed
  final Map<String, dynamic> currentScore;
  final List<String>? activePlayers;
  final String? currentAction;
  final bool isPaused;
  final String? pauseReason;
  final DateTime lastUpdated;

  const MatchState({
    required this.matchId,
    this.currentInning = 1,
    this.currentPeriod = 1,
    this.currentTime = 0,
    required this.currentScore,
    this.activePlayers,
    this.currentAction,
    this.isPaused = false,
    this.pauseReason,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'currentInning': currentInning,
      'currentPeriod': currentPeriod,
      'currentTime': currentTime,
      'currentScore': currentScore,
      'activePlayers': activePlayers,
      'currentAction': currentAction,
      'isPaused': isPaused,
      'pauseReason': pauseReason,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory MatchState.fromMap(Map<String, dynamic> map) {
    return MatchState(
      matchId: map['matchId'] ?? '',
      currentInning: map['currentInning'] ?? 1,
      currentPeriod: map['currentPeriod'] ?? 1,
      currentTime: map['currentTime'] ?? 0,
      currentScore: Map<String, dynamic>.from(map['currentScore'] ?? {}),
      activePlayers: map['activePlayers'] != null 
          ? List<String>.from(map['activePlayers']) 
          : null,
      currentAction: map['currentAction'],
      isPaused: map['isPaused'] ?? false,
      pauseReason: map['pauseReason'],
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MatchState copyWith({
    String? matchId,
    int? currentInning,
    int? currentPeriod,
    int? currentTime,
    Map<String, dynamic>? currentScore,
    List<String>? activePlayers,
    String? currentAction,
    bool? isPaused,
    String? pauseReason,
    DateTime? lastUpdated,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      currentInning: currentInning ?? this.currentInning,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      currentTime: currentTime ?? this.currentTime,
      currentScore: currentScore ?? this.currentScore,
      activePlayers: activePlayers ?? this.activePlayers,
      currentAction: currentAction ?? this.currentAction,
      isPaused: isPaused ?? this.isPaused,
      pauseReason: pauseReason ?? this.pauseReason,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Match event for ball-by-ball / action logging
class MatchEvent {
  final String id;
  final String eventType;
  final DateTime timestamp;
  final int? inningNumber;
  final int? periodNumber;
  final int? overNumber;
  final int? ballNumber;
  final Map<String, dynamic> eventData;
  final String? playerId;
  final String? teamId;
  final String? description;
  final bool isUndoable;

  const MatchEvent({
    required this.id,
    required this.eventType,
    required this.timestamp,
    this.inningNumber,
    this.periodNumber,
    this.overNumber,
    this.ballNumber,
    required this.eventData,
    this.playerId,
    this.teamId,
    this.description,
    this.isUndoable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType,
      'timestamp': Timestamp.fromDate(timestamp),
      'inningNumber': inningNumber,
      'periodNumber': periodNumber,
      'overNumber': overNumber,
      'ballNumber': ballNumber,
      'eventData': eventData,
      'playerId': playerId,
      'teamId': teamId,
      'description': description,
      'isUndoable': isUndoable,
    };
  }

  factory MatchEvent.fromMap(Map<String, dynamic> map) {
    return MatchEvent(
      id: map['id'] ?? '',
      eventType: map['eventType'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inningNumber: map['inningNumber'],
      periodNumber: map['periodNumber'],
      overNumber: map['overNumber'],
      ballNumber: map['ballNumber'],
      eventData: Map<String, dynamic>.from(map['eventData'] ?? {}),
      playerId: map['playerId'],
      teamId: map['teamId'],
      description: map['description'],
      isUndoable: map['isUndoable'] ?? true,
    );
  }
}

/// Match result
class MatchResult {
  final String winnerId;
  final String resultType;
  final int margin;
  final String description;
  final bool isTie;
  final bool wasTieBreaker;

  const MatchResult({
    required this.winnerId,
    required this.resultType,
    required this.margin,
    required this.description,
    this.isTie = false,
    this.wasTieBreaker = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'winnerId': winnerId,
      'resultType': resultType,
      'margin': margin,
      'description': description,
      'isTie': isTie,
      'wasTieBreaker': wasTieBreaker,
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      winnerId: map['winnerId'] ?? '',
      resultType: map['resultType'] ?? '',
      margin: map['margin'] ?? 0,
      description: map['description'] ?? '',
      isTie: map['isTie'] ?? false,
      wasTieBreaker: map['wasTieBreaker'] ?? false,
    );
  }
}

/// Player statistics
class PlayerStats {
  final String playerId;
  final String role;
  final Map<String, dynamic> stats;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;

  const PlayerStats({
    required this.playerId,
    required this.role,
    required this.stats,
    this.isActive = true,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'role': role,
      'stats': stats,
      'isActive': isActive,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      playerId: map['playerId'] ?? '',
      role: map['role'] ?? '',
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
      isActive: map['isActive'] ?? true,
      startTime: (map['startTime'] as Timestamp?)?.toDate(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
    );
  }
}

/// Match Scoring Service
class MatchScoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize match with settings
  Future<void> initializeMatch(
    String matchId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('match_states').doc(matchId).set({
        'matchId': matchId,
        'currentInning': 1,
        'currentPeriod': 1,
        'currentTime': 0,
        'currentScore': {},
        'activePlayers': settings['activePlayers'] ?? [],
        'isPaused': false,
        'lastUpdated': FieldValue.serverTimestamp(),
        'settings': settings,
      });

      // Initialize events collection
      await _firestore
          .collection('match_states')
          .doc(matchId)
          .collection('events')
          .doc('init')
          .set({
        'eventType': 'match_initialized',
        'timestamp': FieldValue.serverTimestamp(),
        'eventData': settings,
      });

      print('✅ Match initialized: $matchId');
    } catch (e) {
      print('❌ Error initializing match: $e');
      rethrow;
    }
  }

  /// Record a score action
  Future<void> recordAction(
    String matchId,
    ScoreAction action,
    Map<String, dynamic> data,
  ) async {
    try {
      final eventId = DateTime.now().millisecondsSinceEpoch.toString();
      final event = MatchEvent(
        id: eventId,
        eventType: action.category,
        timestamp: DateTime.now(),
        eventData: {
          'actionId': action.id,
          'actionName': action.name,
          'value': action.value,
          ...data,
        },
        playerId: data['playerId'],
        teamId: data['teamId'],
        description: _generateEventDescription(action, data),
        isUndoable: true,
      );

      // Save event
      await _firestore
          .collection('match_states')
          .doc(matchId)
          .collection('events')
          .doc(eventId)
          .set(event.toMap());

      // Update match state
      await _updateMatchState(matchId, action, data);

      print('✅ Action recorded: ${action.name}');
    } catch (e) {
      print('❌ Error recording action: $e');
      rethrow;
    }
  }

  /// Undo last action
  Future<void> undoLastAction(String matchId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('match_states')
          .doc(matchId)
          .collection('events')
          .where('isUndoable', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (eventsSnapshot.docs.isEmpty) {
        throw Exception('No undoable actions found');
      }

      final lastEvent = eventsSnapshot.docs.first;
      await lastEvent.reference.delete();

      // Recalculate state from remaining events
      await _recalculateMatchState(matchId);

      print('✅ Last action undone');
    } catch (e) {
      print('❌ Error undoing action: $e');
      rethrow;
    }
  }

  /// Get live match state
  Stream<MatchState?> getMatchState(String matchId) {
    return _firestore
        .collection('match_states')
        .doc(matchId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return MatchState.fromMap(snapshot.data()!);
    });
  }

  /// Get match events
  Stream<List<MatchEvent>> getMatchEvents(String matchId) {
    return _firestore
        .collection('match_states')
        .doc(matchId)
        .collection('events')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchEvent.fromMap(doc.data()))
          .toList();
    });
  }

  /// Complete match and calculate result
  Future<MatchResult> completeMatch(
    String matchId,
    SportConfigModel sport,
  ) async {
    try {
      final stateDoc = await _firestore
          .collection('match_states')
          .doc(matchId)
          .get();

      final state = MatchState.fromMap(stateDoc.data()!);
      final result = _calculateResult(state, sport);

      // Update match document
      await _firestore.collection('matches').doc(matchId).update({
        'status': 'completed',
        'result': result.toMap(),
        'winnerId': result.winnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Match completed: ${result.description}');
      return result;
    } catch (e) {
      print('❌ Error completing match: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<void> _updateMatchState(
    String matchId,
    ScoreAction action,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('match_states').doc(matchId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final currentScore = Map<String, dynamic>.from(doc.data()?['currentScore'] ?? {});

      // Update score based on action
      final teamId = data['teamId'] as String;
      currentScore[teamId] = (currentScore[teamId] ?? 0) + action.value;

      transaction.update(docRef, {
        'currentScore': currentScore,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _recalculateMatchState(String matchId) async {
    // This would recalculate the entire match state from events
    // For now, just update timestamp
    await _firestore.collection('match_states').doc(matchId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  String _generateEventDescription(ScoreAction action, Map<String, dynamic> data) {
    return '${action.name} - ${data['teamId']}';
  }

  MatchResult _calculateResult(MatchState state, SportConfigModel sport) {
    final scores = state.currentScore;
    if (scores.isEmpty) {
      return MatchResult(
        winnerId: '',
        resultType: 'no_result',
        margin: 0,
        description: 'Match abandoned',
      );
    }

    final entries = scores.entries.toList();
    entries.sort((a, b) => (b.value as num).compareTo(a.value as num));

    if (entries.length >= 2 && entries[0].value == entries[1].value) {
      return MatchResult(
        winnerId: '',
        resultType: 'tie',
        margin: 0,
        description: 'Match tied',
        isTie: true,
      );
    }

    final winner = entries[0];
    final margin = entries.length >= 2 
        ? winner.value - entries[1].value 
        : winner.value;

    return MatchResult(
      winnerId: winner.key,
      resultType: sport.primaryScoreUnit,
      margin: margin as int,
      description: 'Won by $margin ${sport.primaryScoreUnit}${margin != 1 ? 's' : ''}',
    );
  }
}
