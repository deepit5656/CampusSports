import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/services/standings_service.dart';

class VolleyballMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const VolleyballMatchControlScreen({super.key, required this.match});

  @override
  State<VolleyballMatchControlScreen> createState() => _VolleyballMatchControlScreenState();
}

class _VolleyballMatchControlScreenState extends State<VolleyballMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  
  bool _isLoading = true;
  String? _team1Name;
  String? _team2Name;
  
  int _currentSet = 1;
  int _totalSets = 5; // Best of 5 sets
  Map<int, Map<String, int>> _setScores = {};
  List<String> _events = [];
  
  // Volleyball specific
  String _servingTeam = 'team1';
  Map<String, int> _timeouts = {'team1': 2, 'team2': 2}; // 2 timeouts per set
  
  // Configurable volleyball settings
  int _pointsPerSet = 25;  // Default: 25 points per set
  int _pointsForFinalSet = 15;  // Default: 15 points for final/5th set
  int _setsToWinMatch = 3;  // Default: best of 5 (first to 3)
  DateTime? _lastSaveTime;  // For debouncing save messages

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final team1Doc = await _firestore.collection('teams').doc(widget.match.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(widget.match.team2Id).get();
      
      setState(() {
        _team1Name = team1Doc.data()?['name'] ?? 'Team 1';
        _team2Name = team2Doc.data()?['name'] ?? 'Team 2';
      });

      final matchDoc = await _firestore.collection('matches').doc(widget.match.id).get();
      final data = matchDoc.data();
      
      if (data != null && data['volleyballMatchData'] != null) {
        final matchData = data['volleyballMatchData'] as Map<String, dynamic>;
        _currentSet = matchData['currentSet'] ?? 1;
        _servingTeam = matchData['servingTeam'] ?? 'team1';
        
        // Load configurable settings
        _pointsPerSet = matchData['pointsPerSet'] ?? 25;
        _pointsForFinalSet = matchData['pointsForFinalSet'] ?? 15;
        _setsToWinMatch = matchData['setsToWinMatch'] ?? 3;
        _totalSets = matchData['totalSets'] ?? 5;
        
        if (matchData['setScores'] != null) {
          final setScoresData = matchData['setScores'] as Map<String, dynamic>;
          _setScores = setScoresData.map((key, value) => 
            MapEntry(int.parse(key), Map<String, int>.from(value as Map))
          );
        }
        
        if (matchData['events'] != null) {
          _events = List<String>.from(matchData['events'] as List);
        }
        
        if (matchData['timeouts'] != null) {
          _timeouts = Map<String, int>.from(matchData['timeouts'] as Map);
        }
      } else {
        for (int i = 1; i <= _totalSets; i++) {
          _setScores[i] = {'team1': 0, 'team2': 0};
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMatchData() async {
    try {
      int team1SetsWon = 0;
      int team2SetsWon = 0;
      
      _setScores.forEach((set, scores) {
        // Volleyball: use configurable points (25 for standard, 15 for final)
        final pointsNeeded = set == _totalSets ? _pointsForFinalSet : _pointsPerSet;
        if (scores['team1']! >= pointsNeeded && scores['team1']! - scores['team2']! >= 2) {
          team1SetsWon++;
        } else if (scores['team2']! >= pointsNeeded && scores['team2']! - scores['team1']! >= 2) {
          team2SetsWon++;
        }
      });

      String? winnerId;
      if (team1SetsWon >= _setsToWinMatch) winnerId = widget.match.team1Id;
      if (team2SetsWon >= _setsToWinMatch) winnerId = widget.match.team2Id;

      await _firestore.collection('matches').doc(widget.match.id).update({
        'volleyballMatchData': {
          'currentSet': _currentSet,
          'totalSets': _totalSets,
          'setScores': _setScores.map((key, value) => MapEntry(key.toString(), value)),
          'events': _events,
          'servingTeam': _servingTeam,
          'timeouts': _timeouts,
          'team1SetsWon': team1SetsWon,
          'team2SetsWon': team2SetsWon,
          'pointsPerSet': _pointsPerSet,
          'pointsForFinalSet': _pointsForFinalSet,
          'setsToWinMatch': _setsToWinMatch,
        },
        'score': {
          widget.match.team1Id: team1SetsWon,
          widget.match.team2Id: team2SetsWon,
        },
        'winnerId': winnerId,
        'status': winnerId != null ? 'completed' : widget.match.status,
      });

      // Update standings if match is completed
      if (winnerId != null) {
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
              widget.match.team1Id: team1SetsWon,
              widget.match.team2Id: team2SetsWon,
            },
            createdAt: widget.match.createdAt,
            winnerId: winnerId,
          );
          await _standingsService.onMatchCompleted(updatedMatch);
        } catch (e) {
          print('Error updating standings: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match data saved'), duration: Duration(milliseconds: 800)),
      );
    } catch (e) {
      print('Error saving: $e');
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
      int team1SetsWon = 0;
      int team2SetsWon = 0;
      
      _setScores.forEach((set, scores) {
        final pointsNeeded = set == _totalSets ? _pointsForFinalSet : _pointsPerSet;
        if (scores['team1']! >= pointsNeeded && scores['team1']! - scores['team2']! >= 2) {
          team1SetsWon++;
        } else if (scores['team2']! >= pointsNeeded && scores['team2']! - scores['team1']! >= 2) {
          team2SetsWon++;
        }
      });

      await _firestore.collection('matches').doc(widget.match.id).update({
        'volleyballMatchData': {
          'currentSet': _currentSet,
          'totalSets': _totalSets,
          'setScores': _setScores.map((key, value) => MapEntry(key.toString(), value)),
          'events': _events,
          'servingTeam': _servingTeam,
          'timeouts': _timeouts,
          'team1SetsWon': team1SetsWon,
          'team2SetsWon': team2SetsWon,
          'pointsPerSet': _pointsPerSet,
          'pointsForFinalSet': _pointsForFinalSet,
          'setsToWinMatch': _setsToWinMatch,
        },
      });
    } catch (e) {
      print('Error saving: $e');
    }
  }

  void _addPoint(String team) {
    setState(() {
      _setScores[_currentSet]![team] = _setScores[_currentSet]![team]! + 1;
      
      // Switch serve if the scoring team is not serving
      if (team != _servingTeam) {
        _servingTeam = team;
        final teamName = team == 'team1' ? _team1Name : _team2Name;
        _events.insert(0, '${DateFormat('HH:mm').format(DateTime.now())} - Serve change to $teamName');
      }
      
      final team1Score = _setScores[_currentSet]!['team1']!;
      final team2Score = _setScores[_currentSet]!['team2']!;
      final pointsNeeded = _currentSet == _totalSets ? _pointsForFinalSet : _pointsPerSet;
      
      if ((team1Score >= pointsNeeded && team1Score - team2Score >= 2) ||
          (team2Score >= pointsNeeded && team2Score - team1Score >= 2)) {
        final winner = team1Score > team2Score ? _team1Name : _team2Name;
        _events.insert(0, '${DateFormat('HH:mm').format(DateTime.now())} - Set $_currentSet won by $winner ($team1Score-$team2Score)');
        
        // Reset timeouts for next set
        _timeouts = {'team1': 2, 'team2': 2};
      }
    });
    _saveMatchDataWithDebounce();
  }

  void _callTimeout(String team) {
    if (_timeouts[team]! > 0) {
      setState(() {
        _timeouts[team] = _timeouts[team]! - 1;
        final teamName = team == 'team1' ? _team1Name : _team2Name;
        _events.insert(0, '${DateFormat('HH:mm').format(DateTime.now())} - Timeout called by $teamName');
      });
      _saveMatchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Volleyball Match Control'),
        backgroundColor: AppTheme.primaryGradientStart,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$_team1Name vs $_team2Name',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Best of $_totalSets Sets',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Set Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_totalSets, (index) {
                    final setNum = index + 1;
                    final isActive = setNum == _currentSet;
                    return GestureDetector(
                      onTap: () => setState(() => _currentSet = setNum),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryGradientStart : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Set $setNum',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Current Set Score
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Set ', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text('$_currentSet', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text(' - Points to ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('${_currentSet == 5 ? '15' : '25'}', style: const TextStyle(color: AppTheme.successColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _team1Name ?? 'Team 1',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  if (_servingTeam == 'team1') ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.sports_volleyball, color: AppTheme.successColor, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_setScores[_currentSet]!['team1']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _addPoint('team1'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                child: const Text('+ Point', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _timeouts['team1']! > 0 ? () => _callTimeout('team1') : null,
                                child: Text('Timeout (${_timeouts['team1']})'),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(width: 2, height: 200, color: Colors.white24),
                        
                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _team2Name ?? 'Team 2',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  if (_servingTeam == 'team2') ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.sports_volleyball, color: AppTheme.successColor, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_setScores[_currentSet]!['team2']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _addPoint('team2'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                child: const Text('+ Point', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _timeouts['team2']! > 0 ? () => _callTimeout('team2') : null,
                                child: Text('Timeout (${_timeouts['team2']})'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sets Score Table
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sets Score',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Table(
                      border: TableBorder.all(color: Colors.white24),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_team1Name ?? 'Team 1', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_team2Name ?? 'Team 2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        ..._setScores.entries.map((entry) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('${entry.key}', style: const TextStyle(color: Colors.white70)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('${entry.value['team1']}', style: const TextStyle(color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('${entry.value['team2']}', style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
