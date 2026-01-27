import 'package:cloud_firestore/cloud_firestore.dart';

class CricketBattingStats {
  final String id;
  final String matchId;
  final String inningId;
  final String playerId;
  final String playerName;
  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final bool isOut;
  final String? howOut;  // "c Fielder b Bowler", "b Bowler", "lbw b Bowler", etc.
  final String? dismissedBy;  // Bowler's name
  final String? fielder;  // Fielder's name (for catches, run-outs)
  final int position;  // Batting order
  final DateTime createdAt;
  final DateTime? updatedAt;

  CricketBattingStats({
    required this.id,
    required this.matchId,
    required this.inningId,
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.howOut,
    this.dismissedBy,
    this.fielder,
    required this.position,
    required this.createdAt,
    this.updatedAt,
  });

  double get strikeRate {
    if (ballsFaced == 0) return 0.0;
    return (runs / ballsFaced) * 100;
  }

  String get displayStrikeRate => strikeRate.toStringAsFixed(2);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningId': inningId,
      'playerId': playerId,
      'playerName': playerName,
      'runs': runs,
      'ballsFaced': ballsFaced,
      'fours': fours,
      'sixes': sixes,
      'isOut': isOut,
      'howOut': howOut,
      'dismissedBy': dismissedBy,
      'fielder': fielder,
      'position': position,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CricketBattingStats.fromMap(Map<String, dynamic> map) {
    return CricketBattingStats(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      inningId: map['inningId'] ?? '',
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      runs: map['runs'] ?? 0,
      ballsFaced: map['ballsFaced'] ?? 0,
      fours: map['fours'] ?? 0,
      sixes: map['sixes'] ?? 0,
      isOut: map['isOut'] ?? false,
      howOut: map['howOut'],
      dismissedBy: map['dismissedBy'],
      fielder: map['fielder'],
      position: map['position'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  CricketBattingStats copyWith({
    String? id,
    String? matchId,
    String? inningId,
    String? playerId,
    String? playerName,
    int? runs,
    int? ballsFaced,
    int? fours,
    int? sixes,
    bool? isOut,
    String? howOut,
    String? dismissedBy,
    String? fielder,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CricketBattingStats(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningId: inningId ?? this.inningId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      howOut: howOut ?? this.howOut,
      dismissedBy: dismissedBy ?? this.dismissedBy,
      fielder: fielder ?? this.fielder,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
