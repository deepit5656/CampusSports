import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/services/standings_service.dart';

class TugOfWarMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const TugOfWarMatchControlScreen({super.key, required this.match});

  @override
  State<TugOfWarMatchControlScreen> createState() => _TugOfWarMatchControlScreenState();
}

class _TugOfWarMatchControlScreenState extends State<TugOfWarMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  
  String _team1Name = 'Team 1';
  String _team2Name = 'Team 2';
  
  int team1Pulls = 0;
  int team2Pulls = 0;
  int currentPull = 1;
  
  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  void _loadMatchData() async {
    try {
      // Load team names
      final team1Doc = await _firestore.collection('teams').doc(widget.match.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(widget.match.team2Id).get();
      if (team1Doc.exists) _team1Name = team1Doc.data()?['name'] ?? 'Team 1';
      if (team2Doc.exists) _team2Name = team2Doc.data()?['name'] ?? 'Team 2';
      if (mounted) setState(() {});
      
      final doc = await _firestore.collection('matches').doc(widget.match.id).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final tugData = data?['tugOfWarMatchData'] as Map<String, dynamic>?;
        
        if (tugData != null) {
          setState(() {
            team1Pulls = tugData['team1Pulls'] ?? 0;
            team2Pulls = tugData['team2Pulls'] ?? 0;
            currentPull = tugData['currentPull'] ?? 1;
          });
        }
      }
    } catch (e) {
      print('Error loading match data: $e');
    }
  }

  Future<void> _saveMatchData() async {
    try {
      await _firestore.collection('matches').doc(widget.match.id).update({
        'tugOfWarMatchData': {
          'team1Pulls': team1Pulls,
          'team2Pulls': team2Pulls,
          'currentPull': currentPull,
        },
        'score': {
          widget.match.team1Id: team1Pulls,
          widget.match.team2Id: team2Pulls,
        },
      });
    } catch (e) {
      print('Error saving match data: $e');
    }
  }

  void _winPull(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        team1Pulls++;
      } else {
        team2Pulls++;
      }
      
      // Best of 3 - check if match is won
      if (team1Pulls >= 2 || team2Pulls >= 2) {
        _endMatch();
      } else {
        currentPull++;
      }
    });
    _saveMatchData();
  }

  void _endMatch() async {
    final winnerId = team1Pulls > team2Pulls ? widget.match.team1Id : widget.match.team2Id;
    
    await _firestore.collection('matches').doc(widget.match.id).update({
      'status': 'completed',
      'winnerId': winnerId,
      'score': {
        widget.match.team1Id: team1Pulls,
        widget.match.team2Id: team2Pulls,
      },
    });

    // Update standings
    try {
      MatchModel updatedMatch = MatchModel(
        id: widget.match.id,
        sportId: widget.match.sportId,
        team1Id: widget.match.team1Id,
        team2Id: widget.match.team2Id,
        dateTime: widget.match.dateTime,
        venue: widget.match.venue,
        status: 'completed',
        category: widget.match.category,
        score: {
          widget.match.team1Id: team1Pulls,
          widget.match.team2Id: team2Pulls,
        },
        createdAt: widget.match.createdAt,
        winnerId: winnerId,
      );
      await _standingsService.onMatchCompleted(updatedMatch);
    } catch (e) {
      print('Error updating standings: $e');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match completed!'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Tug of War Control'),
        backgroundColor: AppTheme.primaryGradientStart,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Scoreboard
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Pull $currentPull of 3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Best of 3 Pulls',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(_team1Name, style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            team1Pulls.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Pulls Won', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const Text('VS', style: TextStyle(color: Colors.white, fontSize: 20)),
                      Column(
                        children: [
                          Text(_team2Name, style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            team2Pulls.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Pulls Won', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Win Pull Buttons
            if (team1Pulls < 2 && team2Pulls < 2) ...[
              const Text(
                'Who won this pull?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _winPull(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '$_team1Name Wins',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _winPull(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGradientStart,
                        padding: const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '$_team2Name Wins',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Rules
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tug of War Rules',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Best of 3 pulls wins the match'),
                  Text('• First team to win 2 pulls wins'),
                  Text('• Pull the rope across the center line to win'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
