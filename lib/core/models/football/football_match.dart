import 'package:cloud_firestore/cloud_firestore.dart';

class FootballMatch {
  final String id;
  final String sportId;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final String status; // 'pending', 'ongoing', 'completed'
  final int currentHalf; // 1 or 2
  final int halfDuration; // minutes per half (typically 45)
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;

  const FootballMatch({
    required this.id,
    required this.sportId,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
    this.team1Score = 0,
    this.team2Score = 0,
    this.status = 'pending',
    this.currentHalf = 1,
    this.halfDuration = 45,
    this.winnerId,
    required this.createdAt,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sportId': sportId,
      'team1Id': team1Id,
      'team1Name': team1Name,
      'team2Id': team2Id,
      'team2Name': team2Name,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'status': status,
      'currentHalf': currentHalf,
      'halfDuration': halfDuration,
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory FootballMatch.fromMap(Map<String, dynamic> map) {
    return FootballMatch(
      id: map['id'] ?? '',
      sportId: map['sportId'] ?? '',
      team1Id: map['team1Id'] ?? '',
      team1Name: map['team1Name'] ?? '',
      team2Id: map['team2Id'] ?? '',
      team2Name: map['team2Name'] ?? '',
      team1Score: map['team1Score'] ?? 0,
      team2Score: map['team2Score'] ?? 0,
      status: map['status'] ?? 'pending',
      currentHalf: map['currentHalf'] ?? 1,
      halfDuration: map['halfDuration'] ?? 45,
      winnerId: map['winnerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
    );
  }

  FootballMatch copyWith({
    String? id,
    String? sportId,
    String? team1Id,
    String? team1Name,
    String? team2Id,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    String? status,
    int? currentHalf,
    int? halfDuration,
    String? winnerId,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return FootballMatch(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      team1Id: team1Id ?? this.team1Id,
      team1Name: team1Name ?? this.team1Name,
      team2Id: team2Id ?? this.team2Id,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      status: status ?? this.status,
      currentHalf: currentHalf ?? this.currentHalf,
      halfDuration: halfDuration ?? this.halfDuration,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

enum FootballEventType {
  goal,
  penalty,
  ownGoal,
  yellowCard,
  redCard,
  substitution,
}

class FootballEvent {
  final String id;
  final String matchId;
  final String teamId;
  final FootballEventType eventType;
  final int minute;
  final String playerId;
  final String playerName;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final String? substitutedPlayerId;
  final String? substitutedPlayerName;
  final DateTime timestamp;

  const FootballEvent({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.eventType,
    required this.minute,
    required this.playerId,
    required this.playerName,
    this.assistPlayerId,
    this.assistPlayerName,
    this.substitutedPlayerId,
    this.substitutedPlayerName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'teamId': teamId,
      'eventType': eventType.name,
      'minute': minute,
      'playerId': playerId,
      'playerName': playerName,
      'assistPlayerId': assistPlayerId,
      'assistPlayerName': assistPlayerName,
      'substitutedPlayerId': substitutedPlayerId,
      'substitutedPlayerName': substitutedPlayerName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FootballEvent.fromMap(Map<String, dynamic> map) {
    return FootballEvent(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      teamId: map['teamId'] ?? '',
      eventType: FootballEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => FootballEventType.goal,
      ),
      minute: map['minute'] ?? 0,
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      assistPlayerId: map['assistPlayerId'],
      assistPlayerName: map['assistPlayerName'],
      substitutedPlayerId: map['substitutedPlayerId'],
      substitutedPlayerName: map['substitutedPlayerName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
