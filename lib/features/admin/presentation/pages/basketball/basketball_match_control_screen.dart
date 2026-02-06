import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/models/team_model.dart';

class BasketballMatchControlScreen extends StatefulWidget {
  final String matchId;

  const BasketballMatchControlScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<BasketballMatchControlScreen> createState() => _BasketballMatchControlScreenState();
}

class _BasketballMatchControlScreenState extends State<BasketballMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MatchModel? _match;
  TeamModel? _team1;
  TeamModel? _team2;
  bool _isLoading = true;
  String _selectedStatus = 'upcoming';
  
  int _currentQuarter = 1;
  Map<int, Map<String, int>> _quarterScores = {
    1: {'team1': 0, 'team2': 0},
    2: {'team1': 0, 'team2': 0},
    3: {'team1': 0, 'team2': 0},
    4: {'team1': 0, 'team2': 0},
  };
  
  List<Map<String, dynamic>> _matchEvents = [];

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final matchDoc = await _firestore.collection('matches').doc(widget.matchId).get();
      if (!matchDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _match = MatchModel.fromSnapshot(matchDoc);
      _selectedStatus = _match!.status;

      // Load teams
      final team1Doc = await _firestore.collection('teams').doc(_match!.team1Id).get();
      final team2Doc = await _firestore.collection('teams').doc(_match!.team2Id).get();
      
      if (!team1Doc.exists || !team2Doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _team1 = TeamModel.fromSnapshot(team1Doc);
      _team2 = TeamModel.fromSnapshot(team2Doc);

      // Load basketball data
      final basketballData = matchDoc.data()?['basketballMatchData'] as Map<String, dynamic>?;
      if (basketballData != null) {
        _currentQuarter = basketballData['currentQuarter'] ?? 1;
        
        if (basketballData['quarterScores'] != null) {
          final loadedScores = basketballData['quarterScores'] as Map<String, dynamic>;
          loadedScores.forEach((key, value) {
            final quarter = int.parse(key);
            final scores = value as Map<String, dynamic>;
            _quarterScores[quarter] = {
              'team1': scores['team1'] ?? 0,
              'team2': scores['team2'] ?? 0,
            };
          });
        }
        
        if (basketballData['events'] != null) {
          _matchEvents = List<Map<String, dynamic>>.from(basketballData['events']);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading match: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _team1TotalScore {
    return _quarterScores.values.fold(0, (sum, quarter) => sum + (quarter['team1'] ?? 0));
  }

  int get _team2TotalScore {
    return _quarterScores.values.fold(0, (sum, quarter) => sum + (quarter['team2'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Basketball Match Control'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_match == null || _team1 == null || _team2 == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Basketball Match Control'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unable to Load Match Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please ensure teams have complete player rosters before managing this match.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_basketball, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            const Text('Basketball Match Control'),
          ],
        ),
        backgroundColor: AppTheme.primaryGradientStart,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMatchInfo(),
            const SizedBox(height: 24),
            _buildStatusControl(),
            const SizedBox(height: 24),
            _buildScoreboard(),
            const SizedBox(height: 24),
            _buildQuarterSelector(),
            const SizedBox(height: 24),
            if (_selectedStatus == 'live') _buildLiveControls(),
            if (_matchEvents.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildMatchEvents(),
            ],
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _team1!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _team2!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(
                _match!.venue,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Upcoming', 'upcoming'),
              _buildStatusChip('Live', 'live'),
              _buildStatusChip('Completed', 'completed'),
              _buildStatusChip('Cancelled', 'cancelled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
      selectedColor: AppTheme.successColor,
      backgroundColor: AppTheme.backgroundDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Total Score',
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
              _buildTeamScore(_team1!.name, _team1TotalScore),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '-',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildTeamScore(_team2!.name, _team2TotalScore),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          _buildQuarterScores(),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String teamName, int score) {
    return Column(
      children: [
        Text(
          teamName,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterScores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quarter Scores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 60),
            ...List.generate(4, (index) {
              final quarter = index + 1;
              return Expanded(
                child: Center(
                  child: Text(
                    'Q$quarter',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        _buildQuarterRow(_team1!.name, true),
        const SizedBox(height: 8),
        _buildQuarterRow(_team2!.name, false),
      ],
    );
  }

  Widget _buildQuarterRow(String teamName, bool isTeam1) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            teamName.length > 6 ? '${teamName.substring(0, 6)}...' : teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        ...List.generate(4, (index) {
          final quarter = index + 1;
          final score = _quarterScores[quarter]?[isTeam1 ? 'team1' : 'team2'] ?? 0;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuarterSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Quarter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) {
              final quarter = index + 1;
              final isSelected = _currentQuarter == quarter;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentQuarter = quarter;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.successColor 
                          : AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.successColor 
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Q$quarter',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quarter $_currentQuarter Score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreControl(_team1!.name, true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScoreControl(_team2!.name, false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog('foul'),
                  icon: const Icon(Icons.warning, size: 16),
                  label: const Text('Foul'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog('timeout'),
                  icon: const Icon(Icons.pause_circle, size: 16),
                  label: const Text('Timeout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreControl(String teamName, bool isTeam1) {
    final currentScore = _quarterScores[_currentQuarter]?[isTeam1 ? 'team1' : 'team2'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentScore.toString(),
            style: const TextStyle(
              color: AppTheme.successColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _addPoints(isTeam1, 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Text('+1'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addPoints(isTeam1, 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Text('+2'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addPoints(isTeam1, 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Text('+3'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchEvents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._matchEvents.take(10).map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final team = event['team'] as String;
    final quarter = event['quarter'] as int?;
    final points = event['points'] as int?;
    
    IconData icon;
    Color color;
    String description;
    
    switch (type) {
      case 'score':
        icon = Icons.sports_basketball;
        color = AppTheme.successColor;
        description = '$points Point${points! > 1 ? 's' : ''}';
        break;
      case 'foul':
        icon = Icons.warning;
        color = Colors.orange;
        description = 'Foul';
        break;
      case 'timeout':
        icon = Icons.pause_circle;
        color = AppTheme.accentGradientStart;
        description = 'Timeout';
        break;
      default:
        icon = Icons.info;
        color = AppTheme.textSecondary;
        description = 'Event';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  team,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (quarter != null)
            Text(
              'Q$quarter',
              style: const TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveMatchData,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.successColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save Match Data',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  void _addPoints(bool isTeam1, int points) {
    setState(() {
      final key = isTeam1 ? 'team1' : 'team2';
      _quarterScores[_currentQuarter]![key] = 
          (_quarterScores[_currentQuarter]![key] ?? 0) + points;
      
      _matchEvents.insert(0, {
        'type': 'score',
        'team': isTeam1 ? _team1!.name : _team2!.name,
        'teamId': isTeam1 ? _team1!.id : _team2!.id,
        'quarter': _currentQuarter,
        'points': points,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _showAddEventDialog(String eventType) {
    String selectedTeam = _team1!.id;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Add ${eventType.toUpperCase()}'),
          content: DropdownButtonFormField<String>(
            value: selectedTeam,
            decoration: const InputDecoration(
              labelText: 'Team',
              prefixIcon: Icon(Icons.groups),
            ),
            items: [
              DropdownMenuItem(value: _team1!.id, child: Text(_team1!.name)),
              DropdownMenuItem(value: _team2!.id, child: Text(_team2!.name)),
            ],
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedTeam = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _matchEvents.insert(0, {
                    'type': eventType,
                    'team': selectedTeam == _team1!.id ? _team1!.name : _team2!.name,
                    'teamId': selectedTeam,
                    'quarter': _currentQuarter,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMatchData() async {
    try {
      String? winnerId;
      if (_selectedStatus == 'completed') {
        winnerId = _team1TotalScore > _team2TotalScore 
            ? _team1!.id 
            : _team2TotalScore > _team1TotalScore 
                ? _team2!.id 
                : null;
      }

      // Convert quarterScores map keys to strings for Firestore
      final quarterScoresForFirestore = <String, dynamic>{};
      _quarterScores.forEach((quarter, scores) {
        quarterScoresForFirestore[quarter.toString()] = scores;
      });

      await _firestore.collection('matches').doc(widget.matchId).update({
        'status': _selectedStatus,
        'score': {
          _team1!.id: _team1TotalScore,
          _team2!.id: _team2TotalScore,
        },
        'winnerId': winnerId,
        'basketballMatchData': {
          'currentQuarter': _currentQuarter,
          'quarterScores': quarterScoresForFirestore,
          'events': _matchEvents,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match data saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving match: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
