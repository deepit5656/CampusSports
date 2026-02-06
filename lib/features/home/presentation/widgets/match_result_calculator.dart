import 'package:flutter/material.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/theme/app_theme.dart';

class MatchResultCalculator {
  static String calculateResult(
    MatchModel match,
    SportModel sport,
    TeamModel team1,
    TeamModel team2,
  ) {
    if (!match.isCompleted) return 'Match not completed';
    
    if (match.winnerId == null) {
      return _getDrawResult(match, sport, team1, team2);
    }
    
    final winnerName = match.winnerId == team1.id ? team1.name : team2.name;
    
    // Get winning margin based on sport type
    final margin = _getWinningMargin(match, sport, team1, team2);
    
    if (margin.isNotEmpty) {
      return '$winnerName won by $margin';
    }
    
    return '$winnerName won';
  }

  static String _getDrawResult(
    MatchModel match,
    SportModel sport,
    TeamModel team1,
    TeamModel team2,
  ) {
    final scoreType = sport.scoringConfig.scoreType;
    
    switch (scoreType) {
      case 'runs':
        return 'Match tied';
      case 'goals':
        return 'Match drawn';
      case 'points':
        return 'Match tied';
      case 'sets':
      case 'games':
        return 'Match tied';
      default:
        return 'Match drawn';
    }
  }

  static String _getWinningMargin(
    MatchModel match,
    SportModel sport,
    TeamModel team1,
    TeamModel team2,
  ) {
    if (!match.hasDetailedScore) return '';
    
    final winnerScore = match.detailedScore![match.winnerId!];
    final loserScore = match.detailedScore![match.winnerId == team1.id ? team2.id : team1.id];
    
    if (winnerScore == null || loserScore == null) return '';
    
    final primaryField = sport.primaryScoreField;
    final winnerPrimary = winnerScore.scores[primaryField.id] ?? 0;
    final loserPrimary = loserScore.scores[primaryField.id] ?? 0;
    
    final scoreType = sport.scoringConfig.scoreType;
    final difference = winnerPrimary - loserPrimary;
    
    switch (scoreType) {
      case 'runs':
        return _getCricketMargin(match, sport, winnerScore, loserScore);
      case 'goals':
        return difference == 1 ? '1 goal' : '$difference goals';
      case 'points':
        return difference == 1 ? '1 point' : '$difference points';
      case 'sets':
        return difference == 1 ? '1 set' : '$difference sets';
      case 'games':
        return difference == 1 ? '1 game' : '$difference games';
      default:
        return difference == 1 ? '1 point' : '$difference points';
    }
  }

  static String _getCricketMargin(
    MatchModel match,
    SportModel sport,
    dynamic winnerScore,
    dynamic loserScore,
  ) {
    // Cricket-specific margin calculation
    final winnerRuns = winnerScore.scores['runs'] ?? 0;
    final loserRuns = loserScore.scores['runs'] ?? 0;
    final loserWickets = loserScore.scores['wickets'] ?? 0;
    
    // If team batting second wins, margin is by wickets
    // If team batting first wins, margin is by runs
    
    // This is a simplified logic - in a real app, you'd track batting order
    if (loserWickets == 10) {
      // Team was bowled out, winner won by runs
      final margin = winnerRuns - loserRuns;
      return margin == 1 ? '1 run' : '$margin runs';
    } else {
      // Team chasing didn't get bowled out, winner won by wickets
      final wicketsRemaining = 10 - loserWickets;
      return wicketsRemaining == 1 ? '1 wicket' : '$wicketsRemaining wickets';
    }
  }
}

class MatchResultDisplay extends StatelessWidget {
  final MatchModel match;
  final SportModel sport;
  final TeamModel team1;
  final TeamModel team2;
  final bool compact;

  const MatchResultDisplay({
    super.key,
    required this.match,
    required this.sport,
    required this.team1,
    required this.team2,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!match.isCompleted) {
      return _buildStatusChip(
        _getStatusText(),
        _getStatusColor(),
      );
    }

    final result = MatchResultCalculator.calculateResult(match, sport, team1, team2);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: match.winnerId != null
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: match.winnerId != null ? AppTheme.successColor : AppTheme.warningColor,
          width: 1,
        ),
      ),
      child: Text(
        result,
        style: TextStyle(
          color: match.winnerId != null ? AppTheme.successColor : AppTheme.warningColor,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusText() {
    if (match.isUpcoming) return 'Upcoming';
    if (match.isLive) return 'Live';
    if (match.isCancelled) return 'Cancelled';
    return 'Unknown';
  }

  Color _getStatusColor() {
    if (match.isUpcoming) return AppTheme.accentGradientStart;
    if (match.isLive) return AppTheme.successColor;
    if (match.isCancelled) return AppTheme.errorColor;
    return AppTheme.textSecondary;
  }
}