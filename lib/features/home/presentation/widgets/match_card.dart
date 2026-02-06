import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/sport_model.dart';
import '../pages/match_detail_screen.dart';

class MatchCard extends StatefulWidget {
  final MatchModel match;
  final SportModel? sport; // Optional sport model for dynamic scoring

  const MatchCard({
    super.key, 
    required this.match,
    this.sport,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
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
      final doc = await FirebaseFirestore.instance
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

  Color _getStatusColor() {
    if (widget.match.isUpcoming) return AppTheme.accentGradientStart;
    if (widget.match.isLive) return AppTheme.successColor;
    if (widget.match.isCompleted) return AppTheme.textSecondary;
    return AppTheme.errorColor;
  }

  String _getStatusText() {
    if (widget.match.isUpcoming) return 'Upcoming';
    if (widget.match.isLive) return 'Live';
    if (widget.match.isCompleted) return 'Completed';
    return 'Cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(match: widget.match),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(widget.match.dateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Match Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<TeamModel?>>(
                future: Future.wait([
                  _getTeam(widget.match.team1Id),
                  _getTeam(widget.match.team2Id),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final team1 = snapshot.data![0];
                  final team2 = snapshot.data![1];

                  if (team1 == null || team2 == null) {
                    return const Text('Teams not found');
                  }

                  return Row(
                    children: [
                      // Team 1
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  team1.name.substring(0, 1).toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryGradientStart,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              team1.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.match.hasScores)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: _buildTeamScore(context, team1.id, true),
                              ),
                          ],
                        ),
                      ),

                      // VS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'VS',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(widget.match.dateTime),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      // Team 2
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  team2.name.substring(0, 1).toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppTheme.accentGradientStart,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              team2.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.match.hasScores)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: _buildTeamScore(context, team2.id, false),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Venue
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.match.venue,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<TeamModel?> _getTeam(String teamId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();
      if (doc.exists) {
        return TeamModel.fromSnapshot(doc);
      }
    } catch (e) {
      print('Error fetching team: $e');
    }
    return null;
  }

  Widget _buildTeamScore(BuildContext context, String teamId, bool isPrimary) {
    if (_sport != null && widget.match.hasDetailedScore) {
      // Use dynamic scoring display
      final teamScore = widget.match.getTeamScore(teamId);
      if (teamScore != null) {
        // Get formatted score from sport configuration
        final formattedScore = _sport!.getFormattedScore(teamScore);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedScore.primary,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isPrimary ? AppTheme.primaryGradientStart : AppTheme.accentGradientStart,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (formattedScore.secondary.isNotEmpty)
              Text(
                formattedScore.secondary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        );
      }
    }
    
    // Legacy scoring display or fallback
    final scoreText = widget.match.score?[teamId]?.toString() ?? '-';
    return Text(
      scoreText,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: isPrimary ? AppTheme.primaryGradientStart : AppTheme.accentGradientStart,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
