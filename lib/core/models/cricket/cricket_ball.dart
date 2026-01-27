import 'package:cloud_firestore/cloud_firestore.dart';
import 'cricket_match_config.dart';

enum BallType { 
  normal, 
  wide, 
  noBall, 
  bye, 
  legBye, 
  wicket,
  widePlusRuns,
  noBallPlusRuns,
}

class CricketBall {
  final String id;
  final String matchId;
  final String inningId;
  final int overNumber;
  final int ballNumber;  // 1-6 (or more if extras)
  final String batsmanId;
  final String nonStrikerId;
  final String bowlerId;
  final BallType ballType;
  final int runs;  // Runs scored off this ball
  final int extras;  // Extra runs (wide, no-ball, byes, leg-byes)
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? fielder1Id;  // For caught, run-out, stumped
  final String? fielder2Id;  // For run-out (second fielder)
  final bool isFour;
  final bool isSix;
  final String? commentary;
  final DateTime createdAt;

  CricketBall({
    required this.id,
    required this.matchId,
    required this.inningId,
    required this.overNumber,
    required this.ballNumber,
    required this.batsmanId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.ballType,
    required this.runs,
    this.extras = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielder1Id,
    this.fielder2Id,
    this.isFour = false,
    this.isSix = false,
    this.commentary,
    required this.createdAt,
  });

  int get totalRuns => runs + extras;

  bool get isValidBall => ballType != BallType.wide && ballType != BallType.noBall;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'inningId': inningId,
      'overNumber': overNumber,
      'ballNumber': ballNumber,
      'batsmanId': batsmanId,
      'nonStrikerId': nonStrikerId,
      'bowlerId': bowlerId,
      'ballType': ballType.name,
      'runs': runs,
      'extras': extras,
      'isWicket': isWicket,
      'wicketType': wicketType?.name,
      'dismissedPlayerId': dismissedPlayerId,
      'fielder1Id': fielder1Id,
      'fielder2Id': fielder2Id,
      'isFour': isFour,
      'isSix': isSix,
      'commentary': commentary,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CricketBall.fromMap(Map<String, dynamic> map) {
    return CricketBall(
      id: map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      inningId: map['inningId'] ?? '',
      overNumber: map['overNumber'] ?? 0,
      ballNumber: map['ballNumber'] ?? 0,
      batsmanId: map['batsmanId'] ?? '',
      nonStrikerId: map['nonStrikerId'] ?? '',
      bowlerId: map['bowlerId'] ?? '',
      ballType: BallType.values.firstWhere(
        (e) => e.name == map['ballType'],
        orElse: () => BallType.normal,
      ),
      runs: map['runs'] ?? 0,
      extras: map['extras'] ?? 0,
      isWicket: map['isWicket'] ?? false,
      wicketType: map['wicketType'] != null
          ? WicketType.values.firstWhere(
              (e) => e.name == map['wicketType'],
              orElse: () => WicketType.bowled,
            )
          : null,
      dismissedPlayerId: map['dismissedPlayerId'],
      fielder1Id: map['fielder1Id'],
      fielder2Id: map['fielder2Id'],
      isFour: map['isFour'] ?? false,
      isSix: map['isSix'] ?? false,
      commentary: map['commentary'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
