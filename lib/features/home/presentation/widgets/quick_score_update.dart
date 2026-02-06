import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/sport_model.dart';

class QuickScoreUpdate extends StatefulWidget {
  final MatchModel match;
  final TeamModel team1;
  final TeamModel team2;
  final SportModel? sport;

  const QuickScoreUpdate({
    super.key,
    required this.match,
    required this.team1,
    required this.team2,
    this.sport,
  });

  @override
  State<QuickScoreUpdate> createState() => _QuickScoreUpdateState();
}

class _QuickScoreUpdateState extends State<QuickScoreUpdate> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUpdating = false;
  SportModel? _sport;

  @override
  void initState() {
    super.initState();
    _sport = widget.sport;
    if (_sport == null && widget.match.sportId.isNotEmpty) {
      _fetchSport();
    }
  }

  void _fetchSport() async {
    try {
      final doc = await _firestore
          .collection('sports')
          .doc(widget.match.sportId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _sport = SportModel.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      print('Error fetching sport: $e');
    }
  }

  String get team1ScoreDisplay {
    if (_sport != null && widget.match.hasDetailedScore) {
      final teamScore = widget.match.getTeamScore(widget.match.team1Id);
      if (teamScore != null) {
        final formatted = _sport!.getFormattedScore(teamScore);
        return '${formatted.primary} ${formatted.secondary}'.trim();
      }
    }
    return 'Score: ${widget.match.score?[widget.match.team1Id] ?? 0}';
  }

  String get team2ScoreDisplay {
    if (_sport != null && widget.match.hasDetailedScore) {
      final teamScore = widget.match.getTeamScore(widget.match.team2Id);
      if (teamScore != null) {
        final formatted = _sport!.getFormattedScore(teamScore);
        return '${formatted.primary} ${formatted.secondary}'.trim();
      }
    }
    return 'Score: ${widget.match.score?[widget.match.team2Id] ?? 0}';
  }

  Future<void> _updateScore(String teamId, int delta) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final currentScore = widget.match.score ?? {};
      final newScore = (currentScore[teamId] ?? 0) + delta;

      if (newScore < 0) {
        setState(() => _isUpdating = false);
        return;
      }

      final updatedScore = {...currentScore, teamId: newScore};

      await _firestore.collection('matches').doc(widget.match.id).update({
        'score': updatedScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Score updated successfully'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating score: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGradientStart.withOpacity(0.2),
            AppTheme.primaryGradientEnd.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGradientStart.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: AppTheme.primaryGradientStart,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Score Update',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGradientStart,
                    ),
              ),
              const Spacer(),
              if (_isUpdating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGradientStart,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Team 1 Score Controls
          _buildScoreControl(
            context,
            widget.team1.name,
            team1ScoreDisplay,
            widget.match.team1Id,
            AppTheme.primaryGradientStart,
          ),

          const SizedBox(height: 16),

          // Team 2 Score Controls
          _buildScoreControl(
            context,
            widget.team2.name,
            team2ScoreDisplay,
            widget.match.team2Id,
            AppTheme.accentGradientStart,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreControl(
    BuildContext context,
    String teamName,
    String scoreDisplay,
    String teamId,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  scoreDisplay,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              // Decrease button
              _buildScoreButton(
                icon: Icons.remove,
                onTap: () => _updateScore(teamId, -1),
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 12),
              // Increase button
              _buildScoreButton(
                icon: Icons.add,
                onTap: () => _updateScore(teamId, 1),
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 12),
              // +5 button
              _buildScoreButton(
                icon: Icons.exposure_plus_2,
                label: '+5',
                onTap: () => _updateScore(teamId, 5),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: _isUpdating ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
