import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../admin/presentation/pages/cricket_match_setup_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/quick_score_update.dart';
import '../widgets/sport_scoreboards.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  SportModel? _sport;

  @override
  void initState() {
    super.initState();
    if (widget.match.sportId.isNotEmpty) {
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
          _sport = SportModel.fromSnapshot(doc);
        });
      }
    } catch (e) {
      print('Error fetching sport: $e');
    }
  }

  Color _getStatusColor(MatchModel currentMatch) {
    if (currentMatch.isUpcoming) return AppTheme.accentGradientStart;
    if (currentMatch.isLive) return AppTheme.successColor;
    if (currentMatch.isCompleted) return AppTheme.textSecondary;
    return AppTheme.errorColor;
  }

  String _getStatusText(MatchModel currentMatch) {
    if (currentMatch.isUpcoming) return 'Upcoming';
    if (currentMatch.isLive) return 'Live';
    if (currentMatch.isCompleted) return 'Completed';
    return 'Cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.match.id)
            .snapshots(),
        builder: (context, matchSnapshot) {
          // Use updated match data if available, otherwise use original
          final currentMatch = matchSnapshot.hasData && matchSnapshot.data!.exists
              ? MatchModel.fromSnapshot(matchSnapshot.data!)
              : widget.match;

          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () {
                                Share.share('Check out this match!');
                              },
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(currentMatch),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(currentMatch),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Teams
                      FutureBuilder<List<TeamModel?>>(
                        future: Future.wait([
                          _getTeam(currentMatch.team1Id),
                          _getTeam(currentMatch.team2Id),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          }

                          final team1 = snapshot.data![0];
                          final team2 = snapshot.data![1];

                          if (team1 == null || team2 == null) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Teams not found',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Team 1
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            team1.name.substring(0, 1).toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(
                                                  color: AppTheme.primaryGradientStart,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ).animate().scale(delay: 200.ms),
                                      const SizedBox(height: 12),
                                      Text(
                                        team1.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (currentMatch.score != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          currentMatch.score![currentMatch.team1Id]?.toString() ?? '0',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // VS
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'VS',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      if (currentMatch.winnerId != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Winner',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Team 2
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            team2.name.substring(0, 1).toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(
                                                  color: AppTheme.accentGradientStart,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ).animate().scale(delay: 300.ms),
                                      const SizedBox(height: 12),
                                      Text(
                                        team2.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (currentMatch.score != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          currentMatch.score![currentMatch.team2Id]?.toString() ?? '0',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Score Update for Admins (Live Matches Only)
                if (isAdmin && currentMatch.isLive)
                  FutureBuilder<List<TeamModel?>>(
                    future: Future.wait([
                      _getTeam(currentMatch.team1Id),
                      _getTeam(currentMatch.team2Id),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data![0] != null &&
                          snapshot.data![1] != null) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('matches')
                              .doc(currentMatch.id)
                              .snapshots(),
                          builder: (context, matchSnapshot) {
                            if (!matchSnapshot.hasData) {
                              return const SizedBox();
                            }

                            final updatedMatch = MatchModel.fromSnapshot(
                              matchSnapshot.data!,
                            );

                            // Check if this is a cricket match
                            final isCricket = _sport?.name.toLowerCase() == 'cricket';
                            
                            if (isCricket && isAdmin) {
                              // For cricket matches, show a button to go to cricket scorer
                              return Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF10b981), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.sports_cricket, size: 48, color: Colors.white),
                                    SizedBox(height: 12),
                                    Text(
                                      'Cricket Match Scoring',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Use professional cricket scorer with ball-by-ball tracking',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CricketMatchSetupScreen(
                                              matchId: updatedMatch.id,
                                              team1Id: snapshot.data![0]!.id,
                                              team1Name: snapshot.data![0]!.name,
                                              team2Id: snapshot.data![1]!.id,
                                              team2Name: snapshot.data![1]!.name,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.play_arrow),
                                      label: Text('Open Cricket Scorer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Color(0xFF10b981),
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
                            }

                            return QuickScoreUpdate(
                              match: updatedMatch,
                              team1: snapshot.data![0]!,
                              team2: snapshot.data![1]!,
                              sport: _sport,
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                // Sport-Specific Scoreboard
                if (_sport != null &&
                    matchSnapshot.hasData &&
                    matchSnapshot.data!.exists)
                  FutureBuilder<List<TeamModel?>>(
                    future: Future.wait([
                      _getTeam(currentMatch.team1Id),
                      _getTeam(currentMatch.team2Id),
                    ]),
                    builder: (context, teamSnap) {
                      if (!teamSnap.hasData ||
                          teamSnap.data![0] == null ||
                          teamSnap.data![1] == null) {
                        return const SizedBox.shrink();
                      }
                      final rawData = matchSnapshot.data!.data()
                          as Map<String, dynamic>? ??
                          {};
                      return SportScoreboard(
                        sportName: _sport!.name,
                        matchData: rawData,
                        matchId: currentMatch.id,
                        team1Id: currentMatch.team1Id,
                        team2Id: currentMatch.team2Id,
                        team1Name: teamSnap.data![0]!.name,
                        team2Name: teamSnap.data![1]!.name,
                      );
                    },
                  ),

                // Match Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 16),

                      _buildDetailCard(
                        context,
                        Icons.calendar_today,
                        'Date',
                        DateFormat('EEEE, MMMM dd, yyyy').format(currentMatch.dateTime),
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      _buildDetailCard(
                        context,
                        Icons.access_time,
                        'Time',
                        DateFormat('hh:mm a').format(currentMatch.dateTime),
                      ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 12),

                      _buildDetailCard(
                        context,
                        Icons.location_on,
                        'Venue',
                        currentMatch.venue,
                      ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ); // Container
      }, // StreamBuilder builder
      ), // StreamBuilder
    ); // Scaffold
  }

  Widget _buildDetailCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
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
}
