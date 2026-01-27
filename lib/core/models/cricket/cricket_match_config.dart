import 'package:cloud_firestore/cloud_firestore.dart';

enum TossDecision { bat, bowl }

enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  hitBallTwice,
  obstructingField,
  retired,
  timedOut
}

class CricketMatchConfig {
  final String matchId;
  final String team1Id;
  final String team2Id;
  final int totalOvers;
  final String tossWonBy; // team1Id or team2Id
  final TossDecision tossDecision;
  final int playersPerTeam;
  
  // Advanced settings
  final bool noBallReball;
  final int noBallRuns;
  final bool wideBallReball;
  final int wideBallRuns;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  CricketMatchConfig({
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.totalOvers,
    required this.tossWonBy,
    required this.tossDecision,
    this.playersPerTeam = 11,
    this.noBallReball = true,
    this.noBallRuns = 1,
    this.wideBallReball = true,
    this.wideBallRuns = 1,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'totalOvers': totalOvers,
      'tossWonBy': tossWonBy,
      'tossDecision': tossDecision.name,
      'playersPerTeam': playersPerTeam,
      'noBallReball': noBallReball,
      'noBallRuns': noBallRuns,
      'wideBallReball': wideBallReball,
      'wideBallRuns': wideBallRuns,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CricketMatchConfig.fromMap(Map<String, dynamic> map) {
    return CricketMatchConfig(
      matchId: map['matchId'] ?? '',
      team1Id: map['team1Id'] ?? '',
      team2Id: map['team2Id'] ?? '',
      totalOvers: map['totalOvers'] ?? 20,
      tossWonBy: map['tossWonBy'] ?? '',
      tossDecision: TossDecision.values.firstWhere(
        (e) => e.name == map['tossDecision'],
        orElse: () => TossDecision.bat,
      ),
      playersPerTeam: map['playersPerTeam'] ?? 11,
      noBallReball: map['noBallReball'] ?? true,
      noBallRuns: map['noBallRuns'] ?? 1,
      wideBallReball: map['wideBallReball'] ?? true,
      wideBallRuns: map['wideBallRuns'] ?? 1,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  CricketMatchConfig copyWith({
    String? matchId,
    String? team1Id,
    String? team2Id,
    int? totalOvers,
    String? tossWonBy,
    TossDecision? tossDecision,
    int? playersPerTeam,
    bool? noBallReball,
    int? noBallRuns,
    bool? wideBallReball,
    int? wideBallRuns,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CricketMatchConfig(
      matchId: matchId ?? this.matchId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      totalOvers: totalOvers ?? this.totalOvers,
      tossWonBy: tossWonBy ?? this.tossWonBy,
      tossDecision: tossDecision ?? this.tossDecision,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      noBallReball: noBallReball ?? this.noBallReball,
      noBallRuns: noBallRuns ?? this.noBallRuns,
      wideBallReball: wideBallReball ?? this.wideBallReball,
      wideBallRuns: wideBallRuns ?? this.wideBallRuns,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
