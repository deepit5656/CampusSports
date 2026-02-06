import 'package:flutter/material.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/theme/app_theme.dart';

class DynamicScoreDisplay extends StatelessWidget {
  final MatchModel match;
  final SportModel sport;
  final TeamModel team1;
  final TeamModel team2;
  final bool showDetailedView;

  const DynamicScoreDisplay({
    super.key,
    required this.match,
    required this.sport,
    required this.team1,
    required this.team2,
    this.showDetailedView = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Main score display
          _buildMainScoreDisplay(context),
          
          if (showDetailedView && match.hasDetailedScore)
            ...[
              const SizedBox(height: 24),
              _buildDetailedScoreBreakdown(context),
            ],
            
          if (match.isCompleted && match.winnerId != null)
            ...[
              const SizedBox(height: 16),
              _buildMatchResult(context),
            ],
        ],
      ),
    );
  }

  Widget _buildMainScoreDisplay(BuildContext context) {
    return Row(
      children: [
        // Team 1
        Expanded(
          child: Column(
            children: [
              Text(
                team1.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getFormattedTeamScore(team1.id),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (match.winnerId == team1.id)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WINNER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Sport icon and VS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                sport.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Team 2
        Expanded(
          child: Column(
            children: [
              Text(
                team2.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getFormattedTeamScore(team2.id),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (match.winnerId == team2.id)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WINNER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedScoreBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team 1 detailed scores
              Expanded(
                child: _buildTeamDetailedScore(team1.id, team1.name),
              ),
              
              const SizedBox(width: 16),
              
              // Team 2 detailed scores
              Expanded(
                child: _buildTeamDetailedScore(team2.id, team2.name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetailedScore(String teamId, String teamName) {
    final teamScore = match.detailedScore?[teamId];
    if (teamScore == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        ...sport.allFieldsSorted.map((field) {
          final value = teamScore.scores[field.id];
          if (value == null) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${field.name}:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: field.isPrimary ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${value}${field.unit != null ? ' ${field.unit}' : ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: field.isPrimary ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMatchResult(BuildContext context) {
    final winnerName = match.winnerId == team1.id ? team1.name : team2.name;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successColor, width: 1),
      ),
      child: Text(
        'Result: $winnerName won',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getFormattedTeamScore(String teamId) {
    if (match.hasDetailedScore) {
      final teamScore = match.detailedScore?[teamId];
      if (teamScore != null) {
        final cardFields = sport.cardDisplayFields;
        if (cardFields.length > 1) {
          // Show combined score like "245/8" for cricket
          return cardFields.map((field) {
            final value = teamScore.scores[field.id];
            return value?.toString() ?? '0';
          }).join('/');
        } else if (cardFields.isNotEmpty) {
          // Show single primary score
          final value = teamScore.scores[cardFields.first.id];
          return value?.toString() ?? '0';
        }
      }
      return '0';
    } else if (match.score != null) {
      // Legacy score display
      return match.score![teamId]?.toString() ?? '0';
    }
    
    return '-';
  }
}