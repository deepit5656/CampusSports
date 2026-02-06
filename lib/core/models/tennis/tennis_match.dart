import 'package:cloud_firestore/cloud_firestore.dart';

class TennisMatch {
  final String id;
  final String sportId;
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;
  final int totalSets; // 3 or 5
  final int player1Sets;
  final int player2Sets;
  final int currentSet;
  final Map<int, Map<String, int>> setScores; // {1: {player1Id: 6, player2Id: 4}}
  final Map<String, String> currentGameScore; // {player1Id: '40', player2Id: '30'}
  final String status; // 'pending', 'ongoing', 'completed'
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;

  const TennisMatch({
    required this.id,
    required this.sportId,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    this.totalSets = 3,
    this.player1Sets = 0,
    this.player2Sets = 0,
    this.currentSet = 1,
    required this.setScores,
    required this.currentGameScore,
    this.status = 'pending',
    this.winnerId,
    required this.createdAt,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sportId': sportId,
      'player1Id': player1Id,
      'player1Name': player1Name,
      'player2Id': player2Id,
      'player2Name': player2Name,
      'totalSets': totalSets,
      'player1Sets': player1Sets,
      'player2Sets': player2Sets,
      'currentSet': currentSet,
      'setScores': setScores.map((key, value) => MapEntry(key.toString(), value)),
      'currentGameScore': currentGameScore,
      'status': status,
      'winnerId': winnerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory TennisMatch.fromMap(Map<String, dynamic> map) {
    return TennisMatch(
      id: map['id'] ?? '',
      sportId: map['sportId'] ?? '',
      player1Id: map['player1Id'] ?? '',
      player1Name: map['player1Name'] ?? '',
      player2Id: map['player2Id'] ?? '',
      player2Name: map['player2Name'] ?? '',
      totalSets: map['totalSets'] ?? 3,
      player1Sets: map['player1Sets'] ?? 0,
      player2Sets: map['player2Sets'] ?? 0,
      currentSet: map['currentSet'] ?? 1,
      setScores: (map['setScores'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          int.parse(key),
          Map<String, int>.from(value as Map),
        ),
      ),
      currentGameScore: Map<String, String>.from(map['currentGameScore'] ?? {}),
      status: map['status'] ?? 'pending',
      winnerId: map['winnerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
    );
  }

  TennisMatch copyWith({
    String? id,
    String? sportId,
    String? player1Id,
    String? player1Name,
    String? player2Id,
    String? player2Name,
    int? totalSets,
    int? player1Sets,
    int? player2Sets,
    int? currentSet,
    Map<int, Map<String, int>>? setScores,
    Map<String, String>? currentGameScore,
    String? status,
    String? winnerId,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TennisMatch(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      player1Id: player1Id ?? this.player1Id,
      player1Name: player1Name ?? this.player1Name,
      player2Id: player2Id ?? this.player2Id,
      player2Name: player2Name ?? this.player2Name,
      totalSets: totalSets ?? this.totalSets,
      player1Sets: player1Sets ?? this.player1Sets,
      player2Sets: player2Sets ?? this.player2Sets,
      currentSet: currentSet ?? this.currentSet,
      setScores: setScores ?? this.setScores,
      currentGameScore: currentGameScore ?? this.currentGameScore,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
