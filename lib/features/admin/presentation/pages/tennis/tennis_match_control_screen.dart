import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/services/standings_service.dart';

class TennisMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const TennisMatchControlScreen({super.key, required this.match});

  @override
  State<TennisMatchControlScreen> createState() => _TennisMatchControlScreenState();
}

class _TennisMatchControlScreenState extends State<TennisMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  
  String _team1Name = 'Team 1';
  String _team2Name = 'Team 2';
  
  // Match state
  int team1Sets = 0;
  int team2Sets = 0;
  int currentSet = 1;
  List<Map<String, int>> setScores = [];
  int team1Games = 0;
  int team2Games = 0;
  bool isTiebreak = false;
  int team1TiebreakPoints = 0;
  int team2TiebreakPoints = 0;
  String? server; // 'team1' or 'team2'
  
  // Configurable tennis settings
  int _gamesPerSet = 6;  // Default: first to 6 games per set
  int _tiebreakPoints = 7;  // Default: first to 7 in tiebreak
  int _setsToWinMatch = 2;  // Default: best of 3 (first to 2)
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
      
      final doc = await _firestore.collection('matches').doc(widget.match.id).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final tennisData = data?['tennisMatchData'] as Map<String, dynamic>?;
        
        if (tennisData != null) {
          setState(() {
            team1Sets = tennisData['team1Sets'] ?? 0;
            team2Sets = tennisData['team2Sets'] ?? 0;
            currentSet = tennisData['currentSet'] ?? 1;
            team1Games = tennisData['team1Games'] ?? 0;
            team2Games = tennisData['team2Games'] ?? 0;
            isTiebreak = tennisData['isTiebreak'] ?? false;
            team1TiebreakPoints = tennisData['team1TiebreakPoints'] ?? 0;
            team2TiebreakPoints = tennisData['team2TiebreakPoints'] ?? 0;
            server = tennisData['server'];
            
            // Load configurable settings
            _gamesPerSet = tennisData['gamesPerSet'] ?? 6;
            _tiebreakPoints = tennisData['tiebreakPoints'] ?? 7;
            _setsToWinMatch = tennisData['setsToWinMatch'] ?? 2;
            
            final sets = tennisData['setScores'] as List?;
            if (sets != null) {
              setScores = sets.map((s) => Map<String, int>.from(s)).toList();
            }
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
        'tennisMatchData': {
          'team1Sets': team1Sets,
          'team2Sets': team2Sets,
          'currentSet': currentSet,
          'team1Games': team1Games,
          'team2Games': team2Games,
          'isTiebreak': isTiebreak,
          'team1TiebreakPoints': team1TiebreakPoints,
          'team2TiebreakPoints': team2TiebreakPoints,
          'setScores': setScores,
          'server': server,
          'gamesPerSet': _gamesPerSet,
          'tiebreakPoints': _tiebreakPoints,
          'setsToWinMatch': _setsToWinMatch,
        },
        'score': {
          widget.match.team1Id: team1Sets,
          widget.match.team2Id: team2Sets,
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
        'tennisMatchData': {
          'team1Sets': team1Sets,
          'team2Sets': team2Sets,
          'currentSet': currentSet,
          'team1Games': team1Games,
          'team2Games': team2Games,
          'isTiebreak': isTiebreak,
          'team1TiebreakPoints': team1TiebreakPoints,
          'team2TiebreakPoints': team2TiebreakPoints,
          'setScores': setScores,
          'server': server,
          'gamesPerSet': _gamesPerSet,
          'tiebreakPoints': _tiebreakPoints,
          'setsToWinMatch': _setsToWinMatch,
        },
      });
    } catch (e) {
      print('Error saving match data: $e');
    }
  }

  void _addGame(bool isTeam1) {
    setState(() {
      if (isTiebreak) {
        if (isTeam1) {
          team1TiebreakPoints++;
        } else {
          team2TiebreakPoints++;
        }
        
        // Check tiebreak win (configurable points, lead by 2)
        if ((team1TiebreakPoints >= _tiebreakPoints && team1TiebreakPoints - team2TiebreakPoints >= 2) ||
            (team2TiebreakPoints >= _tiebreakPoints && team2TiebreakPoints - team1TiebreakPoints >= 2)) {
          _endSet();
        }
      } else {
        if (isTeam1) {
          team1Games++;
        } else {
          team2Games++;
        }
        
        // Check for set win (configurable games per set, lead by 2) or tiebreak
        if (team1Games >= _gamesPerSet || team2Games >= _gamesPerSet) {
          if (team1Games == _gamesPerSet && team2Games == _gamesPerSet) {
            isTiebreak = true;
          } else if ((team1Games >= _gamesPerSet && team1Games - team2Games >= 2) ||
                     (team2Games >= _gamesPerSet && team2Games - team1Games >= 2)) {
            _endSet();
          }
        }
      }
    });
    _saveMatchDataWithDebounce();
  }

  void _endSet() {
    setScores.add({
      'team1': isTiebreak ? team1TiebreakPoints : team1Games,
      'team2': isTiebreak ? team2TiebreakPoints : team2Games,
    });
    
    if (isTiebreak) {
      if (team1TiebreakPoints > team2TiebreakPoints) {
        team1Sets++;
      } else {
        team2Sets++;
      }
    } else {
      if (team1Games > team2Games) {
        team1Sets++;
      } else {
        team2Sets++;
      }
    }
    
    // Reset for next set
    team1Games = 0;
    team2Games = 0;
    isTiebreak = false;
    team1TiebreakPoints = 0;
    team2TiebreakPoints = 0;
    currentSet++;
    
    // Check for match win (configurable sets to win)
    final setsNeededToWin = (_setsToWinMatch / 2).ceil();
    if (team1Sets >= setsNeededToWin || team2Sets >= setsNeededToWin) {
      _endMatch();
    }
  }

  void _endMatch() async {
    final winnerId = team1Sets > team2Sets ? widget.match.team1Id : widget.match.team2Id;
    
    await _firestore.collection('matches').doc(widget.match.id).update({
      'status': 'completed',
      'winnerId': winnerId,
      'score': {
        widget.match.team1Id: team1Sets,
        widget.match.team2Id: team2Sets,
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
          widget.match.team1Id: team1Sets,
          widget.match.team2Id: team2Sets,
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
        title: const Text('Tennis Match Control'),
        backgroundColor: AppTheme.primaryGradientStart,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.getCardColor(context),
                  title: const Text('Tennis Rules'),
                  content: const Text(
                    '• First to 6 games wins a set (lead by 2)\n'
                    '• 6-6 goes to tiebreak (first to 7, lead by 2)\n'
                    '• Best of 3 sets wins the match\n'
                    '• Players alternate serves each game',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current Score
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Set $currentSet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Team 1
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _team1Name,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              team1Sets.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sets',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTiebreak ? team1TiebreakPoints.toString() : team1Games.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isTiebreak ? 'Points' : 'Games',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      
                      // VS
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Team 2
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _team2Name,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              team2Sets.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sets',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTiebreak ? team2TiebreakPoints.toString() : team2Games.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isTiebreak ? 'Points' : 'Games',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isTiebreak) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGradientStart.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TIEBREAK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Game Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addGame(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isTiebreak ? '$_team1Name\n+Point' : '$_team1Name\n+Game',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addGame(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGradientStart,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isTiebreak ? '$_team2Name\n+Point' : '$_team2Name\n+Game',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Set Scores
            if (setScores.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Scores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...setScores.asMap().entries.map((entry) {
                      final setNum = entry.key + 1;
                      final scores = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('Set $setNum:', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Text('${scores['team1']}', style: const TextStyle(fontSize: 16)),
                            const Text(' - ', style: TextStyle(fontSize: 16)),
                            Text('${scores['team2']}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
