import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/services/standings_service.dart';

class TableTennisMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const TableTennisMatchControlScreen({super.key, required this.match});

  @override
  State<TableTennisMatchControlScreen> createState() => _TableTennisMatchControlScreenState();
}

class _TableTennisMatchControlScreenState extends State<TableTennisMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  
  Map<String, dynamic> _matchData = {};
  bool _isLoading = true;
  String? _team1Name;
  String? _team2Name;
  
  int _currentSet = 1;
  int _totalSets = 5; // Best of 5 sets
  Map<int, Map<String, int>> _setScores = {}; // {1: {team1: 11, team2: 9}}
  List<String> _events = [];
  
  // Configurable table tennis settings
  int _pointsPerSet = 11;  // Default: 11 points per set
  int _setsToWinMatch = 3;  // Default: best of 5 (first to 3)
  DateTime? _lastSaveTime;  // For debouncing save messages

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      // Load team names
      final team1Doc = await _firestore.collection('teams').doc(widget.match.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(widget.match.team2Id).get();
      
      setState(() {
        _team1Name = team1Doc.data()?['name'] ?? 'Team 1';
        _team2Name = team2Doc.data()?['name'] ?? 'Team 2';
      });

      // Load existing match data
      final matchDoc = await _firestore.collection('matches').doc(widget.match.id).get();
      final data = matchDoc.data();
      
      if (data != null && data['tableTennisMatchData'] != null) {
        _matchData = data['tableTennisMatchData'] as Map<String, dynamic>;
        _currentSet = _matchData['currentSet'] ?? 1;
        _totalSets = _matchData['totalSets'] ?? 5;
        
        // Load configurable settings
        _pointsPerSet = _matchData['pointsPerSet'] ?? 11;
        _setsToWinMatch = _matchData['setsToWinMatch'] ?? 3;
        
        // Load set scores
        if (_matchData['setScores'] != null) {
          final setScoresData = _matchData['setScores'] as Map<String, dynamic>;
          _setScores = setScoresData.map((key, value) => 
            MapEntry(int.parse(key), Map<String, int>.from(value as Map))
          );
        }
        
        // Load events
        if (_matchData['events'] != null) {
          _events = List<String>.from(_matchData['events'] as List);
        }
      } else {
        // Initialize default data
        for (int i = 1; i <= _totalSets; i++) {
          _setScores[i] = {'team1': 0, 'team2': 0};
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading match: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _saveMatchData() async {
    try {
      // Calculate total sets won
      int team1SetsWon = 0;
      int team2SetsWon = 0;
      
      _setScores.forEach((set, scores) {
        if (scores['team1']! >= _pointsPerSet && scores['team1']! - scores['team2']! >= 2) {
          team1SetsWon++;
        } else if (scores['team2']! >= _pointsPerSet && scores['team2']! - scores['team1']! >= 2) {
          team2SetsWon++;
        }
      });

      // Determine winner
      final setsToWin = (_setsToWinMatch / 2).ceil();
      String? winnerId;
      if (team1SetsWon >= setsToWin) winnerId = widget.match.team1Id;
      if (team2SetsWon >= setsToWin) winnerId = widget.match.team2Id;

      final matchData = {
        'tableTennisMatchData': {
          'currentSet': _currentSet,
          'totalSets': _totalSets,
          'setScores': _setScores.map((key, value) => MapEntry(key.toString(), value)),
          'events': _events,
          'team1SetsWon': team1SetsWon,
          'team2SetsWon': team2SetsWon,
          'pointsPerSet': _pointsPerSet,
          'setsToWinMatch': _setsToWinMatch,
        },
        'score': {
          widget.match.team1Id: team1SetsWon,
          widget.match.team2Id: team2SetsWon,
        },
        'winnerId': winnerId,
        'status': winnerId != null ? 'completed' : widget.match.status,
      };

      await _firestore.collection('matches').doc(widget.match.id).update(matchData);

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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match updated!'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _addPoint(String team) {
    setState(() {
      if (team == 'team1') {
        _setScores[_currentSet]!['team1'] = _setScores[_currentSet]!['team1']! + 1;
      } else {
        _setScores[_currentSet]!['team2'] = _setScores[_currentSet]!['team2']! + 1;
      }
      
      final team1Score = _setScores[_currentSet]!['team1']!;
      final team2Score = _setScores[_currentSet]!['team2']!;
      
      // Check if set is won (need configurable points and 2 point lead)
      if ((team1Score >= _pointsPerSet && team1Score - team2Score >= 2) ||
          (team2Score >= _pointsPerSet && team2Score - team1Score >= 2)) {
        final winner = team1Score > team2Score ? _team1Name : _team2Name;
        _events.insert(0, '${DateFormat('HH:mm').format(DateTime.now())} - Set $_currentSet won by $winner ($team1Score-$team2Score)');
      }
    });
    _saveMatchDataWithDebounce();
  }

  void _removePoint(String team) {
    setState(() {
      if (team == 'team1' && _setScores[_currentSet]!['team1']! > 0) {
        _setScores[_currentSet]!['team1'] = _setScores[_currentSet]!['team1']! - 1;
      } else if (team == 'team2' && _setScores[_currentSet]!['team2']! > 0) {
        _setScores[_currentSet]!['team2'] = _setScores[_currentSet]!['team2']! - 1;
      }
    });
    _saveMatchDataWithDebounce();
  }

  void _saveMatchDataWithDebounce() {
    // Prevent repeated save messages within 2 seconds
    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inMilliseconds < 2000) {
      // Just save without showing message
      _saveMatchDataSilently();
      return;
    }
    
    _lastSaveTime = now;
    _saveMatchData();
  }
  
  void _saveMatchDataSilently() async {
    try {
      // Calculate total sets won
      int team1SetsWon = 0;
      int team2SetsWon = 0;
      
      _setScores.forEach((set, scores) {
        if (scores['team1']! >= _pointsPerSet && scores['team1']! - scores['team2']! >= 2) {
          team1SetsWon++;
        } else if (scores['team2']! >= _pointsPerSet && scores['team2']! - scores['team1']! >= 2) {
          team2SetsWon++;
        }
      });

      final matchData = {
        'tableTennisMatchData': {
          'currentSet': _currentSet,
          'totalSets': _totalSets,
          'setScores': _setScores.map((key, value) => MapEntry(key.toString(), value)),
          'events': _events,
          'team1SetsWon': team1SetsWon,
          'team2SetsWon': team2SetsWon,
          'pointsPerSet': _pointsPerSet,
          'setsToWinMatch': _setsToWinMatch,
        },
      };

      await _firestore.collection('matches').doc(widget.match.id).update(matchData);
    } catch (e) {
      print('Error saving match data silently: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Table Tennis Match'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Table Tennis Match Control'),
        backgroundColor: AppTheme.primaryGradientStart,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Match Header
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    Text(
                      'Set $_currentSet',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _team1Name ?? 'Team 1',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => _removePoint('team1'),
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () => _addPoint('team1'),
                                    icon: const Icon(Icons.add_circle, color: AppTheme.successColor, size: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          width: 2,
                          height: 150,
                          color: Colors.white24,
                        ),
                        
                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _team2Name ?? 'Team 2',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => _removePoint('team2'),
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () => _addPoint('team2'),
                                    icon: const Icon(Icons.add_circle, color: AppTheme.successColor, size: 32),
                                  ),
                                ],
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

            // All Sets Score Table
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

            // Events Timeline
            if (_events.isNotEmpty)
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
                        'Match Events',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._events.take(10).map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(event, style: const TextStyle(color: Colors.white70)),
                      )).toList(),
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
