import 'cricket_ball.dart';

class CricketOver {
  final int overNumber;
  final String bowlerId;
  final String bowlerName;
  final List<CricketBall> balls;
  final int runs;
  final int wickets;
  final int extras;
  final bool isMaiden;

  CricketOver({
    required this.overNumber,
    required this.bowlerId,
    required this.bowlerName,
    required this.balls,
    required this.runs,
    required this.wickets,
    required this.extras,
    this.isMaiden = false,
  });

  String get displayOver => '$overNumber.${balls.length}';
  
  String get displayRuns => wickets > 0 ? '$runs/$wickets' : '$runs';

  List<String> get ballsDisplay {
    return balls.map((ball) {
      if (ball.isWicket) return 'W';
      if (ball.ballType == BallType.wide) return 'WD';
      if (ball.ballType == BallType.noBall) return 'NB';
      if (ball.isSix) return '6';
      if (ball.isFour) return '4';
      return ball.runs.toString();
    }).toList();
  }
}
