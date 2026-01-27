import 'package:cloud_firestore/cloud_firestore.dart';

class CricketPartnership {
  final String id;
  final String matchId;
  final String inningId;
  final String batsman1Id;
  final String batsman1Name;
  final int batsman1Runs;
  final String batsman2Id;
  final String batsman2Name;
  final int batsman2Runs;
  final int totalRuns;
  final int balls;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? endedAt;

  CricketPartnership({
    required this.id,
    required this.matchId,
    required this.inningId,
    required this.batsman1Id,
    required this.batsman1Name,
    this.batsman1Runs = 0,
    required this.batsman2Id,
    required this.batsman2Name,
    this.batsman2Runs = 0,
    this.totalRuns = 0,
    this.balls = 0,
    this.isActive = true,
    required this.startedAt,
    this.endedAt,
  });

  String get display => '$totalRuns runs ($balls balls)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningId': inningId,
      'batsman1Id': batsman1Id,
      'batsman1Name': batsman1Name,
      'batsman1Runs': batsman1Runs,
      'batsman2Id': batsman2Id,
      'batsman2Name': batsman2Name,
      'batsman2Runs': batsman2Runs,
      'totalRuns': totalRuns,
      'balls': balls,
      'isActive': isActive,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    };
  }

  factory CricketPartnership.fromMap(Map<String, dynamic> map) {
    return CricketPartnership(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      inningId: map['inningId'] ?? '',
      batsman1Id: map['batsman1Id'] ?? '',
      batsman1Name: map['batsman1Name'] ?? '',
      batsman1Runs: map['batsman1Runs'] ?? 0,
      batsman2Id: map['batsman2Id'] ?? '',
      batsman2Name: map['batsman2Name'] ?? '',
      batsman2Runs: map['batsman2Runs'] ?? 0,
      totalRuns: map['totalRuns'] ?? 0,
      balls: map['balls'] ?? 0,
      isActive: map['isActive'] ?? true,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      endedAt: map['endedAt'] != null 
          ? (map['endedAt'] as Timestamp).toDate() 
          : null,
    );
  }
}
