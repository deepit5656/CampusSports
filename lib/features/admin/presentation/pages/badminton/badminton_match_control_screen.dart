import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/models/team_model.dart';
import '../../../../../core/models/sport_model.dart';

class BadmintonMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const BadmintonMatchControlScreen({super.key, required this.match});

  @override
  State<BadmintonMatchControlScreen> createState() => _BadmintonMatchControlScreenState();
}

class _BadmintonMatchControlScreenState extends State<BadmintonMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TeamModel? _team1;
  TeamModel? _team2;
  SportModel? _sport;
  
  // Match state
  int _currentSet = 1;
  Map<int, Map<String, int>> _setScores = {
    1: {'team1': 0, 'team2': 0},
    2: {'team1': 0, 'team2': 0},
    3: {'team1': 0, 'team2': 0},
  };
  int _setsWonTeam1 = 0;
  int _setsWonTeam2 = 0;
  String? _servingTeam;
  List<Map<String, dynamic>> _pointHistory = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      // Load teams
      final team1Doc = await _firestore.collection('teams').doc(widget.match.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(widget.match.team2Id).get();
      
      // Load sport
      final sportDoc = await _firestore.collection('sports').doc(widget.match.sportId).get();
      
      if (team1Doc.exists && team2Doc.exists && sportDoc.exists) {
        setState(() {
          _team1 = TeamModel.fromSnapshot(team1Doc);
          _team2 = TeamModel.fromSnapshot(team2Doc);
          _sport = SportModel.fromSnapshot(sportDoc);
        });
        
        // Load existing match data if available
        final matchDoc = await _firestore.collection('matches').doc(widget.match.id).get();
        if (matchDoc.exists) {
          final data = matchDoc.data();
          final badmintonData = data?['badmintonMatchData'] as Map<String, dynamic>?;
          
          if (badmintonData != null) {
            setState(() {
              _currentSet = badmintonData['currentSet'] ?? 1;
              _servingTeam = badmintonData['servingTeam'];
              _setsWonTeam1 = badmintonData['setsWonTeam1'] ?? 0;
              _setsWonTeam2 = badmintonData['setsWonTeam2'] ?? 0;
              
              // Load set scores
              if (badmintonData['setScores'] != null) {
                final scores = badmintonData['setScores'] as Map<String, dynamic>;
                scores.forEach((key, value) {
                  _setScores[int.parse(key)] = Map<String, int>.from(value);
                });
              }
              
              // Load point history
              if (badmintonData['pointHistory'] != null) {
                _pointHistory = List<Map<String, dynamic>>.from(badmintonData['pointHistory']);
              }
            });
          }
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading match: $e')),
        );
      }
    }
  }

  Future<void> _saveMatchData() async {
    try {
      final badmintonData = {
        'currentSet': _currentSet,
        'setScores': _setScores.map((k, v) => MapEntry(k.toString(), v)),
        'setsWonTeam1': _setsWonTeam1,
        'setsWonTeam2': _setsWonTeam2,
        'servingTeam': _servingTeam,
        'pointHistory': _pointHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Calculate winner if match is complete
      String? winnerId;
      if (_setsWonTeam1 >= 2) {
        winnerId = widget.match.team1Id;
      } else if (_setsWonTeam2 >= 2) {
        winnerId = widget.match.team2Id;
      }

      await _firestore.collection('matches').doc(widget.match.id).update({
        'badmintonMatchData': badmintonData,
        'winnerId': winnerId,
        'status': winnerId != null ? 'completed' : widget.match.status,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match data saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _addPoint(String teamId) {
    setState(() {
      final team = teamId == widget.match.team1Id ? 'team1' : 'team2';
      _setScores[_currentSet]![team] = (_setScores[_currentSet]![team] ?? 0) + 1;
      
      // Add to history
      _pointHistory.add({
        'set': _currentSet,
        'team': team,
        'score': _setScores[_currentSet],
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update serving team
      _servingTeam = teamId;
      
      // Check if set is won (21 points with 2 point lead, or 30 points)
      final team1Score = _setScores[_currentSet]!['team1']!;
      final team2Score = _setScores[_currentSet]!['team2']!;
      
      if ((team1Score >= 21 && team1Score - team2Score >= 2) || team1Score == 30) {
        _setsWonTeam1++;
        _checkSetComplete();
      } else if ((team2Score >= 21 && team2Score - team1Score >= 2) || team2Score == 30) {
        _setsWonTeam2++;
        _checkSetComplete();
      }
    });
    
    _saveMatchData();
  }

  void _checkSetComplete() {
    if (_setsWonTeam1 >= 2 || _setsWonTeam2 >= 2) {
      // Match complete
      _showMatchCompleteDialog();
    } else if (_currentSet < 3) {
      // Move to next set
      _showSetCompleteDialog();
    }
  }

  void _showSetCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: Text('Set $_currentSet Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_team1?.name}: ${_setScores[_currentSet]!['team1']}'),
            Text('${_team2?.name}: ${_setScores[_currentSet]!['team2']}'),
            const SizedBox(height: 16),
            Text('Sets Won:'),
            Text('${_team1?.name}: $_setsWonTeam1'),
            Text('${_team2?.name}: $_setsWonTeam2'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentSet++;
              });
              Navigator.pop(context);
            },
            child: const Text('Next Set'),
          ),
        ],
      ),
    );
  }

  void _showMatchCompleteDialog() {
    final winner = _setsWonTeam1 > _setsWonTeam2 ? _team1 : _team2;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: const Text('Match Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: AppTheme.successColor),
            const SizedBox(height: 16),
            Text(
              '${winner?.name} Wins!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Final Score: $_setsWonTeam1 - $_setsWonTeam2'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _undoLastPoint() {
    if (_pointHistory.isEmpty) return;
    
    setState(() {
      final lastPoint = _pointHistory.removeLast();
      final set = lastPoint['set'] as int;
      final team = lastPoint['team'] as String;
      
      _setScores[set]![team] = (_setScores[set]![team] ?? 0) - 1;
      
      // Recalculate sets won
      _recalculateSetsWon();
    });
    
    _saveMatchData();
  }

  void _recalculateSetsWon() {
    _setsWonTeam1 = 0;
    _setsWonTeam2 = 0;
    
    for (int i = 1; i <= _currentSet; i++) {
      final team1Score = _setScores[i]!['team1']!;
      final team2Score = _setScores[i]!['team2']!;
      
      if ((team1Score >= 21 && team1Score - team2Score >= 2) || team1Score == 30) {
        _setsWonTeam1++;
      } else if ((team2Score >= 21 && team2Score - team1Score >= 2) || team2Score == 30) {
        _setsWonTeam2++;
      }
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

    if (_team1 == null || _team2 == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text('Error loading match data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Badminton Match'),
        backgroundColor: AppTheme.primaryGradientStart,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _pointHistory.isNotEmpty ? _undoLastPoint : null,
            tooltip: 'Undo Last Point',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Match Info
            _buildMatchInfo(),
            const SizedBox(height: 24),
            
            // Current Set Display
            _buildCurrentSetDisplay(),
            const SizedBox(height: 24),
            
            // Scoreboard
            _buildScoreboard(),
            const SizedBox(height: 24),
            
            // Sets Won
            _buildSetsWon(),
            const SizedBox(height: 24),
            
            // Set History
            _buildSetHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _sport?.name ?? 'Badminton',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy - HH:mm').format(widget.match.dateTime),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSetDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Set $_currentSet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_servingTeam != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_tennis, color: AppTheme.successColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Serving: ${_servingTeam == widget.match.team1Id ? _team1?.name : _team2?.name}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    final team1Score = _setScores[_currentSet]!['team1']!;
    final team2Score = _setScores[_currentSet]!['team2']!;
    
    return Row(
      children: [
        Expanded(
          child: _buildTeamScoreCard(
            _team1!,
            team1Score,
            widget.match.team1Id,
            isTeam1: true,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.successGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTeamScoreCard(
            _team2!,
            team2Score,
            widget.match.team2Id,
            isTeam1: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScoreCard(TeamModel team, int score, String teamId, {required bool isTeam1}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _servingTeam == teamId 
            ? AppTheme.successColor 
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _addPoint(teamId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('+ Point'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsWon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Sets Won',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    _team1?.name ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _setsWonTeam1.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text(
                '-',
                style: TextStyle(color: Colors.white70, fontSize: 32),
              ),
              Column(
                children: [
                  Text(
                    _team2?.name ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _setsWonTeam2.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Scores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            final setNum = index + 1;
            final scores = _setScores[setNum]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Set $setNum:',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  Text(
                    '${scores['team1']} - ${scores['team2']}',
                    style: TextStyle(
                      color: setNum <= _currentSet ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
