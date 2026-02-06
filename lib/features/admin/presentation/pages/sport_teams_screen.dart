import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/utils/validators.dart';

/// Screen to manage teams and their players for a specific sport
class SportTeamsScreen extends StatefulWidget {
  final String sportId;
  final String sportName;

  const SportTeamsScreen({
    super.key,
    required this.sportId,
    required this.sportName,
  });

  @override
  State<SportTeamsScreen> createState() => _SportTeamsScreenState();
}

class _SportTeamsScreenState extends State<SportTeamsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _numberOfPlayers;

  @override
  void initState() {
    super.initState();
    _loadNumberOfPlayers();
  }

  Future<void> _loadNumberOfPlayers() async {
    final sportDoc =
        await _firestore.collection('sports').doc(widget.sportId).get();
    if (sportDoc.exists) {
      setState(() {
        _numberOfPlayers = sportDoc.data()?['numberOfPlayers'] as int?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.sportName} Teams',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Number of players setting at top
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _numberOfPlayers == null
                      ? AppTheme.accentGradientStart.withOpacity(0.1)
                      : AppTheme.primaryGradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _numberOfPlayers == null
                        ? AppTheme.accentGradientStart
                        : AppTheme.primaryGradientStart,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _numberOfPlayers == null
                          ? Icons.info_outline
                          : Icons.group,
                      color: _numberOfPlayers == null
                          ? AppTheme.accentGradientStart
                          : AppTheme.primaryGradientStart,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _numberOfPlayers == null
                            ? 'Set number of players for ${widget.sportName} teams'
                            : 'Players per team: $_numberOfPlayers',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showSetNumberOfPlayersDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _numberOfPlayers == null
                            ? AppTheme.accentGradientStart
                            : AppTheme.primaryGradientStart,
                      ),
                      child:
                          Text(_numberOfPlayers == null ? 'Set Now' : 'Change'),
                    ),
                  ],
                ),
              ),

              // Teams List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('teams').snapshots(),
                  builder: (context, teamsSnapshot) {
                    if (teamsSnapshot.hasError) {
                      return Center(child: Text('Error: ${teamsSnapshot.error}'));
                    }

                    if (!teamsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Get all teams first
                    final allTeams = teamsSnapshot.data!.docs
                        .map((doc) => TeamModel.fromSnapshot(doc))
                        .toList();

                    if (allTeams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No teams available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Go to Admin → Manage Teams to create teams',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allTeams.length,
                      itemBuilder: (context, index) {
                        final team = allTeams[index];
                        return _buildTeamCard(team, index)
                            .animate(delay: (100 * index).ms)
                            .fadeIn()
                            .slideX(begin: -0.2, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('players')
          .where('teamId', isEqualTo: team.id)
          .where('sportId', isEqualTo: widget.sportId)
          .snapshots(),
      builder: (context, playersSnapshot) {
        final playerCount =
            playersSnapshot.hasData ? playersSnapshot.data!.docs.length : 0;
        final numberOfPlayers = _numberOfPlayers ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
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
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        team.name.substring(0, 1).toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team.department,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        if (numberOfPlayers > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Players: $playerCount / $numberOfPlayers',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: playerCount == numberOfPlayers
                                          ? AppTheme.successColor
                                          : AppTheme.accentGradientStart,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.people,
                        color: numberOfPlayers > 0
                            ? AppTheme.primaryGradientStart
                            : AppTheme.textSecondary),
                    onPressed: numberOfPlayers > 0
                        ? () => _showPlayersDialog(team)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetNumberOfPlayersDialog() {
    final numberOfPlayersController = TextEditingController(
      text: _numberOfPlayers?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Set Number of Players for ${widget.sportName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: numberOfPlayersController,
              decoration: const InputDecoration(
                labelText: 'Number of Players per Team',
                prefixIcon: Icon(Icons.people),
                hintText: 'e.g., 11 for Football, 5 for Basketball',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'This will apply to all teams in ${widget.sportName}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(numberOfPlayersController.text.trim());
              if (count != null && count > 0) {
                try {
                  await _firestore
                      .collection('sports')
                      .doc(widget.sportId)
                      .set({
                    'numberOfPlayers': count,
                  }, SetOptions(merge: true));
                  setState(() {
                    _numberOfPlayers = count;
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Number of players set successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPlayersDialog(TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('players')
            .where('teamId', isEqualTo: team.id)
            .where('sportId', isEqualTo: widget.sportId)
            .snapshots(),
        builder: (context, playersSnapshot) {
          final players = playersSnapshot.hasData
              ? playersSnapshot.data!.docs
                  .map((doc) => PlayerModel.fromSnapshot(doc))
                  .toList()
              : <PlayerModel>[];

          return Dialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${team.name} Players',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _numberOfPlayers ?? 0,
                      itemBuilder: (context, index) {
                        final player =
                            index < players.length ? players[index] : null;
                        return _buildPlayerField(team, index + 1, player);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerField(TeamModel team, int position, PlayerModel? player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player != null
              ? AppTheme.successColor
              : AppTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player != null
                  ? AppTheme.successColor
                  : AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player?.name ?? 'Empty Slot',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: player != null ? null : AppTheme.textSecondary,
                      ),
                ),
                if (player != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${player.idNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (player != null)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deletePlayer(player),
            )
          else
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accentGradientStart),
              onPressed: () => _showAddPlayerDialog(team, position),
            ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(TeamModel team, int position) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Add Player #$position'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'Player name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'ID Number',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'ID number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final docRef = _firestore.collection('players').doc();
                final newPlayer = PlayerModel(
                  id: docRef.id,
                  name: nameController.text.trim(),
                  idNumber: idController.text.trim(),
                  teamId: team.id,
                  sportId: widget.sportId,
                  createdAt: DateTime.now(),
                );

                await docRef.set(newPlayer.toMap());
                Navigator.pop(dialogContext);
                // No need to call setState, StreamBuilder will auto-update
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Player added successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deletePlayer(PlayerModel player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Player'),
        content: Text('Remove ${player.name} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('players').doc(player.id).delete();
      // No need to call setState, StreamBuilder will auto-update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player removed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
