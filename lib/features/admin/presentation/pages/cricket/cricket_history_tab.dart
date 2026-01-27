import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/models/team_model.dart';
import '../../../../../core/services/cricket_scoring_service.dart';
import '../../../../../core/models/cricket/cricket_inning.dart';
import '../../../../../core/models/cricket/cricket_batting_stats.dart';
import '../../../../../core/models/cricket/cricket_bowling_stats.dart';

class CricketHistoryTab extends StatefulWidget {
  final String sportId;

  const CricketHistoryTab({Key? key, required this.sportId}) : super(key: key);

  @override
  State<CricketHistoryTab> createState() => _CricketHistoryTabState();
}

class _CricketHistoryTabState extends State<CricketHistoryTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _cricketService = CricketScoringService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('matches')
          .where('sportId', isEqualTo: widget.sportId)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data!.docs
            .map((doc) => MatchModel.fromSnapshot(doc))
            .where((match) => match.status == 'completed')
            .toList();

        if (matches.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return _buildMatchCard(matches[index], index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Match History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed matches will appear here',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, int index) {
    return FutureBuilder<List<TeamModel?>>(
      future: Future.wait([
        _getTeam(match.team1Id),
        _getTeam(match.team2Id),
      ]),
      builder: (context, teamsSnapshot) {
        if (!teamsSnapshot.hasData) {
          return const SizedBox();
        }

        final team1 = teamsSnapshot.data![0];
        final team2 = teamsSnapshot.data![1];

        if (team1 == null || team2 == null) {
          return const SizedBox();
        }

        return GestureDetector(
          onTap: () => _showMatchScorecard(match, team1, team2),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Match Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(match.dateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            match.venue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Teams and Scores
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTeamScore(
                        team1.name,
                        match.getFormattedScore(match.team1Id, 'runs', 'wickets'),
                        match.winnerId == match.team1Id,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.white.withOpacity(0.2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'vs',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.white.withOpacity(0.2)),
                            ),
                          ],
                        ),
                      ),
                      _buildTeamScore(
                        team2.name,
                        match.getFormattedScore(match.team2Id, 'runs', 'wickets'),
                        match.winnerId == match.team2Id,
                      ),
                    ],
                  ),
                ),

                // Result
                if (match.winnerId != null) ...[
                  const Divider(color: Colors.white24, height: 1),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${match.winnerId == match.team1Id ? team1.name : team2.name} won',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // View Scorecard Button
                const Divider(color: Colors.white24, height: 1),
                InkWell(
                  onTap: () => _showMatchScorecard(match, team1, team2),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Full Scorecard',
                          style: TextStyle(
                            color: Color(0xFF10b981),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF10b981),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2, end: 0),
        );
      },
    );
  }

  Widget _buildTeamScore(String teamName, String score, bool isWinner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (isWinner)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10b981),
                  size: 20,
                ),
              if (isWinner) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  teamName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          score,
          style: TextStyle(
            color: isWinner ? const Color(0xFF10b981) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<TeamModel?> _getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromSnapshot(doc);
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  void _showMatchScorecard(MatchModel match, TeamModel team1, TeamModel team2) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Match Scorecard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(match.dateTime),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      match.venue,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 1),

              // Scorecard content
              Expanded(
                child: FutureBuilder<List<CricketInning>>(
                  future: _cricketService.getMatchInnings(match.id),
                  builder: (context, inningsSnapshot) {
                    if (!inningsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final innings = inningsSnapshot.data!;

                    if (innings.isEmpty) {
                      return const Center(
                        child: Text(
                          'No innings data available',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: innings.length,
                      itemBuilder: (context, index) {
                        final inning = innings[index];
                        final battingTeam = inning.battingTeamId == team1.id ? team1 : team2;
                        return _buildInningCard(inning, battingTeam);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInningCard(CricketInning inning, TeamModel team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inning header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${team.name} - Inning ${inning.inningNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${inning.totalRuns}/${inning.wickets}',
                style: const TextStyle(
                  color: Color(0xFF10b981),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Overs: ${inning.overs.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              if (inning.overs > 0)
                Text(
                  'Run Rate: ${(inning.totalRuns / inning.overs).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // Extras
          Row(
            children: [
              const Text(
                'Extras: ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${inning.extras} (wd ${inning.wides}, nb ${inning.noBalls}, b ${inning.byes}, lb ${inning.legByes})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Batting and Bowling stats would go here
          FutureBuilder(
            future: Future.wait([
              _cricketService.getInningBattingStats(inning.id),
              _cricketService.getInningBowlingStats(inning.id),
            ]),
            builder: (context, statsSnapshot) {
              if (!statsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final battingStats = statsSnapshot.data![0];
              final bowlingStats = statsSnapshot.data![1];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (battingStats.isNotEmpty) ...[
                    const Text(
                      'Batting',
                      style: TextStyle(
                        color: Color(0xFF10b981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...battingStats.take(3).map((stats) {
                      final battingStat = stats as CricketBattingStats;
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  battingStat.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${battingStat.runs}(${battingStat.ballsFaced})',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                    }),
                  ],
                  if (bowlingStats.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Bowling',
                      style: TextStyle(
                        color: Color(0xFF10b981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...bowlingStats.take(3).map((stats) {
                      final bowlingStat = stats as CricketBowlingStats;
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bowlingStat.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${bowlingStat.wickets}/${bowlingStat.runs} (${bowlingStat.overs.toStringAsFixed(1)})',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                    }),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
