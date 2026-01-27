import 'package:cloud_firestore/cloud_firestore.dart';

class CricketInning {
  final String id;
  final String matchId;
  final String battingTeamId;
  final String bowlingTeamId;
  final int inningNumber;  // 1 or 2
  final int totalRuns;
  final int wickets;
  final double overs;
  final int extras;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final bool isCompleted;
  final String? currentStrikerId;
  final String? currentNonStrikerId;
  final String? currentBowlerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  CricketInning({
    required this.id,
    required this.matchId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.inningNumber,
    this.totalRuns = 0,
    this.wickets = 0,
    this.overs = 0.0,
    this.extras = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.isCompleted = false,
    this.currentStrikerId,
    this.currentNonStrikerId,
    this.currentBowlerId,
    required this.createdAt,
    this.completedAt,
  });

  double get currentRunRate {
    if (overs == 0) return 0.0;
    return totalRuns / overs;
  }

  String get displayScore => '$totalRuns-$wickets ($overs)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'inningNumber': inningNumber,
      'totalRuns': totalRuns,
      'wickets': wickets,
      'overs': overs,
      'extras': extras,
      'wides': wides,
      'noBalls': noBalls,
      'byes': byes,
      'legByes': legByes,
      'isCompleted': isCompleted,
      'currentStrikerId': currentStrikerId,
      'currentNonStrikerId': currentNonStrikerId,
      'currentBowlerId': currentBowlerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory CricketInning.fromMap(Map<String, dynamic> map) {
    return CricketInning(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      battingTeamId: map['battingTeamId'] ?? '',
      bowlingTeamId: map['bowlingTeamId'] ?? '',
      inningNumber: map['inningNumber'] ?? 1,
      totalRuns: map['totalRuns'] ?? 0,
      wickets: map['wickets'] ?? 0,
      overs: (map['overs'] ?? 0.0).toDouble(),
      extras: map['extras'] ?? 0,
      wides: map['wides'] ?? 0,
      noBalls: map['noBalls'] ?? 0,
      byes: map['byes'] ?? 0,
      legByes: map['legByes'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      currentStrikerId: map['currentStrikerId'],
      currentNonStrikerId: map['currentNonStrikerId'],
      currentBowlerId: map['currentBowlerId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  CricketInning copyWith({
    String? id,
    String? matchId,
    String? battingTeamId,
    String? bowlingTeamId,
    int? inningNumber,
    int? totalRuns,
    int? wickets,
    double? overs,
    int? extras,
    int? wides,
    int? noBalls,
    int? byes,
    int? legByes,
    bool? isCompleted,
    String? currentStrikerId,
    String? currentNonStrikerId,
    String? currentBowlerId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return CricketInning(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      inningNumber: inningNumber ?? this.inningNumber,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
      extras: extras ?? this.extras,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
      byes: byes ?? this.byes,
      legByes: legByes ?? this.legByes,
      isCompleted: isCompleted ?? this.isCompleted,
      currentStrikerId: currentStrikerId ?? this.currentStrikerId,
      currentNonStrikerId: currentNonStrikerId ?? this.currentNonStrikerId,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
