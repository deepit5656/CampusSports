import 'package:cloud_firestore/cloud_firestore.dart';

class CricketBowlingStats {
  final String id;
  final String matchId;
  final String inningId;
  final String playerId;
  final String playerName;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final int wides;
  final int noBalls;
  final int dotBalls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CricketBowlingStats({
    required this.id,
    required this.matchId,
    required this.inningId,
    required this.playerId,
    required this.playerName,
    this.overs = 0.0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.dotBalls = 0,
    required this.createdAt,
    this.updatedAt,
  });

  double get economyRate {
    if (overs == 0) return 0.0;
    return runs / overs;
  }

  String get displayEconomyRate => economyRate.toStringAsFixed(2);

  String get displayOvers {
    int completeOvers = overs.floor();
    int balls = ((overs - completeOvers) * 10).round();
    return '$completeOvers.$balls';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningId': inningId,
      'playerId': playerId,
      'playerName': playerName,
      'overs': overs,
      'maidens': maidens,
      'runs': runs,
      'wickets': wickets,
      'wides': wides,
      'noBalls': noBalls,
      'dotBalls': dotBalls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CricketBowlingStats.fromMap(Map<String, dynamic> map) {
    return CricketBowlingStats(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      inningId: map['inningId'] ?? '',
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      overs: (map['overs'] ?? 0.0).toDouble(),
      maidens: map['maidens'] ?? 0,
      runs: map['runs'] ?? 0,
      wickets: map['wickets'] ?? 0,
      wides: map['wides'] ?? 0,
      noBalls: map['noBalls'] ?? 0,
      dotBalls: map['dotBalls'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  CricketBowlingStats copyWith({
    String? id,
    String? matchId,
    String? inningId,
    String? playerId,
    String? playerName,
    double? overs,
    int? maidens,
    int? runs,
    int? wickets,
    int? wides,
    int? noBalls,
    int? dotBalls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CricketBowlingStats(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningId: inningId ?? this.inningId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      overs: overs ?? this.overs,
      maidens: maidens ?? this.maidens,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      dotBalls: dotBalls ?? this.dotBalls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
