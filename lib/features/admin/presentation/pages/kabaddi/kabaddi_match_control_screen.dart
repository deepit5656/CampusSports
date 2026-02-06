import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/models/match_model.dart';

class KabaddiMatchControlScreen extends StatefulWidget {
  final MatchModel match;

  const KabaddiMatchControlScreen({super.key, required this.match});

  @override
  State<KabaddiMatchControlScreen> createState() => _KabaddiMatchControlScreenState();
}

class _KabaddiMatchControlScreenState extends State<KabaddiMatchControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int team1Score = 0;
  int team2Score = 0;
  int currentHalf = 1;
  List<Map<String, dynamic>> events = [];
  
  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  void _loadMatchData() async {
    try {
      final doc = await _firestore.collection('matches').doc(widget.match.id).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final kabaddiData = data?['kabaddiMatchData'] as Map<String, dynamic>?;
        
        if (kabaddiData != null) {
          setState(() {
            team1Score = kabaddiData['team1Score'] ?? 0;
            team2Score = kabaddiData['team2Score'] ?? 0;
            currentHalf = kabaddiData['currentHalf'] ?? 1;
            
            final eventsList = kabaddiData['events'] as List?;
            if (eventsList != null) {
              events = eventsList.map((e) => Map<String, dynamic>.from(e)).toList();
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
        'kabaddiMatchData': {
          'team1Score': team1Score,
          'team2Score': team2Score,
          'currentHalf': currentHalf,
          'events': events,
        },
        'score': {
          widget.match.team1Id: team1Score,
          widget.match.team2Id: team2Score,
        },
      });
    } catch (e) {
      print('Error saving match data: $e');
    }
  }

  void _addRaidPoint(bool isTeam1, int points) {
    setState(() {
      if (isTeam1) {
        team1Score += points;
      } else {
        team2Score += points;
      }
      
      events.add({
        'type': 'raid',
        'team': isTeam1 ? 'team1' : 'team2',
        'points': points,
        'time': DateTime.now().toIso8601String(),
        'half': currentHalf,
      });
    });
    _saveMatchData();
  }

  void _addTackle(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        team1Score += 1;
      } else {
        team2Score += 1;
      }
      
      events.add({
        'type': 'tackle',
        'team': isTeam1 ? 'team1' : 'team2',
        'points': 1,
        'time': DateTime.now().toIso8601String(),
        'half': currentHalf,
      });
    });
    _saveMatchData();
  }

  void _addAllOut(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        team1Score += 2;
      } else {
        team2Score += 2;
      }
      
      events.add({
        'type': 'allout',
        'team': isTeam1 ? 'team1' : 'team2',
        'points': 2,
        'time': DateTime.now().toIso8601String(),
        'half': currentHalf,
      });
    });
    _saveMatchData();
  }

  void _switchHalf() {
    setState(() {
      currentHalf = 2;
    });
    _saveMatchData();
  }

  void _endMatch() async {
    final winnerId = team1Score > team2Score ? widget.match.team1Id : widget.match.team2Id;
    
    await _firestore.collection('matches').doc(widget.match.id).update({
      'status': 'completed',
      'winnerId': winnerId,
    });
    
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
        title: const Text('Kabaddi Match Control'),
        backgroundColor: AppTheme.primaryGradientStart,
        actions: [
          if (currentHalf == 1)
            TextButton.icon(
              onPressed: _switchHalf,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text('Switch Half', style: TextStyle(color: Colors.white)),
            ),
          if (currentHalf == 2)
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
                  Text(
                    'Half $currentHalf',
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
                      Column(
                        children: [
                          const Text('Team 1', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            team1Score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text('VS', style: TextStyle(color: Colors.white, fontSize: 20)),
                      Column(
                        children: [
                          const Text('Team 2', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            team2Score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Team 1 Controls
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
                    'Team 1',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addRaidPoint(true, 1),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Text('Touch Point'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addRaidPoint(true, 2),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Text('Bonus Point'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addTackle(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Tackle'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addAllOut(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('All Out'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Team 2 Controls
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
                    'Team 2',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addRaidPoint(false, 1),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Text('Touch Point'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addRaidPoint(false, 2),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Text('Bonus Point'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addTackle(false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Tackle'),
                      ),
                      ElevatedButton(
                        onPressed: () => _addAllOut(false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('All Out'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Events Timeline
            if (events.isNotEmpty) ...[
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
                      'Match Events',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...events.reversed.take(10).map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: event['team'] == 'team1' 
                                    ? AppTheme.successColor.withOpacity(0.2)
                                    : AppTheme.accentGradientStart.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event['team'] == 'team1' ? 'T1' : 'T2',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${event['type'].toString().toUpperCase()}: +${event['points']} points',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'H${event['half']}',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
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
