import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';
import '../../../../../core/models/team_model.dart';

class FootballMatchControlScreen extends StatefulWidget {
  final String matchId;

  const FootballMatchControlScreen({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  State<FootballMatchControlScreen> createState() => _FootballMatchControlScreenState();
}

class _FootballMatchControlScreenState extends State<FootballMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MatchModel? _match;
  TeamModel? _team1;
  TeamModel? _team2;
  bool _isLoading = true;
  String _selectedStatus = 'upcoming';
  
  int _team1Score = 0;
  int _team2Score = 0;
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

      // Load scores
      _team1Score = _match!.score?[_match!.team1Id] ?? 0;
      _team2Score = _match!.score?[_match!.team2Id] ?? 0;

      // Load match events (goals, cards, etc.)
      final footballData = matchDoc.data()?['footballMatchData'] as Map<String, dynamic>?;
      if (footballData != null && footballData['events'] != null) {
        _matchEvents = List<Map<String, dynamic>>.from(footballData['events']);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Football Match Control'),
          backgroundColor: AppTheme.primaryGradientStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_match == null || _team1 == null || _team2 == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Football Match Control'),
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
            const Icon(Icons.sports_soccer, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            const Text('Football Match Control'),
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
            'Score',
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
              _buildTeamScore(_team1!.name, _team1Score, true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildTeamScore(_team2!.name, _team2Score, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String teamName, int score, bool isTeam1) {
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
        if (_selectedStatus == 'live') ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (isTeam1) {
                      if (_team1Score > 0) _team1Score--;
                    } else {
                      if (_team2Score > 0) _team2Score--;
                    }
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.errorColor,
              ),
              IconButton(
                onPressed: () {
                  _addGoal(isTeam1);
                },
                icon: const Icon(Icons.add_circle),
                color: AppTheme.successColor,
              ),
            ],
          ),
        ],
      ],
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
          const Text(
            'Match Events',
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
                  onPressed: () => _showAddEventDialog('yellow_card'),
                  icon: const Icon(Icons.square, color: Colors.yellow, size: 16),
                  label: const Text('Yellow Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog('red_card'),
                  icon: const Icon(Icons.square, color: Colors.red, size: 16),
                  label: const Text('Red Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog('substitution'),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Substitution'),
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
          ..._matchEvents.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final team = event['team'] as String;
    final minute = event['minute'] as int?;
    final player = event['player'] as String?;
    
    IconData icon;
    Color color;
    String description;
    
    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        color = AppTheme.successColor;
        description = 'GOAL by ${player ?? 'Unknown'}';
        break;
      case 'yellow_card':
        icon = Icons.square;
        color = Colors.yellow;
        description = 'Yellow Card - ${player ?? 'Unknown'}';
        break;
      case 'red_card':
        icon = Icons.square;
        color = Colors.red;
        description = 'Red Card - ${player ?? 'Unknown'}';
        break;
      case 'substitution':
        icon = Icons.swap_horiz;
        color = AppTheme.accentGradientStart;
        description = 'Substitution';
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
          if (minute != null)
            Text(
              "$minute'",
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

  void _addGoal(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        _team1Score++;
      } else {
        _team2Score++;
      }
      
      _matchEvents.insert(0, {
        'type': 'goal',
        'team': isTeam1 ? _team1!.name : _team2!.name,
        'teamId': isTeam1 ? _team1!.id : _team2!.id,
        'minute': null,
        'player': null,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _showAddEventDialog(String eventType) {
    final minuteController = TextEditingController();
    final playerController = TextEditingController();
    String selectedTeam = _team1!.id;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Add ${eventType.replaceAll('_', ' ').toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 16),
              TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minute',
                  prefixIcon: Icon(Icons.timer),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: playerController,
                decoration: const InputDecoration(
                  labelText: 'Player Name (Optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
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
                    'minute': minuteController.text.isNotEmpty 
                        ? int.tryParse(minuteController.text) 
                        : null,
                    'player': playerController.text.isNotEmpty 
                        ? playerController.text 
                        : null,
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
        winnerId = _team1Score > _team2Score 
            ? _team1!.id 
            : _team2Score > _team1Score 
                ? _team2!.id 
                : null;
      }

      await _firestore.collection('matches').doc(widget.matchId).update({
        'status': _selectedStatus,
        'score': {
          _team1!.id: _team1Score,
          _team2!.id: _team2Score,
        },
        'winnerId': winnerId,
        'footballMatchData': {
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
