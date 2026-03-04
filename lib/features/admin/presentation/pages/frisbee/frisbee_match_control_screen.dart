import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/services/standings_service.dart';

class FrisbeeMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const FrisbeeMatchControlScreen({super.key, required this.match});

  @override
  State<FrisbeeMatchControlScreen> createState() => _FrisbeeMatchControlScreenState();
}

class _FrisbeeMatchControlScreenState extends State<FrisbeeMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  
  String _team1Name = 'Team 1';
  String _team2Name = 'Team 2';
  
  int team1Score = 0;
  int team2Score = 0;
  String? possession; // 'team1' or 'team2'
  int turnovers = 0;
  
  // Configurable frisbee settings
  int _pointsToWinMatch = 15;  // Default: first to 15 points
  DateTime? _lastSaveTime;  // For debouncing save messages
  
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
        final frisbeeData = data?['frisbeeMatchData'] as Map<String, dynamic>?;
        
        if (frisbeeData != null) {
          setState(() {
            team1Score = frisbeeData['team1Score'] ?? 0;
            team2Score = frisbeeData['team2Score'] ?? 0;
            possession = frisbeeData['possession'];
            turnovers = frisbeeData['turnovers'] ?? 0;
            _pointsToWinMatch = frisbeeData['pointsToWinMatch'] ?? 15;
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
        'frisbeeMatchData': {
          'team1Score': team1Score,
          'team2Score': team2Score,
          'possession': possession,
          'turnovers': turnovers,
          'pointsToWinMatch': _pointsToWinMatch,
        },
        'score': {
          widget.match.team1Id: team1Score,
          widget.match.team2Id: team2Score,
        },
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match data saved'), duration: Duration(milliseconds: 800)),
      );
    } catch (e) {
      print('Error saving match data: $e');
    }
  }

  void _saveMatchDataWithDebounce() {
    final now = DateTime.now();
    if (_lastSaveTime != null && 
        now.difference(_lastSaveTime!).inMilliseconds < 2000) {
      _saveMatchDataSilently();
      return;
    }
    _lastSaveTime = now;
    _saveMatchData();
  }

  Future<void> _saveMatchDataSilently() async {
    try {
      await _firestore.collection('matches').doc(widget.match.id).update({
        'frisbeeMatchData': {
          'team1Score': team1Score,
          'team2Score': team2Score,
          'possession': possession,
          'turnovers': turnovers,
          'pointsToWinMatch': _pointsToWinMatch,
        },
      });
    } catch (e) {
      print('Error saving match data: $e');
    }
  }

  void _addPoint(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        team1Score++;
        possession = 'team2'; // Change possession after scoring
      } else {
        team2Score++;
        possession = 'team1';
      }
      
      // Check if match is won (first to configurable points)
      if (team1Score >= _pointsToWinMatch || team2Score >= _pointsToWinMatch) {
        _endMatch();
      }
    });
    _saveMatchDataWithDebounce();
  }

  void _turnover() {
    setState(() {
      turnovers++;
      // Switch possession
      possession = possession == 'team1' ? 'team2' : 'team1';
    });
    _saveMatchDataWithDebounce();
  }

  void _endMatch() async {
    final winnerId = team1Score > team2Score ? widget.match.team1Id : widget.match.team2Id;
    
    await _firestore.collection('matches').doc(widget.match.id).update({
      'status': 'completed',
      'winnerId': winnerId,
      'score': {
        widget.match.team1Id: team1Score,
        widget.match.team2Id: team2Score,
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
          widget.match.team1Id: team1Score,
          widget.match.team2Id: team2Score,
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
        title: const Text('Ultimate Frisbee Control'),
        backgroundColor: AppTheme.primaryGradientStart,
        actions: [
          if (team1Score >= 15 || team2Score >= 15)
            TextButton.icon(
              onPressed: _endMatch,
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text('End Match', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                  const Text(
                    'First to 15 Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                            team1Score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (possession == 'team1') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'POSSESSION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Text('VS', style: TextStyle(color: Colors.white, fontSize: 20)),
                      Column(
                        children: [
                          Text(_team2Name, style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            team2Score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (possession == 'team2') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGradientStart,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'POSSESSION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Turnovers: $turnovers',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Score Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addPoint(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '$_team1Name\nScores!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addPoint(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGradientStart,
                      padding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '$_team2Name\nScores!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Turnover Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _turnover,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Turnover'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
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
                    'Ultimate Frisbee Rules',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• First team to 15 points wins'),
                  Text('• Score by catching in end zone'),
                  Text('• Possession changes after scoring'),
                  Text('• Turnover switches possession'),
                  Text('• No physical contact allowed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
