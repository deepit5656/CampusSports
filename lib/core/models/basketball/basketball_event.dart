import 'package:cloud_firestore/cloud_firestore.dart';

enum BasketballEventType {
  freeThrow,
  twoPointer,
  threePointer,
  foul,
  rebound,
  assist,
  steal,
  block,
  turnover,
}

class BasketballEvent {
  final String id;
  final String matchId;
  final String teamId;
  final BasketballEventType eventType;
  final int quarter;
  final String playerId;
  final String playerName;
  final int? points;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final DateTime timestamp;

  const BasketballEvent({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.eventType,
    required this.quarter,
    required this.playerId,
    required this.playerName,
    this.points,
    this.assistPlayerId,
    this.assistPlayerName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'teamId': teamId,
      'eventType': eventType.name,
      'quarter': quarter,
      'playerId': playerId,
      'playerName': playerName,
      'points': points,
      'assistPlayerId': assistPlayerId,
      'assistPlayerName': assistPlayerName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory BasketballEvent.fromMap(Map<String, dynamic> map) {
    return BasketballEvent(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      teamId: map['teamId'] ?? '',
      eventType: BasketballEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => BasketballEventType.twoPointer,
      ),
      quarter: map['quarter'] ?? 1,
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      points: map['points'],
      assistPlayerId: map['assistPlayerId'],
      assistPlayerName: map['assistPlayerName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
