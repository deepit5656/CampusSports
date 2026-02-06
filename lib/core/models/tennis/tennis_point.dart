import 'package:cloud_firestore/cloud_firestore.dart';

class TennisPoint {
  final String id;
  final String matchId;
  final String winnerId;
  final int set;
  final int game;
  final bool isAce;
  final bool isDoubleFault;
  final DateTime timestamp;

  const TennisPoint({
    required this.id,
    required this.matchId,
    required this.winnerId,
    required this.set,
    required this.game,
    this.isAce = false,
    this.isDoubleFault = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'winnerId': winnerId,
      'set': set,
      'game': game,
      'isAce': isAce,
      'isDoubleFault': isDoubleFault,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TennisPoint.fromMap(Map<String, dynamic> map) {
    return TennisPoint(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      winnerId: map['winnerId'] ?? '',
      set: map['set'] ?? 1,
      game: map['game'] ?? 1,
      isAce: map['isAce'] ?? false,
      isDoubleFault: map['isDoubleFault'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
