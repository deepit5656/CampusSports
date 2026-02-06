import 'package:flutter/material.dart';
import '../../../../core/models/sport_config_comprehensive.dart';
import '../../../../core/services/match_scoring_service.dart';

class UniversalLiveScoringScreen extends StatefulWidget {
  final String matchId;
  final SportConfigModel sportConfig;

  const UniversalLiveScoringScreen({
    Key? key,
    required this.matchId,
    required this.sportConfig,
  }) : super(key: key);

  @override
  State<UniversalLiveScoringScreen> createState() =>
      _UniversalLiveScoringScreenState();
}

class _UniversalLiveScoringScreenState
    extends State<UniversalLiveScoringScreen> {
  final _scoringService = MatchScoringService();

  @override
  Widget build(BuildContext context) {
    // Route to appropriate scoring interface based on sport structure
    switch (widget.sportConfig.structureType) {
      case StructureType.oversBased:
        return _buildOverBasedInterface();
      case StructureType.timeBased:
        return _buildTimeBasedInterface();
      case StructureType.setsBased:
        return _buildSetBasedInterface();
      case StructureType.roundsBased:
        return _buildRoundBasedInterface();
      case StructureType.pointsBased:
        return _buildPointBasedInterface();
    }
  }

  Widget _buildOverBasedInterface() {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sportConfig.name} - Live Scoring'),
        backgroundColor: widget.sportConfig.primaryColor,
      ),
      body: StreamBuilder<MatchState>(
        stream: _scoringService.getMatchState(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No match data'));
          }

          final matchState = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildScoreHeader(matchState),
                _buildCurrentPlayersSection(matchState),
                _buildQuickActionGrid(),
                _buildThisOverSummary(),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeBasedInterface() {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sportConfig.name} - Live Scoring'),
        backgroundColor: widget.sportConfig.primaryColor,
      ),
      body: StreamBuilder<MatchState>(
        stream: _scoringService.getMatchState(widget.matchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matchState = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildScoreHeader(matchState),
                _buildTimeDisplay(matchState),
                _buildQuickActionGrid(),
                _buildRecentActions(),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSetBasedInterface() {
    return _buildGenericInterface(); // Simplified for now
  }

  Widget _buildRoundBasedInterface() {
    return _buildGenericInterface(); // Simplified for now
  }

  Widget _buildPointBasedInterface() {
    return _buildGenericInterface(); // Simplified for now
  }

  Widget _buildGenericInterface() {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sportConfig.name} - Live Scoring'),
        backgroundColor: widget.sportConfig.primaryColor,
      ),
      body: StreamBuilder<MatchState>(
        stream: _scoringService.getMatchState(widget.matchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matchState = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildScoreHeader(matchState),
                _buildQuickActionGrid(),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreHeader(MatchState matchState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.sportConfig.primaryColor,
            widget.sportConfig.primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.sportConfig.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: matchState.currentScore.entries.map((entry) {
              return Column(
                children: [
                  Text(
                    'Team ${entry.key}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayersSection(MatchState matchState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Players',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (matchState.activePlayers != null)
            ...matchState.activePlayers!.map(
              (playerId) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(playerId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(MatchState matchState) {
    final minutes = matchState.currentTime ~/ 60;
    final seconds = matchState.currentTime % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 32),
          const SizedBox(width: 12),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    final actions = widget.sportConfig.quickActions;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              final scoreAction = widget.sportConfig.scoreActions
                  .firstWhere((sa) => sa.id == action.actionId);

              return ElevatedButton(
                onPressed: () => _handleAction(scoreAction),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action.isPrimary
                      ? widget.sportConfig.primaryColor
                      : Colors.grey[300],
                  foregroundColor:
                      action.isPrimary ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontSize: action.isPrimary ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThisOverSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Over',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• 1 • 4 • W • 0 • 2'),
        ],
      ),
    );
  }

  Widget _buildRecentActions() {
    return StreamBuilder<List<MatchEvent>>(
      stream: _scoringService.getMatchEvents(widget.matchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final recentEvents = snapshot.data!.reversed.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recentEvents.map((event) => ListTile(
                    leading: const Icon(Icons.circle, size: 12),
                    title: Text(event.description ?? event.eventType),
                    subtitle: Text(
                      event.timestamp.toString().substring(11, 19),
                    ),
                    dense: true,
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _undoLastAction,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showEndMatchDialog,
            icon: const Icon(Icons.check_circle),
            label: const Text('End Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(action) async {
    // Show team selector dialog
    final teamId = await _showTeamSelector();
    if (teamId == null) return;

    try {
      await _scoringService.recordAction(
        widget.matchId,
        action,
        {
          'teamId': teamId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.name} recorded for Team $teamId'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showTeamSelector() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Team 1'),
              onTap: () => Navigator.pop(context, 'team1'),
            ),
            ListTile(
              title: const Text('Team 2'),
              onTap: () => Navigator.pop(context, 'team2'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _undoLastAction() async {
    try {
      await _scoringService.undoLastAction(widget.matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last action undone')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEndMatchDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Match'),
        content: const Text('Are you sure you want to end this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Match'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _scoringService.completeMatch(
          widget.matchId,
          widget.sportConfig,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Match Complete'),
              content: Text(result.description),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to match list
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
